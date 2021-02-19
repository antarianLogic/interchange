//
//  StringHelpers.swift
//  RESTWebServiceTests
//
//  Created by Carl Sheppard on 2/13/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

extension String {

    enum DomainPresets: String, CaseIterable {
        case example = "https://example.com"
    }

    enum BasePathPresets: String, CaseIterable {
        case empty = ""
        case subpath = "/subpath"
        case invalid = "/invalid"
    }

    enum BaseURLPresets {
        static let base = DomainPresets.example.rawValue + BasePathPresets.empty.rawValue
        static let subpath = DomainPresets.example.rawValue + BasePathPresets.subpath.rawValue
        static let invalid = DomainPresets.example.rawValue + BasePathPresets.invalid.rawValue
    }

    enum PathPresets: String, CaseIterable {
        case foo = "/foo/123"
        case bar = "/bar?inputs=234,345"
        case foos0 = "/foos?pageSize=2&offset=0"
        case foos2 = "/foos?pageSize=2&offset=2"
        case foos3 = "/foos?pageSize=3&offset=0"
    }

    enum FullURLPresets {
        static let foo = BaseURLPresets.subpath + PathPresets.foo.rawValue
        static let bar = BaseURLPresets.base + PathPresets.bar.rawValue
        static let foos0 = BaseURLPresets.base + PathPresets.foos0.rawValue
        static let foos2 = BaseURLPresets.base + PathPresets.foos2.rawValue
        static let foos3 = BaseURLPresets.base + PathPresets.foos3.rawValue
        static let invalid = BaseURLPresets.invalid + PathPresets.foo.rawValue
    }

    enum JSONPresets: String, CaseIterable {
        case foo = "{ \"name\": \"foo\" }"
        case bar = "{ \"age\": 8 }"
        case foos0 = "{ \"count\": 3, \"offset\": 0, \"foos\": [ { \"name\": \"foo1\" }, { \"name\": \"foo2\" } ] }"
        case foos2 = "{ \"count\": 3, \"offset\": 2, \"foos\": [ { \"name\": \"foo3\" } ] }"
        case foos3 = "{ \"count\": 3, \"offset\": 0, \"foos\": [ { \"name\": \"foo1\" }, { \"name\": \"foo2\" }, { \"name\": \"foo3\" } ] }"
        case invalid = "{}"
    }
}
