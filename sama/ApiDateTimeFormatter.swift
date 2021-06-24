//
//  ApiDateTimeFormatter.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/24/21.
//

import Foundation

struct ApiDateTimeFormatter {
    private let formatter = DateFormatter.with(format: "YYYY-MM-dd'T'HH:mm:ss")

    /// transforms dropping last 6 chars and parses
    ///
    /// i.e 2021-06-25T12:30:00+03:00 becomes 2021-06-25T12:30:00
    func date(from value: String) -> Date {
        return formatter.date(from: String(value.dropLast(6)))!
    }
}
