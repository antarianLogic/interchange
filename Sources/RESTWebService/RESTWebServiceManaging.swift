//
//  RESTWebServiceManaging.swift
//  RESTWebService
//
//  Created by antarianLogic on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

public protocol RESTWebServiceManaging {

    init(baseURL: URL, session: URLSession)

    func get<Model: Decodable>(resource: RESTReadResource<Model>,
                               completionHandler: @escaping (Result<Model, RESTWebServiceError>) -> Void)
}

public enum RESTWebServiceError: Error {

    case invalidBaseURL(String)
    case insufficientURLComponents(String)
    case urlSessionDataTaskError(Error)
    case jsonDecodingError(Error)

    public var presentableDescription: String {
        switch self {
        case .invalidBaseURL(let urlString):
            return "Invalid base URL: \(urlString)"
        case .insufficientURLComponents(let componentsString):
            return "Insufficient URL components: \(componentsString)"
        case .urlSessionDataTaskError(let error):
            return error.localizedDescription
        case .jsonDecodingError(let error):
            return error.localizedDescription
        }
    }

}
