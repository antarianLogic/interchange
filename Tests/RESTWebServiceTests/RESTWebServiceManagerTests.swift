//
//  RESTWebServiceManagerTests.swift
//  RESTWebServiceTests
//
//  Created by antarianLogic on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import XCTest
@testable import RESTWebService

struct FooModel: Decodable {
    let name: String
}

struct BarModel: Decodable {
    let count: Int
}

enum FooBarResources {

    static func getFoo(input: String) -> RESTReadResource<FooModel> {
        return RESTReadResource(path: "/foo/\(input)",
                                queryParameters: [])
    }

    static func getBar(inputs: [String]) -> RESTReadResource<BarModel> {
        let inputsString = inputs.joined(separator: ",")
        return RESTReadResource(path: "/bar",
                                headers: ["User-Agent": "Foo/1.0.0 (bar@example.com)"],
                                queryParameters: [URLQueryItem(name: "inputs", value: inputsString)])
    }
}

final class RESTWebServiceManagerTests: XCTestCase {

    override class func setUp() {
        guard let fooURL = URL(string: "https://example.com/baz/foo/123"),
              let barURL = URL(string: "https://example.com/bar?inputs=234,345") else { fatalError("Invalid URL!") }

        URLProtocolStub.testURLs = [fooURL: Data("{ \"name\": \"foo\" }".utf8),
                                    barURL: Data("{ \"count\": 2 }".utf8)]
    }

    var sut: RESTWebServiceManager!

    func createSUT(baseURLString: String) throws {
        guard let baseURL = URL(string: baseURLString) else { throw URLError(.badURL) }

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        sut = RESTWebServiceManager(baseURL: baseURL, session: session)
    }

    override func tearDown() {
        sut = nil
    }

    func testInit() throws {
        try createSUT(baseURLString: "https://example.com")

        XCTAssertEqual(sut.baseURL.absoluteString, "https://example.com")
    }

    func testGetWithPathParams() throws {
        try createSUT(baseURLString: "https://example.com/baz")

        let exp = expectation(description: "testGetWithPathParams")
        let resource = FooBarResources.getFoo(input: "123")
        var model: FooModel?
        let request = sut.get(resource: resource) { result in
            model = try? result.get()
            exp.fulfill()
        }
        XCTAssertEqual(request?.url?.absoluteString, "https://example.com/baz/foo/123")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Accept": "application/json"])
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error)
        }
        XCTAssertEqual(model?.name, "foo")
    }

    func testGetWithQueryParams() throws {
        try createSUT(baseURLString: "https://example.com")

        let exp = expectation(description: "testGetWithQueryParams")
        let resource = FooBarResources.getBar(inputs: ["234","345"])
        var model: BarModel?
        let request = sut.get(resource: resource) { result in
            model = try? result.get()
            exp.fulfill()
        }
        XCTAssertEqual(request?.url?.absoluteString, "https://example.com/bar?inputs=234,345")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Accept": "application/json",
                                                      "User-Agent": "Foo/1.0.0 (bar@example.com)"])
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error)
        }
        XCTAssertEqual(model?.count, 2)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testGetWithPathParams", testGetWithPathParams),
        ("testGetWithQueryParams", testGetWithQueryParams)
    ]
}
