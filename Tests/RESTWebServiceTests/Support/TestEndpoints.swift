//
//  TestEndpoints.swift
//  RESTWebServiceTests
//
//  Created by Carl Sheppard on 2/12/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation
@testable import RESTWebService

enum FooBarEndpoints {

    static func getFoo(input: String) -> RESTEndpoint {
        return RESTEndpoint(path: "/foo/\(input)",
                            queryParameters: [])
    }

    static func getFoo2(input: String) -> RESTEndpoint {
        return RESTEndpoint(path: "/foo2/\(input)",
                            queryParameters: [])
    }

    static func getFooXML(input: String) -> RESTEndpoint {
        return RESTEndpoint(path: "/foo/\(input)",
                            headers: ["Accept": "application/xml"],
                            queryParameters: [])
    }

    static func getBar(inputs: [String]) -> RESTEndpoint {
        let inputsString = inputs.joined(separator: ",")
        return RESTEndpoint(path: "/bar",
                            headers: ["User-Agent": "Foo/1.0.0 (bar@example.com)"],
                            queryParameters: [URLQueryItem(name: "inputs", value: inputsString)])
    }

    static func getFoos() -> RESTEndpoint {
        return RESTEndpoint(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "2"),
                            offsetQueryItem: URLQueryItem(name: "offset", value: "0"))
    }

    static func getFoos2() -> RESTEndpoint {
        return RESTEndpoint(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "2"),
                            offsetQueryItem: URLQueryItem(name: "offset", value: "2"))
    }

    static func getFoos3() -> RESTEndpoint {
        return RESTEndpoint(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "3"),
                            offsetQueryItem: URLQueryItem(name: "offset", value: "0"))
    }

    static func getFoos4() -> RESTEndpoint {
        return RESTEndpoint(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "2"),
                            pageQueryItem: URLQueryItem(name: "page", value: "1"))
    }

    static func getFoos5() -> RESTEndpoint {
        return RESTEndpoint(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "2"),
                            pageQueryItem: URLQueryItem(name: "page", value: "2"))
    }

    static func getFoos6() -> RESTEndpoint {
        return RESTEndpoint(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "3"),
                            pageQueryItem: URLQueryItem(name: "page", value: "1"))
    }

    static func putFoo() -> RESTEndpoint {
        return RESTEndpoint(method: .put,
                            path: "/foo",
                            headers: ["Content-Type": "application/json; charset=utf-8"],
                            body: "{\"body1\": \"body1 value\"}")
    }
}
