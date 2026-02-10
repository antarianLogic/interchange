//
//  MockInterchangeManager.swift
//  Interchange
//
//  Created by Carl Sheppard on 1/29/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

/// A type conforming to InterchangeManaging that can be injected in testing or preview code as a benign alternative to a real InterchangeManager.
///
/// See <doc:Interchange#Testing> for more information.
///
public actor MockInterchangeManager {

    /// Creates a new mock InterchangeManager.
    ///
    /// - Parameter shouldFail: Flag to allow simulation of request failures.
    ///
    public init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    /// Enables loading mock data to be returned from the requests.
    ///
    /// Call this with data in the reverse order that it should be returned by each request.
    ///
    /// - Parameter value: Some data to be returned by the next request.
    ///
    public func pushMockData(_ value: Any) {
        mockData.append(value)
    }

    /// Empty all the mock data loaded so far.
    ///
    public func clearMockData() {
        mockData = []
    }

    var mockData: [Any] = []

    let shouldFail: Bool
}

extension MockInterchangeManager: InterchangeManaging {

    /// Simulates an asynchronous web API request by simply sleeping for a short time.
    ///
    /// - Parameter endpoint: Endpoint specification as required by `InterchangeManaging`. It is ignored by this implementation. Pass any value.
    /// - Returns: The data currently at the top of the stack that was pushed previously with ``pushMockData(_:)``.
    /// - Throws: ``InterchangeError``of value `.httpError` and code 404 if `shouldFail` is true.
    ///
    /// ## Preconditions
    ///
    /// The data stack associated with ``pushMockData(_:)`` must not be empty and the item currently at the top of the stack must be of the same type as `M`.
    ///
    /// ## Postconditions
    ///
    /// The data previously at the top of the stack associated with ``pushMockData(_:)`` will be popped off.
    ///
    public func sendRequest<M>(with endpoint: RESTEndpoint) async throws -> M where M: Decodable & Sendable {

        try await Task.sleep(nanoseconds: 10)

        guard !shouldFail else {
            throw InterchangeError.httpError(404, "404 Not Found", "http://example.com")
        }

        guard let model = mockData.popLast() as? M else { fatalError() }

        return model
    }

    /// Simulates multipage web service requests by returning a stream that can be iterated on to yield each page of results until all data has been retrieved or `shouldFail` is true.
    ///
    /// - Parameters:
    ///   - initialEndpoint: Endpoint specification as required by `InterchangeManaging`. It is ignored by this implementation. Pass any value.
    ///   - safetyLimit: Optional maximum number of pages to retrieve. If `nil`, continues until all pages are retrieved.
    /// - Returns: `AsyncThrowingStream` that yields page objects of type `M`.
    ///
    nonisolated public func pageStream<M>(with initialEndpoint: RESTEndpoint,
                              safetyLimit: UInt? = nil) -> AsyncThrowingStream<M,Error> where M: Decodable & Pageable & Sendable {
        let actor = PageStreamActor(wsManager: self, baseURLString: "",
                                    initialEndpoint: initialEndpoint, safetyLimit: safetyLimit)
        return AsyncThrowingStream(unfolding: actor.unfoldingClosure)
    }
}
