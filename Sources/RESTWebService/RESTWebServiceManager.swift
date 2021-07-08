//
//  RESTWebServiceManager.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation
import Combine

public final class RESTWebServiceManager {

    public required init(baseURL: URL,
                         session: URLSession = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
    }

    let baseURL: URL
    let session: URLSession

    var cancellable: AnyCancellable?
}

extension RESTWebServiceManager: RESTWebServiceManaging {

    public func get<M>(with resource: RESTResource<M>) async throws -> M {

        let request = try buildRequest(with: resource)

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 204 else {
                let errorString = String(data: data.prefix(128), encoding: .utf8) ?? ""
                throw RESTWebServiceError.httpError(httpResponse.statusCode, errorString)
            }
        }

        return try JSONDecoder().decode(M.self, from: data)
    }

    public func getAllPages<M: Pageable>(with resource: RESTResource<M>, safetyLimit: UInt = 0) -> AnyPublisher<[M], Error> {
        let subject = PassthroughSubject<[M], Error>()
        let getter = multipageGetter(with: resource)
        var models: [M] = []
        cancellable = getter.publisher
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    subject.send(models)
                case let .failure(error):
                    if case let wsError = error as? RESTWebServiceError,
                       case .safetyLimitReached = wsError {
                        subject.send(models)
                    }
                }
                subject.send(completion: completion)
                self?.cancellable = nil
            } receiveValue: { receivedModel in
                models.append(receivedModel)
                if !getter.receivedAllPages {
                    if safetyLimit > 0 {
                        guard getter.receivedCount < safetyLimit else { getter.safetyLimitReached(); return }
                    }
                    getter.getNextPage()
                }
            }
        getter.getNextPage()
        return subject.eraseToAnyPublisher()
    }

    public func multipageGetter<M: Pageable>(with initialResource: RESTResource<M>) -> MultipageGetter<M> {
        return MultipageGetter(initialResource: initialResource, manager: self)
    }
}

extension RESTWebServiceManager {

    func buildRequest<M>(with resource: RESTResource<M>) throws -> URLRequest {

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
