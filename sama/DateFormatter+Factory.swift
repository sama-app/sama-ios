//
//  DateFormatter+Factory.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/24/21.
//

import Foundation

extension DateFormatter {
    static func with(format: String) -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = format
        return f
    }
}
