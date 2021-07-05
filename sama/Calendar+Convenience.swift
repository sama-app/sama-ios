//
//  Calendar+Convenience.swift
//  sama
//
//  Created by Viktoras Laukevičius on 7/5/21.
//

import Foundation

extension Calendar {
    func toTimeZone(date: Date) -> Date {
        return self.date(from: dateComponents(in: timeZone, from: date))!
    }
}
