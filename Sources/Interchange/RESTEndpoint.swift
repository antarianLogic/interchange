//
//  RESTEndpoint.swift
//  Interchange
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

/// Web service endpoint specification.
///
/// `RESTEndpoint` encapsulates all the information needed to make a RESTful API request, including the HTTP method, path, headers, query parameters, and optional features like pagination, caching, and timeouts.
///
/// See <doc:Interchange> and <doc:QuickStart> for more information.
///
public struct RESTEndpoint: Sendable {

    /// HTTP method (or verb). For example, GET, POST, DELETE, etc.
    public let method: RESTMethod

    /// Route path relative to the base URL.
    ///
    /// Example: `/search` or `/users/123`
    ///
    /// This is appended to the base URL configured in ``InterchangeManager``.
    ///
    public let path: String

    /// A string valued dictionary representing the HTTP headers to include in the request.
    ///
    /// Common headers include `Authorization`, `Content-Type`, `Accept`, etc.
    ///
    /// Example:
    /// ```swift
    /// ["Authorization": "Bearer token123",
    ///  "Content-Type": "application/json"]
    /// ```
    public let headers: [String : String]

    /// An array of URLQueryItem representing the URL query parameters to append to the path.
    ///
    /// These will be URL-encoded and appended after a `?` in the final URL.
    ///
    /// Example:
    /// ```swift
    /// [URLQueryItem(name: "search", value: "swift"),
    ///  URLQueryItem(name: "limit", value: "20")]
    /// // Results in: ?search=swift&limit=20
    /// ```
    public let queryParameters: [URLQueryItem]

    /// POST/PUT/PATCH body string.
    ///
    /// The string will be converted to UTF-8 data. Be sure and set the `Content-Type` header appropriately to specify what format it is in (e.g., "application/json").
    ///
    public let body: String?

    /// Query parameter specifying the page size for paginated requests.
    ///
    /// Different APIs use different parameter names (e.g., "limit", "per_page", "size").
    ///
    /// Example: `URLQueryItem(name: "limit", value: "50")`
    ///
    public let pageSizeQueryItem: URLQueryItem?

    /// A query parameter some web services expect, specifying the starting offset for paginated requests.
    ///
    /// Used for offset-based pagination (as opposed to page-number-based).
    /// Mutually exclusive with ``pageQueryItem``.
    ///
    /// Example: `URLQueryItem(name: "offset", value: "100")`
    ///
    public let offsetQueryItem: URLQueryItem?

    /// A query parameter some web services expect, specifying the page number for paginated requests.
    ///
    /// Used for page-number-based pagination (as opposed to offset-based).
    /// Mutually exclusive with ``offsetQueryItem``.
    ///
    /// Example: `URLQueryItem(name: "page", value: "3")`
    ///
    public let pageQueryItem: URLQueryItem?

    /// The elapsed time in seconds before the last cached response is ignored and a fresh request is made.
    ///
    /// If a cached response exists and is newer than this interval, it will be returned instead of making a network request.
    ///
    /// Set to `nil` (default) to use standard cache policy.
    ///
    /// Example: `300` for 5 minutes of caching.
    ///
    public let cacheInterval: TimeInterval?

    /// The elapsed time in seconds to wait for a response before giving up.
    ///
    /// If the server doesn't respond within this time, the request fails with a timeout error.
    ///
    /// Set to `nil` (default) to use the URLSession's default timeout.
    ///
    /// Example: `60` for a 60-second timeout.
    ///
    public let timeoutInterval: TimeInterval?

    /// Creates an endpoint specification.
    ///
    /// - Parameters:
    ///   - method: HTTP method to use. Defaults to `.get`.
    ///   - path: Route path relative to the base URL.
    ///   - headers: HTTP headers for the request. Defaults to an empty dictionary.
    ///   - queryParameters: URL query parameters. Defaults to an empty array.
    ///   - body: Request body string for POST/PUT/PATCH requests. Defaults to `nil`.
    ///   - pageSizeQueryItem: Page size parameter for pagination. Defaults to `nil`.
    ///   - offsetQueryItem: Starting offset parameter for pagination. Defaults to `nil`.
    ///   - pageQueryItem: Page number parameter for pagination. Defaults to `nil`.
    ///   - cacheInterval: Response cache duration in seconds. Defaults to `nil`.
    ///   - timeoutInterval: Request timeout in seconds. Defaults to `nil`.
    ///
    public init(method: RESTMethod = .get,
                path: String,
                headers: [String : String] = [:],
                queryParameters: [URLQueryItem] = [],
                body: String? = nil,
                pageSizeQueryItem: URLQueryItem? = nil,
                offsetQueryItem: URLQueryItem? = nil,
                pageQueryItem: URLQueryItem? = nil,
                cacheInterval: TimeInterval? = nil,
                timeoutInterval: TimeInterval? = nil) {
        self.method = method
        self.path = path
        self.headers = headers
        self.queryParameters = queryParameters
        self.body = body
        self.pageSizeQueryItem = pageSizeQueryItem
        self.offsetQueryItem = offsetQueryItem
        self.pageQueryItem = pageQueryItem
        self.cacheInterval = cacheInterval
        self.timeoutInterval = timeoutInterval
    }
}

extension RESTEndpoint: Equatable {}

// Internal Helpers

extension RESTEndpoint {

    var pageSize: UInt? {
        guard let pageSizeString = pageSizeQueryItem?.value else { return nil }

        return UInt(pageSizeString)
    }

    var currentOffset: UInt? {
        if let currentOffsetString = offsetQueryItem?.value {
            return UInt(currentOffsetString)
        } else if let currentPageString = pageQueryItem?.value,
                  let currentPage = UInt(currentPageString),
                  let validPageSize = pageSize {
            return (currentPage - 1) * validPageSize
        } else {
            return nil
        }
    }

    func nextPageEndpoint(at offset: UInt? = nil) -> RESTEndpoint? {
        guard let validPageSize = pageSize,
              let validCurrentOffset = currentOffset else { return nil }

        let newOffset = offset ?? (validCurrentOffset + validPageSize)

        if let validOffsetQueryItem = offsetQueryItem {
            let newOffsetQueryItem = URLQueryItem(name: validOffsetQueryItem.name, value: String(newOffset))
            return RESTEndpoint(method: method, path: path, headers: headers, queryParameters: queryParameters,
                                body: body,
                                pageSizeQueryItem: pageSizeQueryItem, offsetQueryItem: newOffsetQueryItem,
                                cacheInterval: cacheInterval, timeoutInterval: timeoutInterval)
        } else if let validPageQueryItem = pageQueryItem {
            let newPage = (newOffset / validPageSize) + 1
            let newPageQueryItem = URLQueryItem(name: validPageQueryItem.name, value: String(newPage))
            return RESTEndpoint(method: method, path: path, headers: headers, queryParameters: queryParameters,
                                body: body,
                                pageSizeQueryItem: pageSizeQueryItem, pageQueryItem: newPageQueryItem,
                                cacheInterval: cacheInterval, timeoutInterval: timeoutInterval)
        } else {
            return nil
        }
    }
}
