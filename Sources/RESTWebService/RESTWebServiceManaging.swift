//
//  RESTWebServiceManaging.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

public protocol RESTWebServiceManaging: Actor {

    func sendRequest<M>(with endpoint: RESTEndpoint) async throws -> M where M: Decodable & Sendable

    func pageStream<M>(with initialEndpoint: RESTEndpoint,
                       safetyLimit: UInt?) -> AsyncThrowingStream<M,Error> where M: Decodable & Pageable & Sendable
}
