//
//  MultipageGetter.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 2/11/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Combine

public final class MultipageGetter<M: Codable & Pageable> {

    public private(set) var recievedCount: UInt = 0
    public private(set) var totalCount: UInt?

    public var publisher: AnyPublisher<M, RESTWebServiceError> { subject.eraseToAnyPublisher() }

    public var receivedAllPages: Bool {
        guard let validTotalCount = totalCount else { return false }

        return recievedCount >= validTotalCount
    }

    private(set) var currentResource: RESTResource<M>
    let manager: RESTWebServiceManaging
    let subject = PassthroughSubject<M, RESTWebServiceError>()
    private var cancellables: Set<AnyCancellable> = []

    init(initialResource: RESTResource<M>,
         manager : RESTWebServiceManaging) {
        self.currentResource = initialResource
        self.manager = manager
    }

    @discardableResult
    public func getNextPage() -> Bool {
        if totalCount != nil {
            // not first pass
            guard !receivedAllPages else { return false }
            guard let newResource = currentResource.nextPageResource() else { return false } // TODO: log something here?

            currentResource = newResource
        } else {
            // first pass
            // skip any more requests after the first one until we have totalCount
            guard cancellables.isEmpty else { return false }
        }
        let cancellable = manager.get(with: currentResource)
            .sink(receiveCompletion: receivedCompletion,
                  receiveValue: receivedValue)
        cancellables.insert(cancellable)
        return true
    }

    func receivedCompletion(completion: Subscribers.Completion<RESTWebServiceError>) {
        switch completion {
        case .finished:
            if receivedAllPages {
                subject.send(completion: completion)
                cancellables.removeAll()
            }
        case .failure:
            subject.send(completion: completion)
        }
    }

    func receivedValue(model: M) {
        // TODO: maybe check totalCount against value from previous page and log if it is different, cuz that would be weird
        totalCount = model.totalCount
        recievedCount += UInt(model.submodels.count)
        subject.send(model)
    }
}
