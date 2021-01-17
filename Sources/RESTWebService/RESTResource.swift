//
//  RESTResource.swift
//  RESTWebService
//
//  Created by antarianLogic on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

protocol RESTResource {

    var path: String { get }

    var queryParameters: [URLQueryItem] { get }
}

struct RESTReadResource<Model: Decodable>: RESTResource {

    let path: String

    let queryParameters: [URLQueryItem]
}
