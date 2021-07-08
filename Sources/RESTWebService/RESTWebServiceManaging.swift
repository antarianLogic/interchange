//
//  RESTWebServiceManaging.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Combine

public protocol RESTWebServiceManaging {

    func get<M>(with resource: RESTResource<M>) async throws -> M

    func getAllPages<M: Pageable>(with resource: RESTResource<M>, safetyLimit: UInt) -> AnyPublisher<[M], Error>

    func multipageGetter<M: Pageable>(with initialResource: RESTResource<M>) -> MultipageGetter<M>
}
