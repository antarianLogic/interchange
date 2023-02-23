//
//  MockRESTWebServiceManager.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/29/21.
//  Copyright © 2022 Antarian Logic LLC. All rights reserved.
//

public actor MockRESTWebServiceManager {

    public init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    public func setMockData(_ value: Any?) {
        mockData = value
    }

    var mockData: Any? = nil

    let shouldFail: Bool
}

extension MockRESTWebServiceManager: RESTWebServiceManaging {

    public func sendRequest<M>(with resource: RESTResource) async throws -> M where M: Decodable {

        try await Task.sleep(nanoseconds: 10)

        guard !shouldFail else {
            throw RESTWebServiceError.httpError(404, "404 Not Found")
        }

        guard let model = mockData as? M else { fatalError() }

        return model
    }

    public nonisolated func pageStream<M>(with initialResource: RESTResource,
                                          safetyLimit: UInt? = nil) -> AsyncThrowingStream<M,Error> where M: Decodable & Pageable {

        var currentResource = initialResource
        var totalCount: UInt? = nil
        var receivedCount: UInt = 0

        return AsyncThrowingStream { [weak self] in
            guard let strongSelf = self else { return nil }

            if let uSafetyLimit = safetyLimit {
                guard receivedCount < uSafetyLimit else { throw RESTWebServiceError.safetyLimitReached(currentResource.path) }
            }

            if let uTotalCount = totalCount {
                // not first pass
                guard receivedCount < uTotalCount else { return nil }

                guard let newResource = currentResource.nextPageResource(at: receivedCount) else {
                    throw RESTWebServiceError.invalidRESTResource(currentResource.path)
                }

                currentResource = newResource
            }
            let model: M = try await strongSelf.sendRequest(with: currentResource)

            try Task.checkCancellation()

            totalCount = model.totalCount
            receivedCount += UInt(model.submodels.count)
            return model
        }
    }
}
