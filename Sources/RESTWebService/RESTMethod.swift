//
//  RESTMethod.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 2/10/22.
//  Copyright © 2022 Antarian Logic LLC. All rights reserved.
//

/// HTTP request method (also known as HTTP verb).
///
public enum RESTMethod: String, Sendable {
    /// Retrieve data from the server without modifying it.
    case get = "GET"

    /// Retrieve response headers without the body (useful for checking existence).
    case head = "HEAD"

    /// Submit data to create a new resource or trigger an action.
    case post = "POST"

    /// Replace an existing resource with new data.
    case put = "PUT"

    /// Remove a resource from the server.
    case delete = "DELETE"

    /// Establish a network connection (rarely used in REST APIs).
    case connect = "CONNECT"

    /// Request information about available communication options.
    case options = "OPTIONS"

    /// Perform a message loop-back test (rarely used in REST APIs).
    case trace = "TRACE"

    /// Partially update an existing resource.
    case patch = "PATCH"
}
