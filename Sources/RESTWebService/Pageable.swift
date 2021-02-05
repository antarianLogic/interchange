//
//  Pageable.swift
//  RESTWebService
//  
//  Created by Carl Sheppard on 2/5/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

public protocol Pageable {

    associatedtype Submodel

    var totalCount: UInt { get }

    var currentOffset: UInt { get }

    var submodels: [Submodel] { get }
}
