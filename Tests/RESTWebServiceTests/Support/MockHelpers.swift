//
//  MockHelpers.swift
//  RESTWebServiceTests
//
//  Created by Carl Sheppard on 2/13/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation
import Mocker

extension Mock {

    enum Presets {
        static let foo = Mock(url: URL.FullURLPresets.foo, jsonString: String.JSONPresets.foo.rawValue)
        static let foo2 = Mock(url: URL.FullURLPresets.foo2, jsonString: String.JSONPresets.foo.rawValue,
                               additionalHeaders: ["RateLimit" : "60",
                                                   "RateLimitRemaining" : "20"])
        static let bar = Mock(url: URL.FullURLPresets.bar, jsonString: String.JSONPresets.bar.rawValue)
        static let foos1 = Mock(url: URL.FullURLPresets.foos1, jsonString: String.JSONPresets.foos1.rawValue)
        static let foos2 = Mock(url: URL.FullURLPresets.foos2, jsonString: String.JSONPresets.foos2.rawValue)
        static let foos3 = Mock(url: URL.FullURLPresets.foos3, jsonString: String.JSONPresets.foos3.rawValue)
        static let foos4 = Mock(url: URL.FullURLPresets.foos4, jsonString: String.JSONPresets.foos1.rawValue)
        static let foos5 = Mock(url: URL.FullURLPresets.foos5, jsonString: String.JSONPresets.foos2.rawValue)
        static let foos6 = Mock(url: URL.FullURLPresets.foos6, jsonString: String.JSONPresets.foos3.rawValue)
        static let f00 = Mock(url: URL.FullURLPresets.f00, method: .put, jsonString: String.JSONPresets.foo.rawValue)
        static let invalid = Mock(url: URL.FullURLPresets.invalid, jsonString: String.JSONPresets.invalid.rawValue, statusCode: 400)
    }

    init(url: URL, method: HTTPMethod = .get, jsonString: String, statusCode: Int = 200, additionalHeaders: [String : String] = [:]) {
        self.init(url: url, dataType: .json, statusCode: statusCode, data: [method : Data(jsonString.utf8)], additionalHeaders: additionalHeaders)
    }

    static func registerAll() {
        Presets.foo.register()
        Presets.foo2.register()
        Presets.bar.register()
        Presets.foos1.register()
        Presets.foos2.register()
        Presets.foos3.register()
        Presets.foos4.register()
        Presets.foos5.register()
        Presets.foos6.register()
        Presets.f00.register()
        Presets.invalid.register()
    }
}
