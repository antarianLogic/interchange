//
//  InterchangeError.swift
//  Interchange
//
//  Created by Carl Sheppard on 1/21/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

/// Errors that can occur during web service operations.
///
/// These errors provide detailed information about what went wrong during a web service request, including URL context, HTTP status codes, and decoding failures.
///
/// See <doc:Interchange#Error-Handling> in the main documentation and <doc:QuickStart#Error-Handling> in the Quick Start Guide for more information.
///
public enum InterchangeError: Error {

    /// The endpoint specification is invalid or incomplete.
    ///
    /// - Parameter urlString: The URL that could not be constructed from the endpoint.
    case invalidRESTEndpoint(String)
    
    /// The base URL provided to the manager is invalid.
    ///
    /// - Parameter urlString: The invalid base URL string.
    case invalidBaseURL(String)
    
    /// The URL components could not be combined to form a valid URL.
    ///
    /// - Parameter componentsDescription: Description of the URL components.
    case insufficientURLComponents(String)
    
    /// The request body string could not be converted to UTF-8 data.
    ///
    /// - Parameter bodyString: The body string that failed to convert.
    case bodyStringInvalid(String)
    
    /// The server returned an HTTP error status code (outside the 200-203 range).
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code (e.g., 404, 500).
    ///   - errorString: The raw response body (first 1024 bytes).
    ///   - urlString: The URL that returned the error.
    case httpError(Int, String, String)
    
    /// Failed to decode the JSON response into the expected model type.
    ///
    /// - Parameters:
    ///   - decodingError: The underlying `DecodingError`.
    ///   - urlString: The URL of the request.
    ///   - reason: Human-readable description of the failure.
    ///   - codingPath: The JSON key path where decoding failed, if available.
    case decodingError(DecodingError, String, String, String?)
}

extension InterchangeError: Equatable {

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
        case let (.decodingError(_, lhsURLString, lhsReason, lhsCodingPath), .decodingError(_, rhsURLString, rhsReason, rhsCodingPath)):
            return lhsURLString == rhsURLString &&
                   lhsReason == rhsReason &&
                   lhsCodingPath == rhsCodingPath
        default:
            return false
        }
    }
}

extension InterchangeError: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .invalidRESTEndpoint(let urlString):
            return "Invalid endpoint specification for URL: \(urlString)"
        case .invalidBaseURL(let urlString):
            return "Invalid base URL: \(urlString)"
        case .insufficientURLComponents(let componentsString):
            return "Insufficient URL components: \(componentsString)"
        case .bodyStringInvalid(let bodyString):
            return "Body string could not be converted to UTF-8 data: bodyString: \(bodyString)"
        case let .httpError(statusCode, errorString, urlString):
            return "Received HTTP error code: \(statusCode) for URL: \(urlString). Raw result JSON: \"\(errorString)\""
        case let .decodingError(error, urlString, reason, codingPath):
            if let codingPath {
                return "Decoding error for URL: \(urlString), reason: \(reason), coding-path: \(codingPath), error: \(String(reflecting: error))"
            } else {
                return "Decoding error for URL: \(urlString), reason: \(reason), error: \(String(reflecting: error))"
            }
        }
    }
}
