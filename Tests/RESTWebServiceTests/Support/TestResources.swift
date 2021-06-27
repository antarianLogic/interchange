//
//  TestResources.swift
//  RESTWebServiceTests
//
//  Created by Carl Sheppard on 2/12/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation
@testable import RESTWebService

enum FooBarResources {

    static func getFoo(input: String) -> RESTResource<FooModel> {
        return RESTResource(path: "/foo/\(input)",
                            queryParameters: [])
    }

    static func getFooXML(input: String) -> RESTResource<FooModel> {
        return RESTResource(path: "/foo/\(input)",
                            headers: ["Accept": "application/xml"],
                            queryParameters: [])
    }

    static func getBar(inputs: [String]) -> RESTResource<BarModel> {
        let inputsString = inputs.joined(separator: ",")
        return RESTResource(path: "/bar",
                            headers: ["User-Agent": "Foo/1.0.0 (bar@example.com)"],
                            queryParameters: [URLQueryItem(name: "inputs", value: inputsString)])
    }

    static func getFoos() -> RESTResource<FoosModel> {
        return RESTResource(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "2"),
                            offsetQueryItem: URLQueryItem(name: "offset", value: "0"))
    }

    static func getFoos2() -> RESTResource<FoosModel> {
        return RESTResource(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "2"),
                            offsetQueryItem: URLQueryItem(name: "offset", value: "2"))
    }

    static func getFoos3() -> RESTResource<FoosModel> {
        return RESTResource(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "3"),
                            offsetQueryItem: URLQueryItem(name: "offset", value: "0"))
    }

    static func getFoos4() -> RESTResource<FoosModel> {
        return RESTResource(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "2"),
                            pageQueryItem: URLQueryItem(name: "page", value: "1"))
    }

    static func getFoos5() -> RESTResource<FoosModel> {
        return RESTResource(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "2"),
                            pageQueryItem: URLQueryItem(name: "page", value: "2"))
    }

    static func getFoos6() -> RESTResource<FoosModel> {
        return RESTResource(path: "/foos",
                            pageSizeQueryItem: URLQueryItem(name: "pageSize", value: "3"),
                            pageQueryItem: URLQueryItem(name: "page", value: "1"))
    }
}
