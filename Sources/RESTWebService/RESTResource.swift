//
//  RESTResource.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2022 Antarian Logic LLC. All rights reserved.
//

import Foundation

public struct RESTResource {

    public let method: RESTMethod

    public let path: String

    public let headers: [String : String]

    public let queryParameters: [URLQueryItem]

    public let bodyParameters: [URLQueryItem]

    public let pageSizeQueryItem: URLQueryItem?

    public let offsetQueryItem: URLQueryItem?

    public let pageQueryItem: URLQueryItem?

    public let cacheInterval: TimeInterval?

    public let timeoutInterval: TimeInterval?

    public let enableRateLimiting: Bool

    public init(method: RESTMethod = .get,
                path: String,
                headers: [String : String] = [:],
                queryParameters: [URLQueryItem] = [],
                bodyParameters: [URLQueryItem] = [],
                pageSizeQueryItem: URLQueryItem? = nil,
                offsetQueryItem: URLQueryItem? = nil,
                pageQueryItem: URLQueryItem? = nil,
                cacheInterval: TimeInterval? = nil,
                timeoutInterval: TimeInterval? = nil,
                enableRateLimiting: Bool = false) {
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
        self.enableRateLimiting = enableRateLimiting
    }
}

extension RESTResource: Equatable {}

public extension RESTResource {

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

    func nextPageResource(at offset: UInt? = nil) -> RESTResource? {
        guard let validPageSize = pageSize,
              let validCurrentOffset = currentOffset else { return nil }

        let newOffset = offset ?? (validCurrentOffset + validPageSize)

        if let validOffsetQueryItem = offsetQueryItem {
            let newOffsetQueryItem = URLQueryItem(name: validOffsetQueryItem.name, value: String(newOffset))
            return RESTResource(method: method, path: path, headers: headers, queryParameters: queryParameters,
                                bodyParameters: bodyParameters,
                                pageSizeQueryItem: pageSizeQueryItem, offsetQueryItem: newOffsetQueryItem,
                                cacheInterval: cacheInterval, timeoutInterval: timeoutInterval)
        } else if let validPageQueryItem = pageQueryItem {
            let newPage = (newOffset / validPageSize) + 1
            let newPageQueryItem = URLQueryItem(name: validPageQueryItem.name, value: String(newPage))
            return RESTResource(method: method, path: path, headers: headers, queryParameters: queryParameters,
                                bodyParameters: bodyParameters,
                                pageSizeQueryItem: pageSizeQueryItem, pageQueryItem: newPageQueryItem,
                                cacheInterval: cacheInterval, timeoutInterval: timeoutInterval)
        } else {
            return nil
        }
    }
}
