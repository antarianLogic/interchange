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
        static let bar = Mock(url: URL.FullURLPresets.bar, jsonString: String.JSONPresets.bar.rawValue)
        static let foos1 = Mock(url: URL.FullURLPresets.foos1, jsonString: String.JSONPresets.foos1.rawValue)
        static let foos2 = Mock(url: URL.FullURLPresets.foos2, jsonString: String.JSONPresets.foos2.rawValue)
        static let foos3 = Mock(url: URL.FullURLPresets.foos3, jsonString: String.JSONPresets.foos3.rawValue)
        static let foos4 = Mock(url: URL.FullURLPresets.foos4, jsonString: String.JSONPresets.foos1.rawValue)
        static let foos5 = Mock(url: URL.FullURLPresets.foos5, jsonString: String.JSONPresets.foos2.rawValue)
        static let foos6 = Mock(url: URL.FullURLPresets.foos6, jsonString: String.JSONPresets.foos3.rawValue)
        static let invalid = Mock(url: URL.FullURLPresets.invalid, jsonString: String.JSONPresets.invalid.rawValue, statusCode: 400)
    }

    init(url: URL, jsonString: String, statusCode: Int = 200) {
        self.init(url: url, dataType: .json, statusCode: statusCode, data: [.get : Data(jsonString.utf8)])
    }

    static func registerAll() {
        Presets.foo.register()
        Presets.bar.register()
        Presets.foos1.register()
        Presets.foos2.register()
        Presets.foos3.register()
        Presets.foos4.register()
        Presets.foos5.register()
        Presets.foos6.register()
        Presets.invalid.register()
    }
}
