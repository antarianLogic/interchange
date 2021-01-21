//
//  File.swift
//  
//
//  Created by Antares on 1/21/21.
//

import Foundation

public enum RESTWebServiceError: Error {

    case invalidBaseURL(String)
    case insufficientURLComponents(String)
    case urlSessionDataTaskError(Error)
    case httpError(Int, String)
    case jsonDecodingError(Error)
}

extension RESTWebServiceError: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .invalidBaseURL(let urlString):
            return "Invalid base URL: \(urlString)"
        case .insufficientURLComponents(let componentsString):
            return "Insufficient URL components: \(componentsString)"
        case .urlSessionDataTaskError(let error):
            return error.localizedDescription
        case .httpError(let statusCode, let errorString):
            return "Recieved HTTP error code: \(statusCode). Raw result JSON: \"\(errorString)\""
        case .jsonDecodingError(let error):
            return error.localizedDescription
        }
    }
}
