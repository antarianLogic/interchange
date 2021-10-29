//
//  RESTWebServiceManagerTests.swift
//  RESTWebServiceTests
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import XCTest
import Mocker
@testable import RESTWebService

final class RESTWebServiceManagerTests: XCTestCase {

    override class func setUp() {
        Mock.registerAll()
    }

    func testGetWithPathParams() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.subpath)
        let resource = FooBarResources.getFoo(input: "123")
        let model = try await sut.get(with: resource)
        XCTAssertEqual(model, FooModel.Presets.foo)
    }

    func testGetWithQueryParams() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let resource = FooBarResources.getBar(inputs: ["234", "345"])
        let model = try await sut.get(with: resource)
        XCTAssertEqual(model, BarModel.Presets.bar)
    }

    func testHTTPError() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.invalid)
        let resource = FooBarResources.getFoo(input: "123")
        do {
            let _ = try await sut.get(with: resource)
            XCTFail("get unexpectedly returned value")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // TODO: figure out how to test cacheInterval and timeoutInterval

    func testGetAllPages() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let resource = FooBarResources.getFoos()
        var models: [FoosModel] = []
        do {
            for try await page in sut.pageStream(with: resource) {
                models.append(page)
            }
        } catch {
            XCTFail("pageStream threw error")
        }
        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models.first, FoosModel.Presets.foos1)
        XCTAssertEqual(models.last, FoosModel.Presets.foos2)
    }

    func testGetAllPagesWithSafetyLimit() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let resource = FooBarResources.getFoos()
        var models: [FoosModel] = []
        var theError: Error!
        do {
            for try await page in sut.pageStream(with: resource, safetyLimit: 1) {
                models.append(page)
            }
        } catch {
            theError = error
        }
        XCTAssertEqual(models.count, 1)
        XCTAssertEqual(models.first, FoosModel.Presets.foos1)
        XCTAssertNotNil(theError)
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

    func testBuildRequestWithAcceptOverride() throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.subpath)
        let resource = FooBarResources.getFooXML(input: "456")
        let request = try? sut.buildRequest(with: resource)
        XCTAssertEqual(request?.url?.absoluteString, "https://example.com/subpath/foo/456")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Accept": "application/xml"])
    }

    func testPageStreamIterator() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let resource = FooBarResources.getFoos()
        let stream = sut.pageStream(with: resource, safetyLimit: 1000)
        var page1: FoosModel!
        var pageIterator = stream.makeAsyncIterator()
        do {
            page1 = try await pageIterator.next()
        } catch {
            XCTFail("pageStream threw error")
        }
        XCTAssertEqual(page1, FoosModel.Presets.foos1)
        var page2: FoosModel!
        do {
            page2 = try await pageIterator.next()
        } catch {
            XCTFail("pageStream threw error")
        }
        XCTAssertEqual(page2, FoosModel.Presets.foos2)
        var pageNil: FoosModel?
        do {
            pageNil = try await pageIterator.next()
        } catch {
            XCTFail("pageStream threw error")
        }
        XCTAssertNil(pageNil)
    }

    func testPageStreamIteratorDoneFirstPass() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let resource = FooBarResources.getFoos3()
        let stream = sut.pageStream(with: resource, safetyLimit: 1000)
        var page1: FoosModel!
        var pageIterator = stream.makeAsyncIterator()
        do {
            page1 = try await pageIterator.next()
        } catch {
            XCTFail("pageStream threw error")
        }
        XCTAssertEqual(page1, FoosModel.Presets.foos3)
        var pageNil: FoosModel?
        do {
            pageNil = try await pageIterator.next()
        } catch {
            XCTFail("pageStream threw error")
        }
        XCTAssertNil(pageNil)
    }

    func testPageStreamIteratorWithPageQueryItem() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let resource = FooBarResources.getFoos4()
        let stream = sut.pageStream(with: resource, safetyLimit: 1000)
        var page1: FoosModel!
        var pageIterator = stream.makeAsyncIterator()
        do {
            page1 = try await pageIterator.next()
        } catch {
            XCTFail("pageStream threw error")
        }
        XCTAssertEqual(page1, FoosModel.Presets.foos1)
        var page2: FoosModel!
        do {
            page2 = try await pageIterator.next()
        } catch {
            XCTFail("pageStream threw error")
        }
        XCTAssertEqual(page2, FoosModel.Presets.foos2)
        var pageNil: FoosModel?
        do {
            pageNil = try await pageIterator.next()
        } catch {
            XCTFail("pageStream threw error")
        }
        XCTAssertNil(pageNil)
    }

    func testPageStreamIteratorWithPageQueryItemDoneFirstPass() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let resource = FooBarResources.getFoos6()
        let stream = sut.pageStream(with: resource, safetyLimit: 1000)
        var page1: FoosModel!
        var pageIterator = stream.makeAsyncIterator()
        do {
            page1 = try await pageIterator.next()
        } catch {
            XCTFail("pageStream threw error")
        }
        XCTAssertEqual(page1, FoosModel.Presets.foos3)
        var pageNil: FoosModel?
        do {
            pageNil = try await pageIterator.next()
        } catch {
            XCTFail("pageStream threw error")
        }
        XCTAssertNil(pageNil)
    }
}
