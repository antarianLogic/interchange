//
//  RESTResource.swift
//  RESTWebService
//
//  Created by antarianLogic on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

public protocol RESTResource {

    var path: String { get }

    var headers: [String : String] { get }

    var queryParameters: [URLQueryItem] { get }
}

public struct RESTReadResource<Model: Decodable>: RESTResource {

    public init(path: String,
                headers: [String : String] = [:],
                queryParameters: [URLQueryItem] = []) {
        self.path = path
        self.headers = headers
        self.queryParameters = queryParameters
    }

    public let path: String

    public let headers: [String : String]

    public let queryParameters: [URLQueryItem]
}
