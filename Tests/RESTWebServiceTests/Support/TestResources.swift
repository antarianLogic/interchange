//
//  TestResources.swift
//  RESTWebServiceTests
//
//  Created by Carl Sheppard on 2/12/21.
//  Copyright © 2022 Antarian Logic LLC. All rights reserved.
//

import Foundation
@testable import RESTWebService

enum FooBarResources {

    static func getFoo(input: String) -> RESTResource {
        return RESTResource(path: "/foo/\(input)",
                            queryParameters: [])
    }

    static func getFoo2(input: String) -> RESTResource {
        return RESTResource(path: "/foo2/\(input)",
                            queryParameters: [],
                            enableRateLimiting: true)
    }

    static func getFooXML(input: String) -> RESTResource {
        return RESTResource(path: "/foo/\(input)",
                            headers: ["Accept": "application/xml"],
                            queryParameters: [])
    }

    static func getBar(inputs: [String]) -> RESTResource {
        let inputsString = inputs.joined(separator: ",")
        return RESTResource(path: "/bar",
                            headers: ["User-Agent": "Foo/1.0.0 (bar@example.com)"],
                            queryParameters: [URLQueryItem(name: "inputs", value: inputsString)])
    }

    static func getFoos() -> RESTResource {
        return RESTResource(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "2"),
                            offsetQueryItem: URLQueryItem(name: "offset", value: "0"))
    }

    static func getFoos2() -> RESTResource {
        return RESTResource(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "2"),
                            offsetQueryItem: URLQueryItem(name: "offset", value: "2"))
    }

    static func getFoos3() -> RESTResource {
        return RESTResource(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "3"),
                            offsetQueryItem: URLQueryItem(name: "offset", value: "0"))
    }

    static func getFoos4() -> RESTResource {
        return RESTResource(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "2"),
                            pageQueryItem: URLQueryItem(name: "page", value: "1"))
    }

    static func getFoos5() -> RESTResource {
        return RESTResource(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "2"),
                            pageQueryItem: URLQueryItem(name: "page", value: "2"))
    }

    static func getFoos6() -> RESTResource {
        return RESTResource(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "3"),
                            pageQueryItem: URLQueryItem(name: "page", value: "1"))
    }

    static func putFoo() -> RESTResource {
        return RESTResource(method: .put,
                            path: "/foo",
                            bodyParameters: [URLQueryItem(name: "body1", value: "body1 value")])
    }
}
