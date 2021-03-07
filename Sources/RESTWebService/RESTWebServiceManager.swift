//
//  RESTWebServiceManager.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation
import Combine

public final class RESTWebServiceManager : RESTWebServiceManaging {

    let baseURL: URL
    let session: URLSession

    private var cancellable: AnyCancellable?

    public required init(baseURL: URL,
                         session: URLSession = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func get<M>(with resource: RESTResource<M>) -> AnyPublisher<M, RESTWebServiceError> {

        // NOTE: It may seem weird to do an Empty first then prepending the resource instead of just starting with a
        // Just(resource), but doing the later caused random test failures due to the Just sometimes prematurely
        // finishing before the flatMap publisher could kick in on the utility queue.
        return Empty(completeImmediately: false)
            .receive(on: DispatchQueue.global(qos: .utility))
            .prepend(resource)
            .setFailureType(to: RESTWebServiceError.self)
            .tryMap(buildRequest)
            .mapError(RESTWebServiceError.errorMapper)
            .flatMap(maxPublishers: .max(1), buildModelPublisher)
            .first()
            .eraseToAnyPublisher()
    }

    public func getAllPages<M: Pageable>(with resource: RESTResource<M>) -> AnyPublisher<[M], RESTWebServiceError> {
        let subject = PassthroughSubject<[M], RESTWebServiceError>()
        let getter = multipageGetter(with: resource)
        var models: [M] = []
        cancellable = getter.publisher
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    subject.send(models)
                default: break
                }
                subject.send(completion: completion)
                self?.cancellable = nil
            } receiveValue: { receivedModel in
                models.append(receivedModel)
                if !getter.receivedAllPages {
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

    func buildModelPublisher<M: Decodable>(with request: URLRequest) -> AnyPublisher<M, RESTWebServiceError> {
        return session.dataTaskPublisher(for: request)
            .tryFilter(filterOutput)
            .map(\.data)
            .decode(type: M.self, decoder: JSONDecoder())
            .mapError(RESTWebServiceError.errorMapper)
            .eraseToAnyPublisher()
    }

    func filterOutput(data: Data, response: URLResponse) throws -> Bool {
        guard let httpResponse = response as? HTTPURLResponse else { return false }

        let isIncluded = httpResponse.statusCode >= 200 && httpResponse.statusCode < 204
        guard isIncluded else {
            let errorString = String(data: data.prefix(128), encoding: .utf8) ?? ""
            throw RESTWebServiceError.httpError(httpResponse.statusCode, errorString)
        }

        return isIncluded
    }
}
