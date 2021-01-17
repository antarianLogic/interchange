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
                                queryParameters: [URLQueryItem(name: "inputs", value: inputsString)])
    }
}

final class RESTWebServiceManagerTests: XCTestCase {

    var sut: RESTWebServiceManager!

    override func setUpWithError() throws {
        guard let baseURL = URL(string: "https://example.com"),
              let fooURL = URL(string: "https://example.com/foo/123"),
              let barURL = URL(string: "https://example.com/bar?inputs=234,345") else { fatalError("Invalid URL!") }

        URLProtocolStub.testURLs = [fooURL: Data("{ \"name\": \"foo\" }".utf8),
                                    barURL: Data("{ \"count\": 2 }".utf8)]
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)

        sut = RESTWebServiceManager(baseURL: baseURL, session: session)
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testInit() throws {
        XCTAssertEqual(sut.baseURL.absoluteString, "https://example.com")
    }

    func testGetFoo() throws {
        let exp = expectation(description: "testGetFoo")
        let resource = FooBarResources.getFoo(input: "123")
        var model: FooModel?
        sut.get(route: resource) { result in
            model = try? result.get()
            exp.fulfill()
        }
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error)
        }
        XCTAssertEqual(model?.name, "foo")
    }

    func testGetBar() throws {
        let exp = expectation(description: "testGetBar")
        let resource = FooBarResources.getBar(inputs: ["234","345"])
        var model: BarModel?
        sut.get(route: resource) { result in
            model = try? result.get()
            exp.fulfill()
        }
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error)
        }
        XCTAssertEqual(model?.count, 2)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testGetFoo", testGetFoo),
        ("testGetBar", testGetBar)
    ]
}
