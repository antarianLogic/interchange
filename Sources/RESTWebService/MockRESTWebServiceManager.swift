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

    var shouldFail = false

    var singleSubject: AnyObject? = nil
    var arraySubject: AnyObject? = nil
}

extension MockRESTWebServiceManager: RESTWebServiceManaging {

    public func get<M>(with resource: RESTResource<M>) -> AnyPublisher<M, RESTWebServiceError> {
        let subject = PassthroughSubject<M, RESTWebServiceError>()
        singleSubject = subject
        if shouldFail {
            DispatchQueue.global(qos: .utility).async { [weak self] in
                let error = RESTWebServiceError.httpError(404, "404 Not Found")
                subject.send(completion: .failure(error))
                self?.singleSubject = nil
            }
        } else {
            guard let model = try? JSONDecoder().decode(M.self, from: Data()) else { fatalError() }

            DispatchQueue.global(qos: .utility).async { [weak self] in
                subject.send(model)
                subject.send(completion: .finished)
                self?.singleSubject = nil
            }
        }
        return subject
            .receive(on: DispatchQueue.global(qos: .utility))
            .eraseToAnyPublisher()
    }

    public func getAllPages<M: Pageable>(with resource: RESTResource<M>, safetyLimit: UInt) -> AnyPublisher<[M], RESTWebServiceError> {
        let subject = PassthroughSubject<[M], RESTWebServiceError>()
        arraySubject = subject
        if shouldFail {
            DispatchQueue.global(qos: .utility).async { [weak self] in
                let error = RESTWebServiceError.httpError(404, "404 Not Found")
                subject.send(completion: .failure(error))
                self?.arraySubject = nil
            }
        } else {
            guard let model = try? JSONDecoder().decode([M].self, from: Data()) else { fatalError() }

            DispatchQueue.global(qos: .utility).async { [weak self] in
                subject.send(model)
                DispatchQueue.global(qos: .utility).async { [weak self] in
                    subject.send(model)
                    subject.send(completion: .finished)
                    self?.arraySubject = nil
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
