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

    var cancellables: Set<AnyCancellable> = []

    func testInit() throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        XCTAssertEqual(sut.baseURL.absoluteString, "https://example.com")
    }

    func testGetWithPathParams() throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.subpath)
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
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(model, FooModel.Presets.foo)
    }

    func testGetWithQueryParams() throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
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
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(model, BarModel.Presets.bar)
    }

    func testHTTPError() throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.invalid)
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
        wait(for: [exp], timeout: 1)
        XCTAssertNotNil(error)
    }

    // TODO: figure out how to test cacheInterval and timeoutInterval

    func testGetAllPages() throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
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
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models.first, FoosModel.Presets.foos1)
        XCTAssertEqual(models.last, FoosModel.Presets.foos2)
    }

    func testGetAllPagesWithSafetyLimit() throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let exp = expectation(description: "testGetAllPagesWithSafetyLimit")
        let resource = FooBarResources.getFoos()
        var models: [FoosModel] = []
        var error: RESTWebServiceError!
        let cancellable = sut.getAllPages(with: resource, safetyLimit: 1)
            .sink { completion in
                XCTAssertFalse(Thread.isMainThread, "on main thread")
                switch completion {
                case .finished:
                    XCTFail("publisher returned finished")
                case let .failure(completionError):
                    error = completionError
                }
                exp.fulfill()
            } receiveValue: { receivedModels in
                models = receivedModels
            }
        cancellables.insert(cancellable)
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(models.count, 1)
        XCTAssertEqual(models.first, FoosModel.Presets.foos1)
        XCTAssertNotNil(error)
    }

    func testBuildRequestWithPathParams() throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.subpath)
        let resource = FooBarResources.getFoo(input: "123")
        let request = try? sut.buildRequest(with: resource)
        XCTAssertEqual(request?.url?.absoluteString, "https://example.com/subpath/foo/123")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Accept": "application/json"])
    }

    func testBuildRequestWithQueryParams() throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let resource = FooBarResources.getBar(inputs: ["234","345"])
        let request = try? sut.buildRequest(with: resource)
        XCTAssertEqual(request?.url?.absoluteString, "https://example.com/bar?inputs=234,345")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Accept": "application/json",
                                                      "User-Agent": "Foo/1.0.0 (bar@example.com)"])
    }

    func testMultipageGetter() throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let resource = FooBarResources.getFoos()
        let getter = sut.multipageGetter(with: resource)
        XCTAssertNotNil(getter)
        // testing of returned MultipageGetter is covered by MultipageGetterTests
    }

    static var allTests = [
        ("testInit", testInit),
        ("testGetWithPathParams", testGetWithPathParams),
        ("testGetWithQueryParams", testGetWithQueryParams),
        ("testHTTPError", testHTTPError),
        ("testGetAllPages", testGetAllPages),
        ("testGetAllPagesWithSafetyLimit", testGetAllPagesWithSafetyLimit),
        ("testBuildRequestWithPathParams", testBuildRequestWithPathParams),
        ("testBuildRequestWithQueryParams", testBuildRequestWithQueryParams),
        ("testMultipageGetter", testMultipageGetter)
    ]
}
