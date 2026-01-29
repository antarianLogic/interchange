//
//  InterchangeManaging.swift
//  Interchange
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

/// Protocol defining the core functionality of an Interchange manager.
///
/// This protocol allows injection so you can use alternate implementations such as mocks for testing.
///
public protocol InterchangeManaging: Actor {

    /// Performs a web API request asynchronously.
    /// - Parameter endpoint: The endpoint specification describing the request.
    /// - Returns: A decoded model object of type `M`.
    /// - Throws: ``InterchangeError`` if the request fails or decoding fails.
    ///
    func sendRequest<M>(with endpoint: RESTEndpoint) async throws -> M where M: Decodable & Sendable

    /// Creates an async stream for iterating through paginated responses.
    /// - Parameters:
    ///   - initialEndpoint: The endpoint for the first page request.
    ///   - safetyLimit: Optional maximum number of pages to retrieve.
    /// - Returns: An `AsyncThrowingStream` that the caller can iterate though to yield each page.
    ///
    nonisolated func pageStream<M>(with initialEndpoint: RESTEndpoint,
                                   safetyLimit: UInt?) -> AsyncThrowingStream<M,Error> where M: Decodable & Pageable & Sendable
}
