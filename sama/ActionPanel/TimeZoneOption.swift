//
//  TimeZoneOption.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/9/21.
//

import UIKit

struct TimeZoneOption {
    let id: String
    let title: String
    let hoursFromGMT: Int
    let isUsersTimezone: Bool

    static func from(timeZone: TimeZone, usersTimezone: TimeZone) -> TimeZoneOption {
        let id = timeZone.identifier
        let hoursFromGMT = Int(round(Double(TimeZone(identifier: id)!.secondsFromGMT()) / 3600))
        let sign = hoursFromGMT >= 0 ? "+" : ""
        return TimeZoneOption(
            id: id,
            title: "\(id) \(sign)\(hoursFromGMT)",
            hoursFromGMT: hoursFromGMT,
            isUsersTimezone: timeZone.secondsFromGMT() == usersTimezone.secondsFromGMT()
        )
    }
}
