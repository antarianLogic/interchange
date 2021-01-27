//
//  RESTWebServiceManaging.swift
//  RESTWebService
//
//  Created by antarianLogic on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

public protocol RESTWebServiceManaging {

    init(baseURL: URL, session: URLSession)

    func get<Model: Decodable>(resource: RESTResource<Model>,
                               completionHandler: @escaping (Result<Model, RESTWebServiceError>) -> Void) -> URLRequest?
}
