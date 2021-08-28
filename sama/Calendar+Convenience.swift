//
//  Calendar+Convenience.swift
//  sama
//
//  Created by Viktoras Laukevičius on 7/5/21.
//

import Foundation

/// i.e 11:34
let timeFormatter = DateFormatter.withLocalized(format: "HHmm")

/// i.e Friday
let weekdayFormatter = DateFormatter.with(format: "EEEE")

/// i.e Jul 15
let dayFormatter = DateFormatter.withLocalized(format: "dMMM")

extension Calendar {
    func toTimeZone(date: Date) -> Date {
        return self.date(from: dateComponents(in: timeZone, from: date))!
    }

    func relativeFormatted(from: Date, to: Date) -> String {
        let diff = dateComponents([.day], from: from, to: to)
        if diff.day! >= 0 && diff.day! <= 7 {
            return weekdayRelativeFormatted(from: from, to: to)
        } else {
            return dayFormatter.string(from: to)
        }
    }

    func weekdayRelativeFormatted(from: Date, to: Date) -> String {
        let diff = dateComponents([.day], from: from, to: to)
        if diff.day == 0 {
            return  "Today"
        } else if diff.day == 1 {
            return "Tomorrow"
        } else {
            return weekdayFormatter.string(from: to)
        }
    }
}
