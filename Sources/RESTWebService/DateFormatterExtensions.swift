//
//  DateFormatterExtensions.swift
//  RESTWebService
//
//  Created by Carl Sheppard on 2/7/21.
//  Copyright © 2021 Antarian Logic LLC. All rights reserved.
//

import Foundation

extension DateFormatter {

    static let rfc822DateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss zzz"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
