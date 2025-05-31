//
//  RESTWebServiceError.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 1/21/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

public enum RESTWebServiceError: Error {

    case invalidRESTEndpoint(String)
    case invalidBaseURL(String)
    case insufficientURLComponents(String)
    case bodyStringInvalid(String)
    case httpError(Int, String, String)
    case safetyLimitReached(String)
    case decodingError(DecodingError, String, String, String?)
}

extension RESTWebServiceError: Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.invalidRESTEndpoint(lhsURLString), .invalidRESTEndpoint(rhsURLString)):
            return lhsURLString == rhsURLString
        case let (.invalidBaseURL(lhsURLString), .invalidBaseURL(rhsURLString)):
            return lhsURLString == rhsURLString
        case let (.insufficientURLComponents(lhsComponentsString), .insufficientURLComponents(rhsComponentsString)):
            return lhsComponentsString == rhsComponentsString
        case let (.bodyStringInvalid(lhsBodyString), .bodyStringInvalid(rhsBodyString)):
            return lhsBodyString == rhsBodyString
        case let (.httpError(lhsStatusCode, lhsErrorString, lhsURLString), .httpError(rhsStatusCode, rhsErrorString, rhsURLString)):
            return lhsStatusCode == rhsStatusCode &&
                   lhsErrorString == rhsErrorString &&
                   lhsURLString == rhsURLString
        case let (.safetyLimitReached(lhsURLString), .safetyLimitReached(rhsURLString)):
            return lhsURLString == rhsURLString
        case let (.decodingError(_, lhsURLString, lhsReason, lhsCodingPath), .decodingError(_, rhsURLString, rhsReason, rhsCodingPath)):
            return lhsURLString == rhsURLString &&
                   lhsReason == rhsReason &&
                   lhsCodingPath == rhsCodingPath
        default:
            return false
        }
    }
}

extension RESTWebServiceError: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .invalidRESTEndpoint(let urlString):
            return "Invalid REST endpoint specification for URL: \(urlString)"
        case .invalidBaseURL(let urlString):
            return "Invalid base URL: \(urlString)"
        case .insufficientURLComponents(let componentsString):
            return "Insufficient URL components: \(componentsString)"
        case .bodyStringInvalid(let bodyString):
            return "Body string could not be converted to UTF-8 data: bodyString: \(bodyString)"
        case let .httpError(statusCode, errorString, urlString):
            return "Received HTTP error code: \(statusCode) for URL: \(urlString). Raw result JSON: \"\(errorString)\""
        case .safetyLimitReached(let urlString):
            return "Safety limit reached for URL: \(urlString)"
        case let .decodingError(error, urlString, reason, codingPath):
            if let codingPath {
                return "Decoding error for URL: \(urlString), reason: \(reason), coding-path: \(codingPath), error: \(String(reflecting: error))"
            } else {
                return "Decoding error for URL: \(urlString), reason: \(reason), error: \(String(reflecting: error))"
            }
        }
    }
}
