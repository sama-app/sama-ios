//
//  SlotFinderTests.swift
//  samaTests
//
//  Created by Viktoras Laukevičius on 7/6/21.
//

import XCTest
@testable import sama

class SlotFinderTests: XCTestCase {

    private var finder: SlotFinder!

    override func setUp() {
        super.setUp()
        finder = SlotFinder()
    }

    override func tearDown() {
        super.tearDown()
        finder = nil
    }

    func test_notOverlappingSuggestions() {
        let props = [
            EventProperties(start: 12.25, duration: 0.25, daysOffset: 2, timezoneOffset: 0),
            EventProperties(start: 12.5, duration: 0.25, daysOffset: 2, timezoneOffset: 0),
        ]
        let result = finder.getPossibleSlots(
            with: SlotFinder.Context(
                eventProperties: props,
                blocksForDayIndex: [:],
                totalDaysOffset: 5002,
                currentDayIndex: 5000,
                baseStart: 11.75,
                duration: 3
            )
        )
        let exp = [
            SlotFinder.PossibleSlot(daysOffset: 1, start: 11.75),
            SlotFinder.PossibleSlot(daysOffset: 2, start: 12.75),
            SlotFinder.PossibleSlot(daysOffset: 2, start: 9.25),
            SlotFinder.PossibleSlot(daysOffset: 3, start: 11.75),
            SlotFinder.PossibleSlot(daysOffset: 4, start: 11.75)
        ]
        XCTAssertEqual(result, exp)
    }

    func test_notOverlappingEvents() {
        let result = finder.getPossibleSlots(
            with: SlotFinder.Context(
                eventProperties: [],
                blocksForDayIndex: [
                    5001: [CalendarBlockedTime(title: "SAMA Standup", start: 12.5, duration: 1, depth: 0)],
                    5003: [CalendarBlockedTime(title: "SAMA Standup", start: 12.5, duration: 1, depth: 0)]
                ],
                totalDaysOffset: 5001,
                currentDayIndex: 5000,
                baseStart: 11.5,
                duration: 3
            )
        )
        let exp = [
            SlotFinder.PossibleSlot(daysOffset: 0, start: 11.5),
            SlotFinder.PossibleSlot(daysOffset: 1, start: 13.5),
            SlotFinder.PossibleSlot(daysOffset: 1, start: 9.5),
            SlotFinder.PossibleSlot(daysOffset: 2, start: 11.5),
            SlotFinder.PossibleSlot(daysOffset: 3, start: 13.5),
            SlotFinder.PossibleSlot(daysOffset: 3, start: 9.5),
        ]
        XCTAssertEqual(result, exp)
    }
}
