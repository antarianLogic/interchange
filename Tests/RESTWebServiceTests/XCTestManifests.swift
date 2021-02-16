//
//  XCTestManifests.swift
//  RESTWebServiceTests
//
//  Created by Carl Sheppard on 1/15/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RESTWebServiceManagerTests.allTests),
        testCase(MultipageGetterTests.allTests)
    ]
}
#endif
