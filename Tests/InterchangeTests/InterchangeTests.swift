//
//  InterchangeManagerTests.swift
//  InterchangeTests
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation
import Testing
import Mocker
@testable import Interchange

struct InterchangeManagerTests {

    let sutBase: InterchangeManager
    let sutSubpath: InterchangeManager
    let sutInvalid: InterchangeManager

    init() {
        Mock.registerAll()
        sutBase = InterchangeManager(baseURL: URL.BaseURLPresets.base)
        sutSubpath = InterchangeManager(baseURL: URL.BaseURLPresets.subpath)
        sutInvalid = InterchangeManager(baseURL: URL.BaseURLPresets.invalid)
    }

    @Test func getWithPathParams() async throws {
        let endpoint = FooBarEndpoints.getFoo(input: "123")
        let model: FooModel = try await sutSubpath.sendRequest(with: endpoint)
        #expect(model == FooModel.Presets.foo)
    }

    @Test func getWithQueryParams() async throws {
        let endpoint = FooBarEndpoints.getBar(inputs: ["234", "345"])
        let model: BarModel = try await sutBase.sendRequest(with: endpoint)
        #expect(model == BarModel.Presets.bar)
    }

    @Test func putWithBodyParams() async throws {
        let endpoint = FooBarEndpoints.putFoo()
        let model: FooModel = try await sutBase.sendRequest(with: endpoint)
        #expect(model == FooModel.Presets.foo)
    }

    @Test func httpError() async throws {
        let endpoint = FooBarEndpoints.getFoo(input: "123")
        do {
            let _: FooModel = try await sutInvalid.sendRequest(with: endpoint)
            Issue.record("sendRequest unexpectedly returned value")
        } catch let error as InterchangeError {
            if case let .httpError(statusCode, _, _) = error {
                #expect(statusCode == 400)
            } else {
                Issue.record("Expected InterchangeError.httpError but got \(error)")
            }
        } catch {
            Issue.record("Expected InterchangeError but got \(error)")
        }
    }

    @Test(.timeLimit(.minutes(1))) func getWithRateLimiting() async throws {
        let rateLimitHeaders = RESTRateLimitHeaders(rateLimitKey: "RateLimit",
                                                    rateLimitRemainingKey: "RateLimitRemaining")
        let sut = InterchangeManager(baseURL: URL.BaseURLPresets.subpath,
                                     rateLimitHeaders: rateLimitHeaders)
        let endpoint = FooBarEndpoints.getFoo2(input: "456")
        let _: FooModel = try await sut.sendRequest(with: endpoint)
    }

    // TODO: figure out how to test cacheInterval and timeoutInterval

    @Test func getAllPages() async throws {
        let endpoint = FooBarEndpoints.getFoos()
        var models: [FoosModel] = []
        do {
            for try await page: FoosModel in sutBase.pageStream(with: endpoint) {
                models.append(page)
            }
        } catch {
            Issue.record("pageStream threw error: \(error)")
        }
        #expect(models.count == 2)
        #expect(models.first == FoosModel.Presets.foos1)
        #expect(models.last == FoosModel.Presets.foos2)
    }

    @Test func getAllPagesWithSafetyLimit() async throws {
        let endpoint = FooBarEndpoints.getFoos()
        var models: [FoosModel] = []
        do {
            for try await page: FoosModel in sutBase.pageStream(with: endpoint, safetyLimit: 1) {
                models.append(page)
            }
        } catch {
            Issue.record("pageStream threw error: \(error)")
        }
        #expect(models.count == 1)
        #expect(models.first == FoosModel.Presets.foos1)
    }

    @Test func buildRequestWithPathParams() async throws {
        let endpoint = FooBarEndpoints.getFoo(input: "123")
        let request = try? await sutSubpath.buildRequest(with: endpoint)
        #expect(request?.url?.absoluteString == "https://example.com/subpath/foo/123")
        #expect(request?.httpMethod == "GET")
        #expect(request?.allHTTPHeaderFields == ["Accept": "application/json"])
    }

    @Test func buildRequestWithQueryParams() async throws {
        let endpoint = FooBarEndpoints.getBar(inputs: ["234", "345"])
        let request = try? await sutBase.buildRequest(with: endpoint)
        #expect(request?.url?.absoluteString == "https://example.com/bar?inputs=234,345")
        #expect(request?.httpMethod == "GET")
        #expect(request?.allHTTPHeaderFields == ["Accept": "application/json",
                                                 "User-Agent": "Foo/1.0.0 (bar@example.com)"])
    }

    @Test func buildRequestWithBodyParams() async throws {
        let endpoint = FooBarEndpoints.putFoo()
        let request = try? await sutBase.buildRequest(with: endpoint)
        #expect(request?.url?.absoluteString == "https://example.com/foo")
        #expect(request?.httpMethod == "PUT")
        #expect(request?.httpBody == Data("{\"body1\": \"body1 value\"}".utf8))
        #expect(request?.allHTTPHeaderFields == ["Accept": "application/json",
                                                 "Content-Type": "application/json; charset=utf-8"])
    }

    @Test func buildRequestWithAcceptOverride() async throws {
        let endpoint = FooBarEndpoints.getFooXML(input: "456")
        let request = try? await sutSubpath.buildRequest(with: endpoint)
        #expect(request?.url?.absoluteString == "https://example.com/subpath/foo/456")
        #expect(request?.httpMethod == "GET")
        #expect(request?.allHTTPHeaderFields == ["Accept": "application/xml"])
    }

    @Test(.timeLimit(.minutes(1))) func performRateLimiting() async throws {
        await sutSubpath.performRateLimiting()
    }

    @Test func pageStreamIterator() async throws {
        let endpoint = FooBarEndpoints.getFoos()
        let stream: AsyncThrowingStream<FoosModel, Error> = sutBase.pageStream(with: endpoint, safetyLimit: 1000)
        var pageIterator = stream.makeAsyncIterator()
        var page1: FoosModel!
        do {
            page1 = try await pageIterator.next()
        } catch {
            Issue.record("pageStream threw error")
        }
        #expect(page1 == FoosModel.Presets.foos1)
        var page2: FoosModel!
        do {
            page2 = try await pageIterator.next()
        } catch {
            Issue.record("pageStream threw error")
        }
        #expect(page2 == FoosModel.Presets.foos2)
        var pageNil: FoosModel?
        do {
            pageNil = try await pageIterator.next()
        } catch {
            Issue.record("pageStream threw error")
        }
        #expect(pageNil == nil)
    }

    @Test func pageStreamIteratorDoneFirstPass() async throws {
        let endpoint = FooBarEndpoints.getFoos3()
        let stream: AsyncThrowingStream<FoosModel, Error> = sutBase.pageStream(with: endpoint, safetyLimit: 1000)
        var pageIterator = stream.makeAsyncIterator()
        var page1: FoosModel!
        do {
            page1 = try await pageIterator.next()
        } catch {
            Issue.record("pageStream threw error")
        }
        #expect(page1 == FoosModel.Presets.foos3)
        var pageNil: FoosModel?
        do {
            pageNil = try await pageIterator.next()
        } catch {
            Issue.record("pageStream threw error")
        }
        #expect(pageNil == nil)
    }

    @Test func pageStreamIteratorWithPageQueryItem() async throws {
        let endpoint = FooBarEndpoints.getFoos4()
        let stream: AsyncThrowingStream<FoosModel, Error> = sutBase.pageStream(with: endpoint, safetyLimit: 1000)
        var pageIterator = stream.makeAsyncIterator()
        var page1: FoosModel!
        do {
            page1 = try await pageIterator.next()
        } catch {
            Issue.record("pageStream threw error")
        }
        #expect(page1 == FoosModel.Presets.foos1)
        var page2: FoosModel!
        do {
            page2 = try await pageIterator.next()
        } catch {
            Issue.record("pageStream threw error")
        }
        #expect(page2 == FoosModel.Presets.foos2)
        var pageNil: FoosModel?
        do {
            pageNil = try await pageIterator.next()
        } catch {
            Issue.record("pageStream threw error")
        }
        #expect(pageNil == nil)
    }

    @Test func pageStreamIteratorWithPageQueryItemDoneFirstPass() async throws {
        let endpoint = FooBarEndpoints.getFoos6()
        let stream: AsyncThrowingStream<FoosModel, Error> = sutBase.pageStream(with: endpoint, safetyLimit: 1000)
        var pageIterator = stream.makeAsyncIterator()
        var page1: FoosModel!
        do {
            page1 = try await pageIterator.next()
        } catch {
            Issue.record("pageStream threw error")
        }
        #expect(page1 == FoosModel.Presets.foos3)
        var pageNil: FoosModel?
        do {
            pageNil = try await pageIterator.next()
        } catch {
            Issue.record("pageStream threw error")
        }
        #expect(pageNil == nil)
    }
}
