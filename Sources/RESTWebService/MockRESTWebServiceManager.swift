//
//  MockRESTWebServiceManager.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/29/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

public actor MockRESTWebServiceManager {

    public init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    public func pushMockData(_ value: Any) {
        mockData.append(value)
    }

    public func clearMockData() {
        mockData = []
    }

    var mockData: [Any] = []

    let shouldFail: Bool
}

extension MockRESTWebServiceManager: RESTWebServiceManaging {

    public func sendRequest<M>(with endpoint: RESTEndpoint) async throws -> M where M: Decodable & Sendable {

        try await Task.sleep(nanoseconds: 10)

        guard !shouldFail else {
            throw RESTWebServiceError.httpError(404, "404 Not Found", "http://example.com")
        }

        guard let model = mockData.popLast() as? M else { fatalError() }

        return model
    }

    public nonisolated func pageStream<M>(with initialEndpoint: RESTEndpoint,
                                          safetyLimit: UInt? = nil) -> AsyncThrowingStream<M,Error> where M: Decodable & Pageable & Sendable {

        var currentEndpoint = initialEndpoint
        var totalCount: UInt? = nil
        var receivedCount: UInt = 0

        return AsyncThrowingStream { [weak self] in
            guard let strongSelf = self else { return nil }

            if let uSafetyLimit = safetyLimit {
                guard receivedCount < uSafetyLimit else { throw RESTWebServiceError.safetyLimitReached(currentEndpoint.path) }
            }

            if let uTotalCount = totalCount {
                // not first pass
                guard receivedCount < uTotalCount else { return nil }

                guard let newEndpoint = currentEndpoint.nextPageEndpoint(at: receivedCount) else {
                    throw RESTWebServiceError.invalidRESTEndpoint(currentEndpoint.path)
                }

                currentEndpoint = newEndpoint
            }
            let model: M = try await strongSelf.sendRequest(with: currentEndpoint)

            totalCount = model.totalCount
            receivedCount += UInt(model.submodels.count)
            return model
        }
    }
}
