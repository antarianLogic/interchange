//
//  RESTWebServiceManaging.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2022 Antarian Logic LLC. All rights reserved.
//

public protocol RESTWebServiceManaging: Actor {

    nonisolated func sendRequest<M>(with resource: RESTResource) async throws -> M where M: Decodable

    nonisolated func pageStream<M>(with initialResource: RESTResource,
                                   safetyLimit: UInt?) -> AsyncThrowingStream<M,Error> where M: Decodable & Pageable
}
