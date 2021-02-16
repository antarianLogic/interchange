//
//  RESTResource.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

public struct RESTResource<Model: Codable> {

    public let path: String

    public let headers: [String : String]

    public let queryParameters: [URLQueryItem]

    public let model: Model?

    public let pageSizeQueryItem: URLQueryItem?

    public let offsetQueryItem: URLQueryItem?

    public let cacheInterval: TimeInterval?

    public let timeoutInterval: TimeInterval?

    public init(path: String,
                headers: [String : String] = [:],
                queryParameters: [URLQueryItem] = [],
                model: Model? = nil,
                pageSizeQueryItem: URLQueryItem? = nil,
                offsetQueryItem: URLQueryItem? = nil,
                cacheInterval: TimeInterval? = nil,
                timeoutInterval: TimeInterval? = nil) {
        self.path = path
        self.headers = headers
        self.queryParameters = queryParameters
        self.model = model
        self.pageSizeQueryItem = pageSizeQueryItem
        self.offsetQueryItem = offsetQueryItem
        self.cacheInterval = cacheInterval
        self.timeoutInterval = timeoutInterval
    }
}

extension RESTResource: Equatable where Model: Equatable {}

public extension RESTResource {

    var pageSize: UInt? {
        guard let pageSizeString = pageSizeQueryItem?.value else { return nil }

        return UInt(pageSizeString)
    }

    var currentOffset: UInt? {
        guard let currentOffsetString = offsetQueryItem?.value else { return nil }

        return UInt(currentOffsetString)
    }

    func nextPageResource(at offset: UInt? = nil) -> RESTResource? {
        guard let validPageSize = pageSize,
              let validCurrentOffset = currentOffset,
              let validOffsetQueryItem = offsetQueryItem else { return nil }

        let newOffset = offset ?? validCurrentOffset + validPageSize
        let newOffsetQueryItem = URLQueryItem(name: validOffsetQueryItem.name, value: String(newOffset))
        return RESTResource(path: path, headers: headers, queryParameters: queryParameters, model: model,
                            pageSizeQueryItem: pageSizeQueryItem, offsetQueryItem: newOffsetQueryItem,
                            cacheInterval: cacheInterval, timeoutInterval: timeoutInterval)
    }
}
