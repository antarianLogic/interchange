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
    func get<M>(with resource: RESTResource<M>,
                successOnMainQueue: Bool,
                onCompletion: @escaping (Result<M, RESTWebServiceError>) -> Void) -> URLRequest?

    @discardableResult
    func getMultipage<M: Pageable>(with resource: RESTResource<M>,
                                   successOnMainQueue: Bool,
                                   onCompletion: @escaping (Result<[M.Submodel], RESTWebServiceError>) -> Void) -> URLRequest?
}

public extension RESTWebServiceManaging {

    @discardableResult
    func get<M>(with resource: RESTResource<M>,
                onCompletion: @escaping (Result<M, RESTWebServiceError>) -> Void) -> URLRequest? {
        return get(with: resource, successOnMainQueue: true, onCompletion: onCompletion)
    }

    @discardableResult
    func getMultipage<M: Pageable>(with resource: RESTResource<M>,
                                   onCompletion: @escaping (Result<[M.Submodel], RESTWebServiceError>) -> Void) -> URLRequest? {
        return getMultipage(with: resource, successOnMainQueue: true, onCompletion: onCompletion)
    }
}
