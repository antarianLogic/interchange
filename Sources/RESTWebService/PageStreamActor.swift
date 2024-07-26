//
//  PageStreamActor.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 7/25/24.
//  Copyright © 2024 Antarian Logic LLC. All rights reserved.
//

actor PageStreamActor {

    init(wsManager: RESTWebServiceManaging,
         baseURLString: String,
         initialEndpoint: RESTEndpoint,
         safetyLimit: UInt? = nil) {
        self.wsManager = wsManager
        self.baseURLString = baseURLString
        currentEndpoint = initialEndpoint
        self.safetyLimit = safetyLimit
    }

    let wsManager: RESTWebServiceManaging
    let baseURLString: String
    var currentEndpoint: RESTEndpoint
    let safetyLimit: UInt?
    var totalCount: UInt? = nil
    var receivedCount: UInt = 0

    func unfoldingClosure<M>() async throws -> M? where M: Decodable & Pageable & Sendable {
        if let uSafetyLimit = safetyLimit {
            guard receivedCount < uSafetyLimit else {
                let failingURL = "\(baseURLString)/\(currentEndpoint.path)"
                throw RESTWebServiceError.safetyLimitReached(failingURL)
            }
        }

        if let uTotalCount = totalCount {
            // not first pass
            guard receivedCount < uTotalCount else { return nil } // returning nil terminates stream

            guard let newEndpoint = currentEndpoint.nextPageEndpoint(at: receivedCount) else {
                let failingURL = "\(baseURLString)/\(currentEndpoint.path)"
                throw RESTWebServiceError.invalidRESTEndpoint(failingURL)
            }

            currentEndpoint = newEndpoint
        }
        let model: M = try await wsManager.sendRequest(with: currentEndpoint)

        totalCount = model.totalCount
        receivedCount += UInt(model.submodels.count)
        return model
    }
}
