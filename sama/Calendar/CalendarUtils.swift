//
//  CalendarUtils.swift
//  sama
//
//  Created by Viktoras Laukevičius on 9/27/21.
//

import Foundation

struct CalendarDateUtils {

    static let shared = CalendarDateUtils(uiRefDate: Date())

    let uiRefDate: Date

    var dateNow: Date {
        return Date()
    }
}
