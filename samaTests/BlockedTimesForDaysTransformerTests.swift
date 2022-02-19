//
//  BlockedTimesForDaysTransformerTests.swift
//  samaTests
//
//  Created by Viktoras Laukevičius on 7/6/21.
//

import XCTest
@testable import Sama

class BlockedTimesForDaysTransformerTests: XCTestCase {

    private var transformer: BlockedTimesForDaysTransformer!

    override func setUp() {
        super.setUp()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Vilnius")!
        var comps = DateComponents()
        comps.calendar = calendar
        comps.timeZone = TimeZone(identifier: "Europe/Vilnius")!
        comps.year = 2021
        comps.month = 7
        comps.day = 6
        comps.hour = 20
        comps.minute = 8
        let refDate = calendar.date(from: comps)!
        transformer = BlockedTimesForDaysTransformer(currentDayIndex: 5000, refDate: refDate, calendar: calendar)
    }

    override func tearDown() {
        super.tearDown()
        transformer = nil
    }

    func test_transformsModel() {
        let model = CalendarBlocks(
            events: [
                CalendarBlock(accountId: "a1", calendarId: "c1", title: "SAMA Standup #1", startDateTime: "2021-07-07T09:30:00Z", endDateTime: "2021-07-07T10:30:00Z", meetingBlock: false),
                CalendarBlock(accountId: "a1", calendarId: "c1", title: "SAMA Standup #2", startDateTime: "2021-07-09T09:30:00Z", endDateTime: "2021-07-09T10:30:00Z", meetingBlock: true),
            ]
        )
        let result = transformer.transform(model: model, in: (-5 ... 5))
        let exp = [
            4995: [],
            4996: [],
            4997: [],
            4998: [],
            4999: [],
            5000: [],
            5001: [CalendarBlockedTime(id: AccountCalendarId(accountId: "a1", calendarId: "c1"), title: "SAMA Standup #1", start: 12.5, duration: 1, isBlockedTime: false, depth: 0)],
            5002: [],
            5003: [CalendarBlockedTime(id: AccountCalendarId(accountId: "a1", calendarId: "c1"), title: "SAMA Standup #2", start: 12.5, duration: 1, isBlockedTime: true, depth: 0)],
            5004: [],
            5005: []
        ]
        XCTAssertEqual(result, exp)
    }
}
