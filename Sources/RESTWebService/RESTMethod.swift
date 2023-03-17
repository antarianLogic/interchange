//
//  RESTMethod.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 2/10/22.
//  Copyright © 2022 Antarian Logic LLC. All rights reserved.
//

/// HTTP method (or verb).
public enum RESTMethod: String {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case connect = "CONNECT"
    case options = "OPTIONS"
    case trace = "TRACE"
    case patch = "PATCH"
}
