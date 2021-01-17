//
//  RESTWebServiceManager.swift
//  RESTWebService
//
//  Created by antarianLogic on 1/15/21.
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

    public func get<Model: Decodable>(resource: RESTReadResource<Model>,
                                      completionHandler: @escaping (Result<Model, RESTWebServiceError>) -> Void) {
        let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        guard var validComponents = components else {
            let error = RESTWebServiceError.invalidBaseURL(baseURL.absoluteString)
            completionHandler(.failure(error))
            return
        }

        validComponents.path = resource.path
        if !resource.queryParameters.isEmpty {
            validComponents.queryItems = resource.queryParameters
        }
        guard let url = validComponents.url else {
            let error = RESTWebServiceError.insufficientURLComponents(validComponents.description)
            completionHandler(.failure(error))
            return
        }

        let task = session.dataTask(with: url) { (data, response, error) in
            if let validError = error {
                let dataTaskError = RESTWebServiceError.urlSessionDataTaskError(validError)
                DispatchQueue.main.async {
                    completionHandler(.failure(dataTaskError))
                }
            }
            else if let validData = data {
                do {
                    let model:Model = try JSONDecoder().decode(Model.self, from: validData)
                    DispatchQueue.main.async {
                        completionHandler(.success(model))
                    }
                } catch {
                    let decodingError = RESTWebServiceError.jsonDecodingError(error)
                    DispatchQueue.main.async {
                        completionHandler(.failure(decodingError))
                    }
                }
            }
        }
        task.resume()
    }
}
