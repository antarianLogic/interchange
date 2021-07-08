//
//  MultipageGetter.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 2/11/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Combine

public final class MultipageGetter<M: Codable & Pageable> {

    public var publisher: AnyPublisher<M, Error> { subject.eraseToAnyPublisher() }

    public var receivedAllPages: Bool {
        guard let validTotalCount = totalCount else { return false }

        return receivedCount >= validTotalCount
    }

    @discardableResult
    public func getNextPage() -> Bool {
        if totalCount != nil {
            // not first pass
            guard !receivedAllPages else { return false }
            guard let newResource = currentResource.nextPageResource(at: receivedCount) else { return false } // TODO: log something here?

            currentResource = newResource
        }
        Task {
            do {
                let model = try await manager.get(with: currentResource)
                try Task.checkCancellation()
                totalCount = model.totalCount
                receivedCount += UInt(model.submodels.count)
                subject.send(model)
                if receivedAllPages {
                    subject.send(completion: .finished)
                }
            } catch {
                subject.send(completion: .failure(error))
            }
        }
        return true
    }

    var receivedCount: UInt = 0
    var totalCount: UInt?
    var currentResource: RESTResource<M>
    let manager: RESTWebServiceManaging
    let subject = PassthroughSubject<M, Error>()

    init(initialResource: RESTResource<M>,
         manager : RESTWebServiceManaging) {
        self.currentResource = initialResource
        self.manager = manager
    }

    func safetyLimitReached() {
        subject.send(completion: .failure(RESTWebServiceError.safetyLimitReached))
    }
}
