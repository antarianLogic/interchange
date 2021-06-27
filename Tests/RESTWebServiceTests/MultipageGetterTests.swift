//
//  MultipageGetterTests.swift
//  RESTWebServiceTests
//
//  Created by Carl Sheppard on 2/11/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import XCTest
import Combine
import Mocker
@testable import RESTWebService

final class MultipageGetterTests: XCTestCase {

    override class func setUp() {
        Mock.registerAll()
    }

    var cancellables: Set<AnyCancellable> = []

    func testGetNextPageIncomplete() throws {
        let sut = MultipageGetter(initialResource: FooBarResources.getFoos(),
                                  manager: RESTWebServiceManager(baseURL: URL.BaseURLPresets.base))
        XCTAssertEqual(sut.receivedCount, 0)
        XCTAssertNil(sut.totalCount)
        XCTAssertEqual(sut.currentResource, FooBarResources.getFoos())
        XCTAssertFalse(sut.receivedAllPages)
        let exp = expectation(description: "testGetNextPageIncomplete")
        var models: [FoosModel] = []
        let cancellable = sut.publisher.sink { completion in
            XCTFail("should not have received completion yet")
        } receiveValue: { output in
            models.append(output)
            exp.fulfill()
        }
        cancellables.insert(cancellable)
        let status = sut.getNextPage()
        XCTAssertTrue(status)
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(sut.receivedCount, 2)
        XCTAssertEqual(sut.totalCount, 3)
        XCTAssertEqual(sut.currentResource, FooBarResources.getFoos())
        XCTAssertFalse(sut.receivedAllPages)
        XCTAssertEqual(models.count, 1)
        XCTAssertEqual(models.first, FoosModel.Presets.foos1)
    }

    func testGetNextPageComplete() throws {
        let sut = MultipageGetter(initialResource: FooBarResources.getFoos(),
                                  manager: RESTWebServiceManager(baseURL: URL.BaseURLPresets.base))
        let exp = expectation(description: "testGetNextPageComplete")
        var models: [FoosModel] = []
        let cancellable = sut.publisher.sink { completion in
            switch completion {
            case let .failure(error):
                XCTFail("should not have received failure, error: \(error)")
            default: break
            }
            exp.fulfill()
        } receiveValue: { output in
            models.append(output)
            guard !sut.receivedAllPages else { return }

            let status = sut.getNextPage()
            XCTAssertTrue(status)
        }
        cancellables.insert(cancellable)
        let status = sut.getNextPage()
        XCTAssertTrue(status)
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(sut.receivedCount, 3)
        XCTAssertEqual(sut.totalCount, 3)
        XCTAssertEqual(sut.currentResource, FooBarResources.getFoos2())
        XCTAssertTrue(sut.receivedAllPages)
        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models.first, FoosModel.Presets.foos1)
        XCTAssertEqual(models.last, FoosModel.Presets.foos2)
    }

    func testGetNextPageCompleteFirstPass() throws {
        let sut = MultipageGetter(initialResource: FooBarResources.getFoos3(),
                                  manager: RESTWebServiceManager(baseURL: URL.BaseURLPresets.base))
        let exp = expectation(description: "testGetNextPageCompleteFirstPass")
        var models: [FoosModel] = []
        let cancellable = sut.publisher.sink { completion in
            switch completion {
            case .failure:
                XCTFail("should not have received failure")
            default: break
            }
            exp.fulfill()
        } receiveValue: { output in
            models.append(output)
        }
        cancellables.insert(cancellable)
        let status = sut.getNextPage()
        XCTAssertTrue(status)
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(sut.receivedCount, 3)
        XCTAssertEqual(sut.totalCount, 3)
        XCTAssertEqual(sut.currentResource, FooBarResources.getFoos3())
        XCTAssertTrue(sut.receivedAllPages)
        XCTAssertEqual(models.count, 1)
        XCTAssertEqual(models.first, FoosModel.Presets.foos3)
    }

    func testGetNextPageIncompleteWithPageQueryItem() throws {
        let sut = MultipageGetter(initialResource: FooBarResources.getFoos4(),
                                  manager: RESTWebServiceManager(baseURL: URL.BaseURLPresets.base))
        XCTAssertEqual(sut.receivedCount, 0)
        XCTAssertNil(sut.totalCount)
        XCTAssertEqual(sut.currentResource, FooBarResources.getFoos4())
        XCTAssertFalse(sut.receivedAllPages)
        let exp = expectation(description: "testGetNextPageIncompleteWithPageQueryItem")
        var models: [FoosModel] = []
        let cancellable = sut.publisher.sink { completion in
            XCTFail("should not have received completion yet")
        } receiveValue: { output in
            models.append(output)
            exp.fulfill()
        }
        cancellables.insert(cancellable)
        let status = sut.getNextPage()
        XCTAssertTrue(status)
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(sut.receivedCount, 2)
        XCTAssertEqual(sut.totalCount, 3)
        XCTAssertEqual(sut.currentResource, FooBarResources.getFoos4())
        XCTAssertFalse(sut.receivedAllPages)
        XCTAssertEqual(models.count, 1)
        XCTAssertEqual(models.first, FoosModel.Presets.foos1)
    }

    func testGetNextPageCompleteWithPageQueryItem() throws {
        let sut = MultipageGetter(initialResource: FooBarResources.getFoos4(),
                                  manager: RESTWebServiceManager(baseURL: URL.BaseURLPresets.base))
        let exp = expectation(description: "testGetNextPageCompleteWithPageQueryItem")
        var models: [FoosModel] = []
        let cancellable = sut.publisher.sink { completion in
            switch completion {
            case let .failure(error):
                XCTFail("should not have received failure, error: \(error)")
            default: break
            }
            exp.fulfill()
        } receiveValue: { output in
            models.append(output)
            guard !sut.receivedAllPages else { return }

            let status = sut.getNextPage()
            XCTAssertTrue(status)
        }
        cancellables.insert(cancellable)
        let status = sut.getNextPage()
        XCTAssertTrue(status)
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(sut.receivedCount, 3)
        XCTAssertEqual(sut.totalCount, 3)
        XCTAssertEqual(sut.currentResource, FooBarResources.getFoos5())
        XCTAssertTrue(sut.receivedAllPages)
        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models.first, FoosModel.Presets.foos1)
        XCTAssertEqual(models.last, FoosModel.Presets.foos2)
    }

    func testGetNextPageCompleteFirstPassWithPageQueryItem() throws {
        let sut = MultipageGetter(initialResource: FooBarResources.getFoos6(),
                                  manager: RESTWebServiceManager(baseURL: URL.BaseURLPresets.base))
        let exp = expectation(description: "testGetNextPageCompleteFirstPassWithPageQueryItem")
        var models: [FoosModel] = []
        let cancellable = sut.publisher.sink { completion in
            switch completion {
            case .failure:
                XCTFail("should not have received failure")
            default: break
            }
            exp.fulfill()
        } receiveValue: { output in
            models.append(output)
        }
        cancellables.insert(cancellable)
        let status = sut.getNextPage()
        XCTAssertTrue(status)
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(sut.receivedCount, 3)
        XCTAssertEqual(sut.totalCount, 3)
        XCTAssertEqual(sut.currentResource, FooBarResources.getFoos6())
        XCTAssertTrue(sut.receivedAllPages)
        XCTAssertEqual(models.count, 1)
        XCTAssertEqual(models.first, FoosModel.Presets.foos3)
    }
}
