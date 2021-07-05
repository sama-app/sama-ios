//
//  DateFormatter+Factory.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/24/21.
//

import Foundation

extension DateFormatter {
    static func with(format: String, timeZone: TimeZone = .current) -> DateFormatter {
        let f = DateFormatter()
        f.timeZone = timeZone
        f.dateFormat = format
        return f
    }
}
