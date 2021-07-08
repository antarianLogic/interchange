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
        Task.detached { [weak self] in
            guard let strongSelf = self else { return }

            do {
                let model = try await strongSelf.manager.get(with: strongSelf.currentResource)
                try Task.checkCancellation()
                strongSelf.totalCount = model.totalCount
                strongSelf.receivedCount += UInt(model.submodels.count)
                strongSelf.subject.send(model)
                if strongSelf.receivedAllPages {
                    strongSelf.subject.send(completion: .finished)
                }
            } catch {
                strongSelf.subject.send(completion: .failure(error))
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
