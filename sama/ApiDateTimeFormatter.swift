//
//  ApiDateTimeFormatter.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/24/21.
//

import Foundation

struct ApiDateTimeFormatter {
    static let formatter = DateFormatter.with(format: "YYYY-MM-dd'T'HH:mm:ss'Z'", timeZone: TimeZone(identifier: "GMT")!)

    /// transforms dropping last 6 chars and parses
    ///
    /// i.e 2021-06-25T12:30:00+03:00 becomes 2021-06-25T12:30:00
    func date(from value: String) -> Date {
        return ApiDateTimeFormatter.formatter.date(from: value)!
    }
}
