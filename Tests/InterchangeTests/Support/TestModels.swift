//
//  TestModels.swift
//  InterchangeTests
//
//  Created by Carl Sheppard on 2/12/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation
@testable import Interchange

struct FooModel: Codable, Equatable {
    let name: String
}

extension FooModel {
    enum Presets {
        static let foo = FooModel(name: "foo")
        static let foo1 = FooModel(name: "foo1")
        static let foo2 = FooModel(name: "foo2")
        static let foo3 = FooModel(name: "foo3")
    }
}

struct BarModel: Codable, Equatable {
    let age: Int?
}

extension BarModel {
    enum Presets {
        static let bar = BarModel(age: 8)
    }
}

struct FoosModel: Codable, Equatable {
    let count: UInt
    let offset: UInt
    let foos: [FooModel]
}

extension FoosModel: Pageable {
    var totalCount: UInt { return count }
    var currentOffset: UInt { return offset }
    var submodels: [FooModel] { return foos }
}

extension FoosModel {
    enum Presets {
        static let foos1 = FoosModel(count: 3, offset: 0, foos: [FooModel.Presets.foo1, FooModel.Presets.foo2])
        static let foos2 = FoosModel(count: 3, offset: 2, foos: [FooModel.Presets.foo3])
        static let foos3 = FoosModel(count: 3, offset: 0, foos: [FooModel.Presets.foo1, FooModel.Presets.foo2, FooModel.Presets.foo3])
    }
}
