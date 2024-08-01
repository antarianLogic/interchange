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

    nonisolated public func pageStream<M>(with initialEndpoint: RESTEndpoint,
                              safetyLimit: UInt? = nil) -> AsyncThrowingStream<M,Error> where M: Decodable & Pageable & Sendable {
        let actor = PageStreamActor(wsManager: self, baseURLString: "",
                                    initialEndpoint: initialEndpoint, safetyLimit: safetyLimit)
        return AsyncThrowingStream(unfolding: actor.unfoldingClosure)
    }
}
