//
//  RESTWebServiceManager.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

public class RESTWebServiceManager : RESTWebServiceManaging {

    let baseURL: URL
    let session: URLSession

    public required init(baseURL: URL,
                         session: URLSession = URLSession(configuration: .default)) {
        self.baseURL = baseURL
        self.session = session
    }

    @discardableResult
    public func get<M>(with resource: RESTResource<M>,
                       successOnMainQueue: Bool = true,
                       onCompletion: @escaping (Result<M, RESTWebServiceError>) -> Void) -> URLRequest? {
        let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        guard var validComponents = components else {
            let error = RESTWebServiceError.invalidBaseURL(baseURL.absoluteString)
            DispatchQueue.main.async {
                onCompletion(.failure(error))
            }
            return nil
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
            let error = RESTWebServiceError.insufficientURLComponents(validComponents.description)
            DispatchQueue.main.async {
                onCompletion(.failure(error))
            }
            return nil
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

        let task = session.dataTask(with: request) { data, response, error in
            if let validError = error {
                let dataTaskError = RESTWebServiceError.urlSessionDataTaskError(validError)
                DispatchQueue.main.async {
                    onCompletion(.failure(dataTaskError))
                }
            }
            else if let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode < 200 || httpResponse.statusCode > 203 {
                var errorString = ""
                if let validErrorData = data {
                    errorString = String(data: validErrorData, encoding: .utf8) ?? ""
                }
                let httpError = RESTWebServiceError.httpError(httpResponse.statusCode, errorString)
                DispatchQueue.main.async {
                    onCompletion(.failure(httpError))
                }
            }
            else if let validData = data {
                do {
                    let model:M = try JSONDecoder().decode(M.self, from: validData)
                    if successOnMainQueue {
                        DispatchQueue.main.async {
                            onCompletion(.success(model))
                        }
                    } else {
                        onCompletion(.success(model))
                    }
                } catch {
                    let decodingError = RESTWebServiceError.jsonDecodingError(error)
                    DispatchQueue.main.async {
                        onCompletion(.failure(decodingError))
                    }
                }
            }
        }
        task.resume()

        return request
    }

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
}

extension RESTWebServiceManager {

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
}
