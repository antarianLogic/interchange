//
//  RESTWebServiceError.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/21/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

public enum RESTWebServiceError: Error {

    case invalidRESTResource
    case invalidBaseURL(String)
    case insufficientURLComponents(String)
    case httpError(Int, String)
    case safetyLimitReached
}

extension RESTWebServiceError: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .invalidRESTResource:
            return "Invalid REST resource"
        case .invalidBaseURL(let urlString):
            return "Invalid base URL: \(urlString)"
        case .insufficientURLComponents(let componentsString):
            return "Insufficient URL components: \(componentsString)"
        case .httpError(let statusCode, let errorString):
            return "Received HTTP error code: \(statusCode). Raw result JSON: \"\(errorString)\""
        case .safetyLimitReached:
            return "Safety limit reached"
        }
    }
}
