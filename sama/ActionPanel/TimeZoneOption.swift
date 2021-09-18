//
//  TimeZoneOption.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/9/21.
//

import UIKit

struct TimeZoneOption {
    let itemId: String
    let zoneId: String
    let placeTitle: String
    let offsetTitle: String
    let hoursFromGMT: Int
    let isUsersTimezone: Bool

    static func from(timeZone: TimeZone, usersTimezone: TimeZone) -> TimeZoneOption {
        return make(
            itemId: "----",
            zoneId: timeZone.identifier,
            placeTitle: timeZone.identifier.split(separator: "/").last!.replacingOccurrences(of: "_", with: " "),
            secsFromGMT: timeZone.secondsFromGMT(),
            usersTimezone: usersTimezone
        )
    }

    static func make(itemId: String, zoneId: String, placeTitle: String, secsFromGMT: Int, usersTimezone: TimeZone) -> TimeZoneOption {
        let hoursFromGMT = Int(round(Double(secsFromGMT) / 3600))
        let sign = (hoursFromGMT > 0) ? "+" : ""
        let hoursTitle = (hoursFromGMT != 0) ? "\(hoursFromGMT)" : ""
        let offsetTitle = "GMT\(sign)\(hoursTitle)"
        return TimeZoneOption(
            itemId: itemId,
            zoneId: zoneId,
            placeTitle: placeTitle,
            offsetTitle: offsetTitle,
            hoursFromGMT: hoursFromGMT,
            isUsersTimezone: secsFromGMT == usersTimezone.secondsFromGMT()
        )
    }
}
