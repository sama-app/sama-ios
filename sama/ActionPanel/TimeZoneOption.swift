//
//  TimeZoneOption.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/9/21.
//

import UIKit

struct TimeZoneOption {
    let id: String
    let placeTitle: String
    let offsetTitle: String
    let hoursFromGMT: Int
    let isUsersTimezone: Bool

    static func from(timeZone: TimeZone, usersTimezone: TimeZone) -> TimeZoneOption {
        let id = timeZone.identifier
        let placeTitle = id.split(separator: "/").last!.replacingOccurrences(of: "_", with: " ")
        let hoursFromGMT = Int(round(Double(TimeZone(identifier: id)!.secondsFromGMT()) / 3600))
        let sign = (hoursFromGMT > 0) ? "+" : ""
        let hoursTitle = (hoursFromGMT != 0) ? "\(hoursFromGMT)" : ""
        let offsetTitle = "GMT\(sign)\(hoursTitle)"
        return TimeZoneOption(
            id: id,
            placeTitle: placeTitle,
            offsetTitle: offsetTitle,
            hoursFromGMT: hoursFromGMT,
            isUsersTimezone: timeZone.secondsFromGMT() == usersTimezone.secondsFromGMT()
        )
    }
}
