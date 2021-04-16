//
//  RESTWebServiceError.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/21/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

public enum RESTWebServiceError: Error {

    case invalidBaseURL(String)
    case insufficientURLComponents(String)
    case urlSessionDataTaskError(Error)
    case httpError(Int, String)
    case jsonDecodingError(Error)
    case safetyLimitReached
    case downstreamError(String)
    case unknown(Error)
}

extension RESTWebServiceError: CustomDebugStringConvertible {

    public static func errorMapper(error: Error) -> Self {
        switch error {
        case let restWebServiceError as Self:
            return restWebServiceError
        case let decodingError as DecodingError:
            return .jsonDecodingError(decodingError)
        case let urlError as URLError:
            return .urlSessionDataTaskError(urlError)
        default:
            return .unknown(error)
        }
    }

    public var debugDescription: String {
        switch self {
        case .invalidBaseURL(let urlString):
            return "Invalid base URL: \(urlString)"
        case .insufficientURLComponents(let componentsString):
            return "Insufficient URL components: \(componentsString)"
        case .urlSessionDataTaskError(let error):
            return "URLSession dataTask error: \(error)"
        case .httpError(let statusCode, let errorString):
            return "Recieved HTTP error code: \(statusCode). Raw result JSON: \"\(errorString)\""
        case .jsonDecodingError(let error):
            return "JSON decoding error: \(error)"
        case .safetyLimitReached:
            return "Safety limit reached"
        case .downstreamError(let string):
            return "Downstream error: \(string)"
        case .unknown(let error):
            return "Unknown error: \(error)"
        }
    }
}
