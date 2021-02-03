//
//  RESTWebServiceManaging.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

public protocol RESTWebServiceManaging {

    @discardableResult
    func get<Model>(resource: RESTResource<Model>,
                    successOnMainQueue: Bool,
                    onCompletion: @escaping (Result<Model, RESTWebServiceError>) -> Void) -> URLRequest?
}

public extension RESTWebServiceManaging {

    @discardableResult
    func get<Model>(resource: RESTResource<Model>,
                    onCompletion: @escaping (Result<Model, RESTWebServiceError>) -> Void) -> URLRequest? {
        return get(resource: resource, successOnMainQueue: true, onCompletion: onCompletion)
    }
}
