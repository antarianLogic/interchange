//
//  RESTWebServiceManagerTests.swift
//  RESTWebServiceTests
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import XCTest
import Combine
import Mocker
@testable import RESTWebService

final class RESTWebServiceManagerTests: XCTestCase {

    override class func setUp() {
        Mock.registerAll()
    }

    var sut: RESTWebServiceManager!

    var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        sut = nil
    }

    func testInit() throws {
        sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        XCTAssertEqual(sut.baseURL.absoluteString, "https://example.com")
    }

    func testGetWithPathParams() throws {
        sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.subpath)
        let exp = expectation(description: "testGetWithPathParams")
        let resource = FooBarResources.getFoo(input: "123")
        var model: FooModel!
        let cancellable = sut.get(with: resource)
            .sink { completion in
                XCTAssertFalse(Thread.isMainThread, "on main thread")
                switch completion {
                case .finished:
                    exp.fulfill()
                case let .failure(error):
                    XCTFail("publisher returned failure with error: \(error)")
                }
            } receiveValue: { receivedModel in
                model = receivedModel
            }
        cancellables.insert(cancellable)
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error)
        }
        XCTAssertEqual(model, FooModel.Presets.foo)
    }

    func testGetWithQueryParams() throws {
        sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let exp = expectation(description: "testGetWithQueryParams")
        let resource = FooBarResources.getBar(inputs: ["234", "345"])
        var model: BarModel!
        let cancellable = sut.get(with: resource)
            .receive(on: RunLoop.main)
            .sink { completion in
                XCTAssertTrue(Thread.isMainThread, "not on main thread")
                switch completion {
                case .finished:
                    exp.fulfill()
                case let .failure(error):
                    XCTFail("publisher returned failure with error: \(error)")
                }
            } receiveValue: { receivedModel in
                model = receivedModel
            }
        cancellables.insert(cancellable)
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error)
        }
        XCTAssertEqual(model, BarModel.Presets.bar)
    }

    func testGetAllPages() throws {
        sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let exp = expectation(description: "testGetAllPages")
        let resource = FooBarResources.getFoos()
        var models: [FoosModel] = []
        let cancellable = sut.getAllPages(with: resource)
            .sink { completion in
                XCTAssertFalse(Thread.isMainThread, "on main thread")
                switch completion {
                case .finished:
                    exp.fulfill()
                case let .failure(error):
                    XCTFail("publisher returned failure with error: \(error)")
                }
            } receiveValue: { receivedModels in
                models = receivedModels
            }
        cancellables.insert(cancellable)
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error)
        }
        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models.first, FoosModel.Presets.foos1)
        XCTAssertEqual(models.last, FoosModel.Presets.foos2)
    }

    func testBuildRequestWithPathParams() throws {
        sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.subpath)
        let resource = FooBarResources.getFoo(input: "123")
        let request = try? sut.buildRequest(with: resource)
        XCTAssertEqual(request?.url?.absoluteString, "https://example.com/subpath/foo/123")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Accept": "application/json"])
    }

    func testBuildRequestWithQueryParams() throws {
        sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let resource = FooBarResources.getBar(inputs: ["234","345"])
        let request = try? sut.buildRequest(with: resource)
        XCTAssertEqual(request?.url?.absoluteString, "https://example.com/bar?inputs=234,345")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Accept": "application/json",
                                                      "User-Agent": "Foo/1.0.0 (bar@example.com)"])
    }

    /*

    func testGetMultipage() throws {
        try createSUT(baseURLString: "https://example.com")

        let exp = expectation(description: "testGetMultipage")
        let resource = FooBarResources.getFoos()
        var models: [FooModel]!
        let request = sut.getMultipage(with: resource) { result in
            XCTAssertTrue(Thread.isMainThread)
            models = try? result.get()
            exp.fulfill()
        }
        XCTAssertEqual(request?.url?.absoluteString, "https://example.com/foos?offset=0")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Accept": "application/json"])
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error)
        }
        XCTAssertEqual(models.count, 3)
        XCTAssertEqual(models.first?.name, "foo1")
        XCTAssertEqual(models.last?.name, "foo3")
    }

    func testGetRemainingPages() throws {
        try createSUT(baseURLString: "https://example.com")

        let exp = expectation(description: "testGetRemainingPages")
        let resource = FooBarResources.getFoos2()
        let existingSubmodels = [FooModel(name: "foo1"), FooModel(name: "foo2")]
        var models: [FooModel]!
        var request: URLRequest?
        request = sut.getRemainingPages(with: resource, at: 2, existingSubmodels: existingSubmodels) { result in
            XCTAssertFalse(Thread.isMainThread)
            models = try? result.get()
            DispatchQueue.main.async {
                exp.fulfill()
            }
        }
        XCTAssertEqual(request?.url?.absoluteString, "https://example.com/foos?offset=2")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Accept": "application/json"])
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error)
        }
        XCTAssertEqual(models.count, 3)
        XCTAssertEqual(models.first?.name, "foo1")
        XCTAssertEqual(models.last?.name, "foo3")
    }

     */

    func testHTTPError() throws {
        sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.invalid)
        let exp = expectation(description: "testHTTPError")
        let resource = FooBarResources.getFoo(input: "123")
        var error: RESTWebServiceError!
        let cancellable = sut.get(with: resource)
            .sink { completion in
                XCTAssertFalse(Thread.isMainThread, "on main thread")
                switch completion {
                case .finished:
                    XCTFail("publisher returned finished")
                case let .failure(completionError):
                    error = completionError
                }
                exp.fulfill()
            } receiveValue: { receivedModel in
                XCTFail("publisher returned value: \(receivedModel)")
            }
        cancellables.insert(cancellable)
        waitForExpectations(timeout: 1) { (expError) in
            XCTAssertNil(expError)
        }
        XCTAssertNotNil(error)
    }

    // TODO: figure out how to test cacheInterval and timeoutInterval

    static var allTests = [
        ("testInit", testInit),
        ("testGetWithPathParams", testGetWithPathParams),
        ("testGetWithQueryParams", testGetWithQueryParams),
        ("testGetAllPages", testGetAllPages),
        ("testBuildRequestWithPathParams", testBuildRequestWithPathParams),
        ("testBuildRequestWithQueryParams", testBuildRequestWithQueryParams),
//        ("testGetMultipage", testGetMultipage),
//        ("testGetRemainingPages", testGetRemainingPages),
        ("testHTTPError", testHTTPError)
    ]
}
