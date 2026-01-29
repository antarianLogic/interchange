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
///
/// `RESTWebServiceManager` is an actor that provides REST API operations with support for pagination, rate limiting, caching, and more.
///
/// ## Overview
///
/// Create one instance per API base URL and reuse it throughout your application.
/// The actor ensures thread-safe access to shared state like rate limiting counters.
///
/// See <doc:RESTWebService> and <doc:QuickStart> for more information.
///
public actor RESTWebServiceManager {

    /// Creates a new manager instance for a specific API base URL.
    ///
    /// - Parameters:
    ///   - baseURL: Web API base URL. Includes everything common to all routes (e.g., `https://api.example.com/v1`) but without the parts specific to each endpoint. A trailing slash is not required.
    ///   - session: Optional URLSession to use for all requests. If omitted, `URLSession.shared` will be used. Provide a custom session for specialized configurations (authentication, certificates, custom caching, etc.).
    ///   - rateLimitHeaders: Optional specification of API request headers used for rate limiting. If omitted, rate limiting will not be performed. See ``RESTRateLimitHeaders`` for configuration details. Also see See <doc:RESTWebService#Rate-Limiting-Support>.
    ///
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

    /// Performs a web service request asynchronously.
    ///
    /// This method executes a REST API request and automatically decodes the JSON response into your specified model type.
    ///
    /// - Parameter endpoint: Web service endpoint specification describing the request (path, method, headers, query parameters, etc.).
    /// - Returns: Decoded model object of type `M` conforming to `Decodable` and `Sendable`.
    /// - Throws: ``RESTWebServiceError`` if the request fails, returns an HTTP error, or the response cannot be decoded.
    ///
    /// ## Behavior
    ///
    /// 1. Applies rate limiting if configured (waits if necessary)
    /// 2. Builds the complete URL from base URL and endpoint
    /// 3. Executes the HTTP request
    /// 4. Validates HTTP status code (accepts 200-203)
    /// 5. Decodes the JSON response
    /// 6. Updates rate limit state from response headers
    ///
    /// ## HTTP Status Codes
    ///
    /// Only status codes 200-203 are considered successful. Any other code (including 204 No Content) throws ``RESTWebServiceError/httpError(_:_:_:)``.
    ///
    /// ## Concurrency
    ///
    /// This method respects Swift's task cancellation. If the task is cancelled, it throws a `CancellationError`.
    ///
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

    /// This method enables multipage web service requests by returning a stream that can be iterated on to yield each page of results until all data has been retrieved or an error occurs.
    ///
    /// - Parameters:
    ///   - initialEndpoint: Web service endpoint specification for the first page. Must include pagination parameters (``RESTEndpoint/pageSizeQueryItem`` and either ``RESTEndpoint/offsetQueryItem`` or ``RESTEndpoint/pageQueryItem``).
    ///   - safetyLimit: Optional maximum number of pages to retrieve. Useful to prevent runaway pagination or when only a limited number or pages is required. If `nil`, continues until all pages are retrieved.
    /// - Returns: `AsyncThrowingStream` that yields page objects of type `M`.
    ///
    ///   Iteration ends when all pages are retrieved or `safetyLimit` is reached.
    ///
    /// ## Requirements
    ///
    /// The response model type `M` must conform to ``Pageable``, which requires:
    /// - `totalCount`: Total items across all pages
    /// - `currentOffset`: Starting position of this page
    /// - `submodels`: Array of items in this page
    ///
    /// ## Behavior
    ///
    /// 1. Makes initial request with provided endpoint
    /// 2. Yields the first page
    /// 3. Calculates next offset based on current progress
    /// 4. Automatically constructs endpoint for next page
    /// 5. Continues until `totalCount` is reached or `safetyLimit` is hit
    ///
    /// ## Error Handling
    ///
    /// If any page request fails, the stream throws an error and terminates:
    ///
    nonisolated public func pageStream<M>(with initialEndpoint: RESTEndpoint,
                              safetyLimit: UInt? = nil) -> AsyncThrowingStream<M,Error> where M: Decodable & Pageable & Sendable {
        let actor = PageStreamActor(wsManager: self, baseURLString: baseURL.absoluteString,
                                    initialEndpoint: initialEndpoint, safetyLimit: safetyLimit)
        return AsyncThrowingStream(unfolding: actor.unfoldingClosure)
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

        if let body = endpoint.body,
           !body.isEmpty {
            guard let validData = body.data(using: .utf8) else {
                let error = RESTWebServiceError.bodyStringInvalid(body)
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

/// Configuration for API rate limiting based on HTTP response headers.
///
/// Many REST APIs include rate limit information in response headers.
/// This struct specifies which header names to look for so the manager
/// can automatically throttle requests to stay within limits.
///
public struct RESTRateLimitHeaders: Sendable {

    /// The HTTP header name containing the total rate limit (e.g., "X-RateLimit-Limit").
    public let rateLimitKey: String
    
    /// The HTTP header name containing the remaining requests allowed (e.g., "X-RateLimit-Remaining").
    public let rateLimitRemainingKey : String

    /// Creates a rate limit header configuration.
    ///
    /// - Parameters:
    ///   - rateLimitKey: Header name for the total rate limit.
    ///   - rateLimitRemainingKey: Header name for remaining requests.
    ///
    public init(rateLimitKey: String,
                rateLimitRemainingKey: String) {
        self.rateLimitKey = rateLimitKey
        self.rateLimitRemainingKey = rateLimitRemainingKey
    }
}
