//
//  RESTWebServiceManager.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

public actor RESTWebServiceManager {

    public init(baseURL: URL,
                session: URLSession = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
    }

    nonisolated let baseURL: URL
    nonisolated let session: URLSession
}

extension RESTWebServiceManager: RESTWebServiceManaging {

    public func get<M>(with resource: RESTResource<M>) async throws -> M {

        let request = try buildRequest(with: resource)

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 204 else {
                let errorString = String(data: data.prefix(1024), encoding: .utf8) ?? ""
                throw RESTWebServiceError.httpError(httpResponse.statusCode, errorString)
            }
        }

        return try JSONDecoder().decode(M.self, from: data)
    }

    nonisolated public func pageStream<M: Pageable>(with initialResource: RESTResource<M>,
                                                    safetyLimit: UInt? = nil) -> AsyncThrowingStream<M, Error> {

        var currentResource = initialResource
        var totalCount: UInt? = nil
        var receivedCount: UInt = 0

        return AsyncThrowingStream { [weak self] in
            guard let strongSelf = self else { return nil }

            if let uSafetyLimit = safetyLimit {
                guard receivedCount < uSafetyLimit else { throw RESTWebServiceError.safetyLimitReached }
            }

            if let uTotalCount = totalCount {
                // not first pass
                guard receivedCount < uTotalCount else { return nil }

                guard let newResource = currentResource.nextPageResource(at: receivedCount) else {
                    throw RESTWebServiceError.invalidRESTResource
                }

                currentResource = newResource
            }
            let model = try await strongSelf.get(with: currentResource)

            try Task.checkCancellation()

            totalCount = model.totalCount
            receivedCount += UInt(model.submodels.count)
            return model
        }
    }
}

extension RESTWebServiceManager {

    nonisolated func buildRequest<M>(with resource: RESTResource<M>) throws -> URLRequest {

        let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        guard var validComponents = components else {
            throw RESTWebServiceError.invalidBaseURL(baseURL.absoluteString)
        }

        validComponents.path = validComponents.path.appending(resource.path)

        var queryItems = resource.queryParameters
        if let pageSizeQueryItem = resource.pageSizeQueryItem {
            queryItems.append(pageSizeQueryItem)
        }
        if let offsetQueryItem = resource.offsetQueryItem {
            queryItems.append(offsetQueryItem)
        } else if let pageQueryItem = resource.pageQueryItem {
            queryItems.append(pageQueryItem)
        }
        if !queryItems.isEmpty {
            validComponents.queryItems = queryItems
        }

        guard let url = validComponents.url else {
            throw RESTWebServiceError.insufficientURLComponents(validComponents.description)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for header in resource.headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }

        if let cacheInterval = resource.cacheInterval,
           cacheInterval > 0,
           let cachedResponse = session.configuration.urlCache?.cachedResponse(for: request),
           let httpURLResponse = cachedResponse.response as? HTTPURLResponse,
           let dateString = httpURLResponse.value(forHTTPHeaderField: "Date"),
           let date = DateFormatter.rfc822DateFormatter.date(from: dateString),
           date.timeIntervalSinceNow > -cacheInterval {
            // use cached response
            request.cachePolicy = .returnCacheDataElseLoad
        } // otherwise just use default cachePolicy (.useProtocolCachePolicy)

        if let timeoutInterval = resource.timeoutInterval,
           timeoutInterval > 0 {
            request.timeoutInterval = timeoutInterval
        }

        return request
    }
}
