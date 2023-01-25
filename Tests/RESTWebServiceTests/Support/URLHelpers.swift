//
//  URLHelpers.swift
//  RESTWebServiceTests
//
//  Created by Carl Sheppard on 2/13/21.
//  Copyright © 2022 Antarian Logic LLC. All rights reserved.
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
        static let foo2 = URL(string: String.FullURLPresets.foo2)!
        static let bar = URL(string: String.FullURLPresets.bar)!
        static let foos1 = URL(string: String.FullURLPresets.foos1)!
        static let foos2 = URL(string: String.FullURLPresets.foos2)!
        static let foos3 = URL(string: String.FullURLPresets.foos3)!
        static let foos4 = URL(string: String.FullURLPresets.foos4)!
        static let foos5 = URL(string: String.FullURLPresets.foos5)!
        static let foos6 = URL(string: String.FullURLPresets.foos6)!
        static let invalid = URL(string: String.FullURLPresets.invalid)!
        static let f00 = URL(string: String.FullURLPresets.f00)!
    }
}
