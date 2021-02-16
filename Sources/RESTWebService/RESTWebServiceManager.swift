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

        return Just<RESTResource<M>>(resource)
            .receive(on: DispatchQueue.global(qos: .utility))
            .setFailureType(to: RESTWebServiceError.self)
            .tryMap(buildRequest)
            .mapError(RESTWebServiceError.errorMapper)
            .flatMap(maxPublishers: .unlimited, buildModelPublisher)
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

//    public func getMultipage<M: Pageable>(with resource: RESTResource<M>) -> AnyPublisher<[M.Submodel], RESTWebServiceError> where M.Submodel: Decodable {
//        return Publishers.Sequence<[RESTResource<M>],Never>(sequence: [resource])
//            .receive(on: DispatchQueue.global(qos: .utility))
//            .setFailureType(to: RESTWebServiceError.self)
//            .tryMap(buildRequest)
//            .mapError(RESTWebServiceError.errorMapper)
//            .flatMap(maxPublishers: .unlimited, buildModelPublisher)
//            .eraseToAnyPublisher()
//    }

    public func multipageGetter<M: Pageable>(with initialResource: RESTResource<M>) -> MultipageGetter<M> {
        return MultipageGetter(initialResource: initialResource, manager: self)
    }

    /*

    @discardableResult
    public func getMultipage<M: Pageable>(with resource: RESTResource<M>,
                                          successOnMainQueue: Bool = true,
                                          onCompletion: @escaping (Result<[M.Submodel], RESTWebServiceError>) -> Void) -> URLRequest? {
        let initialSubmodels: [M.Submodel] = []
        let request = getRemainingPages(with: resource, at: 0, existingSubmodels: initialSubmodels) { result in
            switch result {
            case let .success(resultSubmodels):
                if successOnMainQueue {
                    DispatchQueue.main.async {
                        onCompletion(.success(resultSubmodels))
                    }
                } else {
                    onCompletion(.success(resultSubmodels))
                }
            case let .failure(error):
                onCompletion(.failure(error))
            }
        }
        return request
    }

     */
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
            let errorString = String(data: data, encoding: .utf8) ?? ""
            throw RESTWebServiceError.httpError(httpResponse.statusCode, errorString)
        }

        return isIncluded
    }

    /*

    func utilityGet<M>(with resource: RESTResource<M>,
                       subject: PassthroughSubject<M, RESTWebServiceError>) {

        let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        guard var validComponents = components else {
            subject.send(completion: .failure(.invalidBaseURL(baseURL.absoluteString)))
        }

        validComponents.path = validComponents.path.appending(resource.path)

        var queryItems = resource.queryParameters
        if let offsetQueryItem = resource.offsetQueryItem {
            queryItems.append(offsetQueryItem)
        }
        if !queryItems.isEmpty {
            validComponents.queryItems = queryItems
        }

        guard let url = validComponents.url else {
            subject.send(completion: .failure(.insufficientURLComponents(validComponents.description)))
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

        session.dataTaskPublisher(for: request)
            .mapError { RESTWebServiceError.urlSessionDataTaskError($0) }
            .tryFilter {
                guard let httpResponse = $0.response as? HTTPURLResponse else { return false }
                let isIncluded = httpResponse.statusCode >= 200 && httpResponse.statusCode < 204
                guard isIncluded else {
                    let errorString = String(data: $0.data, encoding: .utf8) ?? ""
                    throw RESTWebServiceError.httpError(httpResponse.statusCode, errorString)
                }
                return isIncluded
            }
            .map(\.data)
            .decode(type: M.self, decoder: JSONDecoder())
            .mapError { RESTWebServiceError.jsonDecodingError($0) }

//        subject.fla
//            .catch { error -> Empty<M, Never> in
//                promise(.failure(error))
//                return Empty<M, Never>(completeImmediately: true)
//            }
//            .sink { promise(.success($0)) }
    }

    func utilityGet<M>(with resource: RESTResource<M>,
                       promise: @escaping Future<M, RESTWebServiceError>.Promise) {

        let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        guard var validComponents = components else {
            promise(.failure(.invalidBaseURL(baseURL.absoluteString)))
        }

        validComponents.path = validComponents.path.appending(resource.path)

        var queryItems = resource.queryParameters
        if let offsetQueryItem = resource.offsetQueryItem {
            queryItems.append(offsetQueryItem)
        }
        if !queryItems.isEmpty {
            validComponents.queryItems = queryItems
        }

        guard let url = validComponents.url else {
            promise(.failure(.insufficientURLComponents(validComponents.description)))
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

        session.dataTaskPublisher(for: request)
            .mapError { RESTWebServiceError.urlSessionDataTaskError($0) }
            .tryFilter {
                guard let httpResponse = $0.response as? HTTPURLResponse else { return false }
                let isIncluded = httpResponse.statusCode >= 200 && httpResponse.statusCode < 204
                guard isIncluded else {
                    let errorString = String(data: $0.data, encoding: .utf8) ?? ""
                    throw RESTWebServiceError.httpError(httpResponse.statusCode, errorString)
                }
                return isIncluded
            }
            .map(\.data)
            .decode(type: M.self, decoder: JSONDecoder())
            .mapError { RESTWebServiceError.jsonDecodingError($0) }
            .catch { error -> Empty<M, Never> in
                promise(.failure(error))
                return Empty<M, Never>(completeImmediately: true)
            }
            .sink { promise(.success($0)) }
    }

    func failPublisher<M>(with error: RESTWebServiceError) -> AnyPublisher<M, RESTWebServiceError> {
        let fail = Fail<M, RESTWebServiceError>(error: error)
        return fail.eraseToAnyPublisher()
    }

    @discardableResult
    func getRemainingPages<M: Pageable>(with resource: RESTResource<M>,
                                        at offset: UInt,
                                        existingSubmodels: [M.Submodel],
                                        onCompletion: @escaping (Result<[M.Submodel], RESTWebServiceError>) -> Void) -> URLRequest? {
        let request = get(with: resource, successOnMainQueue: false) { [weak self] result in
            switch result {
            case let .success(resultModel):
                let submodels = resultModel.submodels
                let appendedSubmodels = existingSubmodels + submodels
                let resultCount = UInt(appendedSubmodels.count)
                if resultCount < resultModel.totalCount {
                    // we don't have them all yet, need to recursivly make another request
                    // TODO: need to handle missing offset in resource, exiting with fatalError for now
                    guard let offsetQueryItem = resource.offsetQueryItem else { fatalError() }

                    // create a new resource identical to the original except with a new offset
                    let newOffsetQueryItem = URLQueryItem(name: offsetQueryItem.name, value: String(resultCount))
                    let newNesource = RESTResource<M>(path: resource.path,
                                                      headers: resource.headers,
                                                      queryParameters: resource.queryParameters,
                                                      model: resource.model,
                                                      offsetQueryItem: newOffsetQueryItem,
                                                      cacheInterval: resource.cacheInterval,
                                                      timeoutInterval: resource.timeoutInterval)
                    self?.getRemainingPages(with: newNesource,
                                            at: resultCount,
                                            existingSubmodels: appendedSubmodels,
                                            onCompletion: onCompletion)
                } else {
                    // we are done with the recursion!
                    onCompletion(.success(appendedSubmodels))
                }
            case let .failure(error):
                onCompletion(.failure(error))
            }
        }
        return request
    }

     */

}
