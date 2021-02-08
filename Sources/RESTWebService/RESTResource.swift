//
//  RESTResource.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

public struct RESTResource<Model: Codable> {

    public init(path: String,
                headers: [String : String] = [:],
                queryParameters: [URLQueryItem] = [],
                model: Model? = nil,
                offsetQueryItem: URLQueryItem? = nil,
                cacheTime: TimeInterval? = nil,
                timeout: TimeInterval? = nil) {
        self.path = path
        self.headers = headers
        self.queryParameters = queryParameters
        self.model = model
        self.offsetQueryItem = offsetQueryItem
        self.cacheTime = cacheTime
        self.timeout = timeout
    }

    public let path: String

    public let headers: [String : String]

    public let queryParameters: [URLQueryItem]

    public let model: Model?

    public let offsetQueryItem: URLQueryItem?

    public let cacheTime: TimeInterval?

    public let timeout: TimeInterval?
}
