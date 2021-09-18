//
//  CalendarBlocks.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import Foundation

struct CalendarBlocks: Decodable {
    let events: [CalendarBlock]
}

struct CalendarBlock: Decodable {
    let title: String?
    let startDateTime: String
    let endDateTime: String
}
