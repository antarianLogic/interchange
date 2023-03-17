//
//  RESTEndpoint.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2022 Antarian Logic LLC. All rights reserved.
//

import Foundation

/// Web service endpoint specification.
public struct RESTEndpoint {

    /// HTTP method (or verb). For example, GET, POST, DELETE, etc.
    public let method: RESTMethod

    /// Route path.
    public let path: String

    /// HTTP Headers.
    public let headers: [String : String]

    /// URL query parameters.
    public let queryParameters: [URLQueryItem]

    /// POST body parameters (in URLQueryItem format)
    public let bodyParameters: [URLQueryItem]

    /// The special query parameter the web service expects for page size.
    public let pageSizeQueryItem: URLQueryItem?

    /// The special query parameter the web service expects for starting offset.
    public let offsetQueryItem: URLQueryItem?

    /// The special query parameter the web service expects for starting page.
    public let pageQueryItem: URLQueryItem?

    /// The elapsed time before the last cached response is ignored and a fresh request is made.
    public let cacheInterval: TimeInterval?

    /// The elapsed time to wait for a response before giving up.
    public let timeoutInterval: TimeInterval?

    public init(method: RESTMethod = .get,
                path: String,
                headers: [String : String] = [:],
                queryParameters: [URLQueryItem] = [],
                bodyParameters: [URLQueryItem] = [],
                pageSizeQueryItem: URLQueryItem? = nil,
                offsetQueryItem: URLQueryItem? = nil,
                pageQueryItem: URLQueryItem? = nil,
                cacheInterval: TimeInterval? = nil,
                timeoutInterval: TimeInterval? = nil) {
        self.method = method
        self.path = path
        self.headers = headers
        self.queryParameters = queryParameters
        self.bodyParameters = bodyParameters
        self.pageSizeQueryItem = pageSizeQueryItem
        self.offsetQueryItem = offsetQueryItem
        self.pageQueryItem = pageQueryItem
        self.cacheInterval = cacheInterval
        self.timeoutInterval = timeoutInterval
    }
}

extension RESTEndpoint: Equatable {}

public extension RESTEndpoint {

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
                                bodyParameters: bodyParameters,
                                pageSizeQueryItem: pageSizeQueryItem, offsetQueryItem: newOffsetQueryItem,
                                cacheInterval: cacheInterval, timeoutInterval: timeoutInterval)
        } else if let validPageQueryItem = pageQueryItem {
            let newPage = (newOffset / validPageSize) + 1
            let newPageQueryItem = URLQueryItem(name: validPageQueryItem.name, value: String(newPage))
            return RESTEndpoint(method: method, path: path, headers: headers, queryParameters: queryParameters,
                                bodyParameters: bodyParameters,
                                pageSizeQueryItem: pageSizeQueryItem, pageQueryItem: newPageQueryItem,
                                cacheInterval: cacheInterval, timeoutInterval: timeoutInterval)
        } else {
            return nil
        }
    }
}
