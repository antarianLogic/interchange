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
        let endpoint = FooBarEndpoints.getFoo(input: "123")
        let model: FooModel = try await sut.sendRequest(with: endpoint)
        XCTAssertEqual(model, FooModel.Presets.foo)
    }

    func testGetWithQueryParams() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let endpoint = FooBarEndpoints.getBar(inputs: ["234", "345"])
        let model: BarModel = try await sut.sendRequest(with: endpoint)
        XCTAssertEqual(model, BarModel.Presets.bar)
    }

    func testPutWithBodyParams() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let endpoint = FooBarEndpoints.putFoo()
        let model: FooModel = try await sut.sendRequest(with: endpoint)
        XCTAssertEqual(model, FooModel.Presets.foo)
    }

    func testHTTPError() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.invalid)
        let endpoint = FooBarEndpoints.getFoo(input: "123")
        do {
            let _: FooModel = try await sut.sendRequest(with: endpoint)
            XCTFail("sendRequest unexpectedly returned value")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testGetWithRateLimiting() async throws {
        let rateLimitHeaders = RESTRateLimitHeaders(rateLimitKey: "RateLimit",
                                                    rateLimitRemainingKey: "RateLimitRemaining")
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.subpath,
                                        rateLimitHeaders: rateLimitHeaders)
        let endpoint = FooBarEndpoints.getFoo2(input: "456")
        measure {
            let exp = expectation(description: "testGetWithRateLimiting")
            Task {
                let _: FooModel = try await sut.sendRequest(with: endpoint)
                exp.fulfill()
            }
            wait(for: [exp], timeout: 1000)
        }
    }

    // TODO: figure out how to test cacheInterval and timeoutInterval

    func testGetAllPages() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let endpoint = FooBarEndpoints.getFoos()
        var models: [FoosModel] = []
        do {
            for try await page: FoosModel in sut.pageStream(with: endpoint) {
                models.append(page)
            }
        } catch {
            XCTFail("pageStream threw error: \(error)")
        }
        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models.first, FoosModel.Presets.foos1)
        XCTAssertEqual(models.last, FoosModel.Presets.foos2)
    }

    func testGetAllPagesWithSafetyLimit() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let endpoint = FooBarEndpoints.getFoos()
        var models: [FoosModel] = []
        var theError: Error!
        do {
            for try await page: FoosModel in sut.pageStream(with: endpoint, safetyLimit: 1) {
                models.append(page)
            }
        } catch {
            theError = error
        }
        XCTAssertEqual(models.count, 1)
        XCTAssertEqual(models.first, FoosModel.Presets.foos1)
        XCTAssertNotNil(theError)
    }

    func testBuildRequestWithPathParams() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.subpath)
        let endpoint = FooBarEndpoints.getFoo(input: "123")
        let request = try? await sut.buildRequest(with: endpoint)
        XCTAssertEqual(request?.url?.absoluteString, "https://example.com/subpath/foo/123")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Accept": "application/json"])
    }

    func testBuildRequestWithQueryParams() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let endpoint = FooBarEndpoints.getBar(inputs: ["234","345"])
        let request = try? await sut.buildRequest(with: endpoint)
        XCTAssertEqual(request?.url?.absoluteString, "https://example.com/bar?inputs=234,345")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Accept": "application/json",
                                                      "User-Agent": "Foo/1.0.0 (bar@example.com)"])
    }

    func testBuildRequestWithBodyParams() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let endpoint = FooBarEndpoints.putFoo()
        let request = try? await sut.buildRequest(with: endpoint)
        XCTAssertEqual(request?.url?.absoluteString, "https://example.com/foo")
        XCTAssertEqual(request?.httpMethod, "PUT")
        XCTAssertEqual(request?.httpBody, Data("{\"body1\": \"body1 value\"}".utf8))
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Accept": "application/json",
                                                      "Content-Type": "application/json; charset=utf-8"])
    }

    func testBuildRequestWithAcceptOverride() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.subpath)
        let endpoint = FooBarEndpoints.getFooXML(input: "456")
        let request = try? await sut.buildRequest(with: endpoint)
        XCTAssertEqual(request?.url?.absoluteString, "https://example.com/subpath/foo/456")
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Accept": "application/xml"])
    }

    func testPerformRateLimiting() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.subpath)
        measure {
            let exp = expectation(description: "testPerformRateLimiting")
            Task {
                await sut.performRateLimiting()
                exp.fulfill()
            }
            wait(for: [exp], timeout: 60)
        }
    }

    func testPageStreamIterator() async throws {
        let sut = RESTWebServiceManager(baseURL: URL.BaseURLPresets.base)
        let endpoint = FooBarEndpoints.getFoos()
        let stream: AsyncThrowingStream<FoosModel,Error> = sut.pageStream(with: endpoint, safetyLimit: 1000)
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
        let endpoint = FooBarEndpoints.getFoos3()
        let stream: AsyncThrowingStream<FoosModel,Error> = sut.pageStream(with: endpoint, safetyLimit: 1000)
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
        let endpoint = FooBarEndpoints.getFoos4()
        let stream: AsyncThrowingStream<FoosModel,Error> = sut.pageStream(with: endpoint, safetyLimit: 1000)
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
        let endpoint = FooBarEndpoints.getFoos6()
        let stream: AsyncThrowingStream<FoosModel,Error> = sut.pageStream(with: endpoint, safetyLimit: 1000)
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
