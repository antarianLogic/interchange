//
//  Pageable.swift
//  Interchange
//  
//  Created by Carl Sheppard on 2/5/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

/// A protocol that identifies the items and statistics in a response page.
///
/// Conform your response models to this protocol to enable automatic pagination when using ``InterchangeManager/pageStream(with:safetyLimit:)``.
///
public protocol Pageable {

    /// The type of items contained in each page.
    associatedtype Submodel

    /// The total number of items available across all pages.
    ///
    /// This is used to determine when pagination is complete.
    var totalCount: UInt { get }

    /// The current offset (starting position) of items in this page.
    ///
    /// For the first page, this is typically 0. For subsequent pages,
    /// it increases by the page size.
    var currentOffset: UInt { get }

    /// The array of items contained in this page.
    ///
    /// The count of items in this array is used to calculate the next offset.
    var submodels: [Submodel] { get }
}
