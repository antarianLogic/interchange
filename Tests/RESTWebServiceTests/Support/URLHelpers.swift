//
//  URLHelpers.swift
//  RESTWebServiceTests
//
//  Created by Carl Sheppard on 2/13/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

extension URL {

    enum BaseURLPresets {
        static let base = URL(string: String.BaseURLPresets.base)!
        static let subpath = URL(string: String.BaseURLPresets.subpath)!
        static let invalid = URL(string: String.BaseURLPresets.invalid)!
    }

    enum FullURLPresets {
        static let foo = URL(string: String.FullURLPresets.foo)!
        static let bar = URL(string: String.FullURLPresets.bar)!
        static let foos0 = URL(string: String.FullURLPresets.foos0)!
        static let foos2 = URL(string: String.FullURLPresets.foos2)!
        static let foos3 = URL(string: String.FullURLPresets.foos3)!
    }
}
