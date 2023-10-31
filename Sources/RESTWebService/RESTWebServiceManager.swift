//
//  RESTWebServiceManager.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation
import os
import DateUtils

/// The main RESTWebService object that handles web service requests for a given web service.
public actor RESTWebServiceManager {

    /// RESTWebServiceManager Initializer.
    /// - Parameters:
    ///   - baseURL: Web service base URL. Includes everything in the URL that is common to all routes such as version path, etc. but not the method parts themselves. A slash at the end is not required.
    ///   - session: Optional URLSession to be used for all service requests. If omitted, the shared URLSession will be used.
    ///   - rateLimitHeaders: Optional specification of service request headers used for rate limiting. If omitted, rate limiting will not be performed. See <doc:RESTWebService#Rate-Limiting>.
    public init(baseURL: URL,
                session: URLSession = URLSession.shared,
                rateLimitHeaders: RESTRateLimitHeaders? = nil) {
        self.baseURL = baseURL
        self.session = session
        self.rateLimitHeaders = rateLimitHeaders
    }

    let baseURL: URL
    let session: URLSession
    let rateLimitHeaders: RESTRateLimitHeaders?
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "RESTWebService", category: "Package")
    var prevRequestTime: Date = .distantPast
    var rateLimit: UInt64 = 0
    var rateLimitRemaining: UInt64 = .max
}

extension RESTWebServiceManager: RESTWebServiceManaging {

    /// Performs web service request asynchronously.
    /// - Parameter endpoint: Web service endpoint specification.
    /// - Returns: Decoded model object.
    public func sendRequest<M>(with endpoint: RESTEndpoint) async throws -> M where M: Decodable & Sendable {

        await performRateLimiting()

        let request = try buildRequest(with: endpoint)

        try Task.checkCancellation()

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
                let failingURL = request.url?.absoluteString ?? ""
                let error = RESTWebServiceError.httpError(httpResponse.statusCode, errorString, failingURL)
                logger.warning("In RESTWebServiceManager.sendRequest, HTTP error with status code: \(httpResponse.statusCode) – \(errorString, privacy: .public)")
                throw error
            }
        }

        do {
            return try JSONDecoder().decode(M.self, from: data)
        } catch let decodingError as DecodingError {
            let failingURL = request.url?.absoluteString ?? ""
            let error = buildErrorAndLog(decodingError: decodingError, urlString: failingURL)
            throw error
        }
    }

    /// Creates an AsyncThrowingStream that can be iterated on to perform multipage web service requests.
    /// - Parameters:
    ///   - initialEndpoint: Web service endpoint specification for initial page request. Subsequent page requests will used modified versions of this endpoint specification for each page.
    ///   - safetyLimit: Optional page limit to protect against infinite loops during iteration or to simply limit the maximum number of pages to retrieve.
    /// - Returns: AsyncThrowingStream to be iterated on.
    nonisolated public func pageStream<M>(with initialEndpoint: RESTEndpoint,
                                          safetyLimit: UInt? = nil) -> AsyncThrowingStream<M,Error> where M: Decodable & Pageable & Sendable {

        var currentEndpoint = initialEndpoint
        var totalCount: UInt? = nil
        var receivedCount: UInt = 0

        return AsyncThrowingStream { [weak self] in
            guard let strongSelf = self else { return nil }

            if let uSafetyLimit = safetyLimit {
                guard receivedCount < uSafetyLimit else {
                    let failingURL = "\(strongSelf.baseURL.absoluteString)/\(currentEndpoint.path)"
                    strongSelf.logger.warning("In RESTWebServiceManager.pageStream, safety limit reached for URL: \(failingURL, privacy: .public)")
                    throw RESTWebServiceError.safetyLimitReached(failingURL)
                }
            }

            if let uTotalCount = totalCount {
                // not first pass
                guard receivedCount < uTotalCount else { return nil }

                guard let newEndpoint = currentEndpoint.nextPageEndpoint(at: receivedCount) else {
                    let failingURL = "\(strongSelf.baseURL.absoluteString)/\(currentEndpoint.path)"
                    strongSelf.logger.warning("In RESTWebServiceManager.pageStream, invalid next page endpoint specification for URL: \(failingURL, privacy: .public)")
                    throw RESTWebServiceError.invalidRESTEndpoint(failingURL)
                }

                currentEndpoint = newEndpoint
            }
            let model: M = try await strongSelf.sendRequest(with: currentEndpoint)

            totalCount = model.totalCount
            receivedCount += UInt(model.submodels.count)
            return model
        }
    }
}

extension RESTWebServiceManager {

    func buildRequest(with endpoint: RESTEndpoint) throws -> URLRequest {

        let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        guard var validComponents = components else {
            let error = RESTWebServiceError.invalidBaseURL(baseURL.absoluteString)
            logger.error("In RESTWebServiceManager.buildRequest, error: \(String(reflecting: error), privacy: .public)")
            throw error
        }

        validComponents.path = validComponents.path.appending(endpoint.path)

        var queryItems = endpoint.queryParameters
        if let pageSizeQueryItem = endpoint.pageSizeQueryItem {
            queryItems.append(pageSizeQueryItem)
        }
        if let offsetQueryItem = endpoint.offsetQueryItem {
            queryItems.append(offsetQueryItem)
        } else if let pageQueryItem = endpoint.pageQueryItem {
            queryItems.append(pageQueryItem)
        }
        if !queryItems.isEmpty {
            validComponents.queryItems = queryItems
        }

        guard let url = validComponents.url else {
            let error = RESTWebServiceError.insufficientURLComponents(validComponents.description)
            logger.error("In RESTWebServiceManager.buildRequest, error: \(String(reflecting: error), privacy: .public)")
            throw error
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for header in endpoint.headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }

        if !endpoint.bodyParameters.isEmpty {
            var bodyComponents = URLComponents()
            bodyComponents.queryItems = endpoint.bodyParameters
            guard let validQuery = bodyComponents.query else {
                let error = RESTWebServiceError.bodyParametersInvalid(endpoint.bodyParameters)
                logger.error("In RESTWebServiceManager.buildRequest, error: \(String(reflecting: error), privacy: .public)")
                throw error
            }

            guard let validData = validQuery.data(using: .utf8) else {
                let error = RESTWebServiceError.bodyStringInvalid(validQuery)
                logger.error("In RESTWebServiceManager.buildRequest, error: \(String(reflecting: error), privacy: .public)")
                throw error
            }

            request.httpBody = validData
        }

        if let cacheInterval = endpoint.cacheInterval,
           cacheInterval > 0,
           let cachedResponse = session.configuration.urlCache?.cachedResponse(for: request),
           let httpURLResponse = cachedResponse.response as? HTTPURLResponse,
           let dateString = httpURLResponse.value(forHTTPHeaderField: "Date"),
           let date = DateFormatter.rfc822DateFormatter.date(from: dateString),
           date.timeIntervalSinceNow > -cacheInterval {
            // use cached response
            request.cachePolicy = .returnCacheDataElseLoad
        } // otherwise just use default cachePolicy (.useProtocolCachePolicy)

        if let timeoutInterval = endpoint.timeoutInterval,
           timeoutInterval > 0 {
            request.timeoutInterval = timeoutInterval
        }

        return request
    }

    func buildErrorAndLog(decodingError: DecodingError, urlString: String) -> RESTWebServiceError {
        var reason: String = ""
        var codingPathString: String?
        switch decodingError {
        case let .typeMismatch(type, context):
            let codingPath = context.codingPath.map { $0.stringValue }
            codingPathString = codingPath.joined(separator: ".")
            logger.warning("In RESTWebServiceManager.sendRequest, JSON decoding error, \(type) type mismatch – \(String(reflecting: context), privacy: .public)")
            reason = "\(type) type mismatch"
        case let .valueNotFound(type, context):
            let codingPath = context.codingPath.map { $0.stringValue }
            codingPathString = codingPath.joined(separator: ".")
            logger.warning("In RESTWebServiceManager.sendRequest, JSON decoding error, missing \(type) value – \(String(reflecting: context), privacy: .public)")
            reason = "missing \(type) value"
        case let .keyNotFound(key, context):
            let codingPath = context.codingPath.map { $0.stringValue }
            codingPathString = codingPath.joined(separator: ".")
            logger.warning("In RESTWebServiceManager.sendRequest, JSON decoding error, missing key '\(key.stringValue, privacy: .public)' not found – \(String(reflecting: context), privacy: .public)")
            reason = "missing key: \(key.stringValue)"
        case let .dataCorrupted(context):
            let codingPath = context.codingPath.map { $0.stringValue }
            codingPathString = codingPath.joined(separator: ".")
            logger.warning("In RESTWebServiceManager.sendRequest, JSON decoding error, invalid JSON = \(String(reflecting: context), privacy: .public)")
            reason = "invalid JSON"
        @unknown default:
            logger.warning("In RESTWebServiceManager.sendRequest, JSON decoding error, unknown error: \(String(reflecting: decodingError), privacy: .public)")
            reason = "unknown"
        }
        return RESTWebServiceError.decodingError(decodingError, urlString, reason, codingPathString)
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

public struct RESTRateLimitHeaders {

    public let rateLimitKey: String
    public let rateLimitRemainingKey : String

    public init(rateLimitKey: String,
                rateLimitRemainingKey: String) {
        self.rateLimitKey = rateLimitKey
        self.rateLimitRemainingKey = rateLimitRemainingKey
    }
}
