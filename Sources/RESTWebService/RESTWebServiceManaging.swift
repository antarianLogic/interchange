//
//  RESTWebServiceManaging.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

public protocol RESTWebServiceManaging: Actor {

    func get<M>(with resource: RESTResource<M>) async throws -> M

    func pageStream<M: Pageable>(with initialResource: RESTResource<M>,
                                 safetyLimit: UInt?) -> AsyncThrowingStream<M, Error>
}
