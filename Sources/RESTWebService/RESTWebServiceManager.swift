//
//  RESTWebServiceManager.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2022 Antarian Logic LLC. All rights reserved.
//

import Foundation
import os
import DateUtils
import ALTelemetryProtocol

public struct RESTRateLimitHeaders {
    public let rateLimitKey: String
    public let rateLimitRemainingKey : String
}

public actor RESTWebServiceManager {

    public init(baseURL: URL,
                session: URLSession = URLSession.shared,
                rateLimitHeaders: RESTRateLimitHeaders? = nil,
                telemetryInteractor: TelemetryInteracting = DummyTelemetryInteractor()) {
        self.baseURL = baseURL
        self.session = session
        self.rateLimitHeaders = rateLimitHeaders
        self.telemetryInteractor = telemetryInteractor
    }

    let baseURL: URL
    let session: URLSession
    let rateLimitHeaders: RESTRateLimitHeaders?
    let telemetryInteractor: TelemetryInteracting
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "RESTWebService", category: "Package")
    var prevRequestTime: Date = .distantPast
    var rateLimit: UInt64 = 0
    var rateLimitRemaining: UInt64 = .max
}

extension RESTWebServiceManager: RESTWebServiceManaging {

    public func sendRequest<M>(with resource: RESTResource) async throws -> M where M: Decodable {

        if resource.enableRateLimiting && rateLimit > 0 {
            await performRateLimiting()
        }

        let request = try buildRequest(with: resource)

        prevRequestTime = .now
        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            if let rateLimitHeaders {
                if let rateLimitString = httpResponse.value(forHTTPHeaderField: rateLimitHeaders.rateLimitKey),
                   !rateLimitString.isEmpty,
                   let theRateLimit = UInt64(rateLimitString) {
                    rateLimit = theRateLimit
                }
                if let rateLimitRemainingString = httpResponse.value(forHTTPHeaderField: rateLimitHeaders.rateLimitRemainingKey),
                   !rateLimitRemainingString.isEmpty,
                   let theRateLimitRemaining = UInt64(rateLimitRemainingString) {
                    rateLimitRemaining = theRateLimitRemaining
                }
            }

            guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 204 else {
                let errorString = String(data: data.prefix(1024), encoding: .utf8) ?? ""
                let error = RESTWebServiceError.httpError(httpResponse.statusCode, errorString)
                logger.warning("In RESTWebServiceManager.sendRequest, HTTP error with status code: \(httpResponse.statusCode) – \(errorString, privacy: .public)")
                // don't send out telemetry here, we can't do anything about this error
                throw error
            }
        }

        do {
            return try JSONDecoder().decode(M.self, from: data)
        } catch let decodingError as DecodingError {
            let failingURL = request.url?.absoluteString ?? ""
            logDecodingError(decodingError: decodingError, urlString: failingURL)
            throw decodingError
        }
    }

    nonisolated public func pageStream<M>(with initialResource: RESTResource,
                                          safetyLimit: UInt? = nil) -> AsyncThrowingStream<M,Error> where M: Decodable & Pageable {

        var currentResource = initialResource
        var totalCount: UInt? = nil
        var receivedCount: UInt = 0

        return AsyncThrowingStream { [weak self] in
            guard let strongSelf = self else { return nil }

            if let uSafetyLimit = safetyLimit {
                guard receivedCount < uSafetyLimit else {
                    let failingURL = "\(strongSelf.baseURL.absoluteString)/\(currentResource.path)"
                    strongSelf.logger.warning("In RESTWebServiceManager.pageStream, safety limit reached for URL: \(failingURL, privacy: .public)")
                    strongSelf.telemetryInteractor.sendAnonymously(signalType: "restWebServiceError",
                                                                   with: ["url" : failingURL,
                                                                          "reason" : "safety limit reached"])
                    throw RESTWebServiceError.safetyLimitReached
                }
            }

            if let uTotalCount = totalCount {
                // not first pass
                guard receivedCount < uTotalCount else { return nil }

                guard let newResource = currentResource.nextPageResource(at: receivedCount) else {
                    let failingURL = "\(strongSelf.baseURL.absoluteString)/\(currentResource.path)"
                    strongSelf.logger.warning("In RESTWebServiceManager.pageStream, invalid next page resource for URL: \(failingURL, privacy: .public)")
                    strongSelf.telemetryInteractor.sendAnonymously(signalType: "restWebServiceError",
                                                                   with: ["url" : failingURL,
                                                                          "reason" : "invalid next page resource"])
                    throw RESTWebServiceError.invalidRESTResource
                }

                currentResource = newResource
            }
            let model: M = try await strongSelf.sendRequest(with: currentResource)

            try Task.checkCancellation()

            totalCount = model.totalCount
            receivedCount += UInt(model.submodels.count)
            return model
        }
    }
}

extension RESTWebServiceManager {

    func buildRequest(with resource: RESTResource) throws -> URLRequest {

        let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        guard var validComponents = components else {
            let error = RESTWebServiceError.invalidBaseURL(baseURL.absoluteString)
            logger.error("In RESTWebServiceManager.buildRequest, error: \(String(reflecting: error), privacy: .public)")
            // don't send out telemetry here, this would be a pure programming error that would likely be found early
            throw error
        }

        validComponents.path = validComponents.path.appending(resource.path)

        var queryItems = resource.queryParameters
        if let pageSizeQueryItem = resource.pageSizeQueryItem {
            queryItems.append(pageSizeQueryItem)
        }
        if let offsetQueryItem = resource.offsetQueryItem {
            queryItems.append(offsetQueryItem)
        } else if let pageQueryItem = resource.pageQueryItem {
            queryItems.append(pageQueryItem)
        }
        if !queryItems.isEmpty {
            validComponents.queryItems = queryItems
        }

        guard let url = validComponents.url else {
            let error = RESTWebServiceError.insufficientURLComponents(validComponents.description)
            logger.error("In RESTWebServiceManager.buildRequest, error: \(String(reflecting: error), privacy: .public)")
            // don't send out telemetry here, this would be a pure programming error that would likely be found early
            throw error
        }

        var request = URLRequest(url: url)
        request.httpMethod = resource.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for header in resource.headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }

        if !resource.bodyParameters.isEmpty {
            var bodyComponents = URLComponents()
            bodyComponents.queryItems = resource.bodyParameters
            guard let validQuery = bodyComponents.query else {
                let error = RESTWebServiceError.bodyParametersInvalid(resource.bodyParameters)
                logger.error("In RESTWebServiceManager.buildRequest, error: \(String(reflecting: error), privacy: .public)")
                // don't send out telemetry here, this would be a pure programming error that would likely be found early
                throw error
            }

            guard let validData = validQuery.data(using: .utf8) else {
                let error = RESTWebServiceError.bodyStringInvalid(validQuery)
                logger.error("In RESTWebServiceManager.buildRequest, error: \(String(reflecting: error), privacy: .public)")
                // don't send out telemetry here, this would be a pure programming error that would likely be found early
                throw error
            }

            request.httpBody = validData
        }

        if let cacheInterval = resource.cacheInterval,
           cacheInterval > 0,
           let cachedResponse = session.configuration.urlCache?.cachedResponse(for: request),
           let httpURLResponse = cachedResponse.response as? HTTPURLResponse,
           let dateString = httpURLResponse.value(forHTTPHeaderField: "Date"),
           let date = DateFormatter.rfc822DateFormatter.date(from: dateString),
           date.timeIntervalSinceNow > -cacheInterval {
            // use cached response
            request.cachePolicy = .returnCacheDataElseLoad
        } // otherwise just use default cachePolicy (.useProtocolCachePolicy)

        if let timeoutInterval = resource.timeoutInterval,
           timeoutInterval > 0 {
            request.timeoutInterval = timeoutInterval
        }

        return request
    }

    func logDecodingError(decodingError: DecodingError, urlString: String) {
        switch decodingError {
        case let .typeMismatch(type, context):
            let codingPath = context.codingPath.map { $0.stringValue }
            let codingPathString = codingPath.joined(separator: ".")
            logger.warning("In RESTWebServiceManager.sendRequest, JSON decoding error, \(type) type mismatch – \(String(reflecting: context), privacy: .public)")
            telemetryInteractor.sendAnonymously(signalType: "jsonDecodingError",
                                                with: ["url" : urlString,
                                                       "reason" : "\(type) type mismatch",
                                                       "codingPath" : codingPathString])
        case let .valueNotFound(type, context):
            let codingPath = context.codingPath.map { $0.stringValue }
            let codingPathString = codingPath.joined(separator: ".")
            logger.warning("In RESTWebServiceManager.sendRequest, JSON decoding error, missing \(type) value – \(String(reflecting: context), privacy: .public)")
            telemetryInteractor.sendAnonymously(signalType: "jsonDecodingError",
                                                with: ["url" : urlString,
                                                       "reason" : "missing \(type) value",
                                                       "codingPath" : codingPathString])
        case let .keyNotFound(key, context):
            let codingPath = context.codingPath.map { $0.stringValue }
            let codingPathString = codingPath.joined(separator: ".")
            logger.warning("In RESTWebServiceManager.sendRequest, JSON decoding error, missing key '\(key.stringValue, privacy: .public)' not found – \(String(reflecting: context), privacy: .public)")
            telemetryInteractor.sendAnonymously(signalType: "jsonDecodingError",
                                                with: ["url" : urlString,
                                                       "reason" : "missing key: \(key.stringValue)",
                                                       "codingPath" : codingPathString])
        case let .dataCorrupted(context):
            let codingPath = context.codingPath.map { $0.stringValue }
            let codingPathString = codingPath.joined(separator: ".")
            logger.warning("In RESTWebServiceManager.sendRequest, JSON decoding error, invalid JSON = \(String(reflecting: context), privacy: .public)")
            telemetryInteractor.sendAnonymously(signalType: "jsonDecodingError",
                                                with: ["url" : urlString,
                                                       "reason" : "invalid JSON",
                                                       "codingPath" : codingPathString])
        @unknown default:
            logger.warning("In RESTWebServiceManager.sendRequest, JSON decoding error, unknown error: \(String(reflecting: decodingError), privacy: .public)")
            telemetryInteractor.sendAnonymously(signalType: "jsonDecodingError",
                                                with: ["url" : urlString,
                                                       "reason" : "unknown"])
        }
    }

    func performRateLimiting() async {
        guard rateLimit > 0,
              rateLimitRemaining >= 0,
              rateLimitRemaining < rateLimit else { return }

        let waitInterval = TimeInterval(rateLimit) / pow(1.5, Double(rateLimitRemaining))
        let nextRequestTime = prevRequestTime.addingTimeInterval(waitInterval)
        let actualWaitInterval = nextRequestTime.timeIntervalSinceNow
        guard actualWaitInterval > 0 else { return }

        let waitNanoseconds = UInt64(1_000_000_000.0 * actualWaitInterval)
        let capturedRateLimit = rateLimit
        let capturedRateLimitRemaining = rateLimitRemaining
        logger.info("In RESTWebServiceManager.performRateLimiting, rateLimit: \(capturedRateLimit), rateLimitRemaining: \(capturedRateLimitRemaining), waiting \(waitNanoseconds) nanoseconds...")
        try? await Task.sleep(nanoseconds: waitNanoseconds)
    }
}
