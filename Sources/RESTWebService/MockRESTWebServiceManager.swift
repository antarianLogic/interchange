//
//  MockRESTWebServiceManager.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/29/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation
import Combine

public final class MockRESTWebServiceManager {

    public required init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    public var mockData: Any? = nil

    var shouldFail = false

    var arraySubject: AnyObject? = nil
}

extension MockRESTWebServiceManager: RESTWebServiceManaging {

    public func get<M>(with resource: RESTResource<M>) async throws -> M {

        await Task.sleep(1000)

        guard !shouldFail else {
            throw RESTWebServiceError.httpError(404, "404 Not Found")
        }

        guard let model = mockData as? M else { fatalError() }

        return model
    }

    public func getAllPages<M: Pageable>(with resource: RESTResource<M>, safetyLimit: UInt = 0) -> AnyPublisher<[M], Error> {
        let subject = PassthroughSubject<[M], Error>()
        arraySubject = subject
        if shouldFail {
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(100)) {
                subject.send(completion: .failure(RESTWebServiceError.httpError(404, "404 Not Found")))
            }
        } else {
            guard let model = mockData as? [M] else { fatalError() }

            DispatchQueue.global(qos: .utility).asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(100)) {
                subject.send(model)
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(100)) {
                    subject.send(model)
                    DispatchQueue.global(qos: .utility).asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(100)) {
                        subject.send(completion: .finished)
                    }
                }
            }
        }
        return subject
            .receive(on: DispatchQueue.global(qos: .utility))
            .eraseToAnyPublisher()
    }

    public func multipageGetter<M: Pageable>(with initialResource: RESTResource<M>) -> MultipageGetter<M> {
        return MultipageGetter(initialResource: initialResource, manager: self)
    }
}
