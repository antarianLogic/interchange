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

    public func get<Model: Decodable>(resource: RESTResource<Model>,
                                      completionHandler: @escaping (Result<Model, RESTWebServiceError>) -> Void) -> URLRequest? {
        let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        guard var validComponents = components else {
            let error = RESTWebServiceError.invalidBaseURL(baseURL.absoluteString)
            DispatchQueue.main.async {
                completionHandler(.failure(error))
            }
            return nil
        }

        validComponents.path = validComponents.path.appending(resource.path)
        if !resource.queryParameters.isEmpty {
            validComponents.queryItems = resource.queryParameters
        }
        guard let url = validComponents.url else {
            let error = RESTWebServiceError.insufficientURLComponents(validComponents.description)
            DispatchQueue.main.async {
                completionHandler(.failure(error))
            }
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for header in resource.headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let validError = error {
                let dataTaskError = RESTWebServiceError.urlSessionDataTaskError(validError)
                DispatchQueue.main.async {
                    completionHandler(.failure(dataTaskError))
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
                    completionHandler(.failure(httpError))
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

        return request
    }
}
