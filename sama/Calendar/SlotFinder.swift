//
//  SlotFinder.swift
//  sama
//
//  Created by Viktoras Laukevičius on 7/6/21.
//

import Foundation

struct SlotFinder {

    struct Context {
        let eventProperties: [EventProperties]
        let blocksForDayIndex: [Int: [CalendarBlockedTime]]
        let totalDaysOffset: Int
        let currentDayIndex: Int
        let minTarget: RescheduleTarget
        let baseStart: Decimal
        let duration: Decimal
    }

    struct PossibleSlot: Equatable {
        let daysOffset: Int
        let start: Decimal
    }

    func getPossibleSlots(with context: Context) -> [PossibleSlot] {
        let baseDaysOffset = context.totalDaysOffset - context.currentDayIndex
        let maxMinsOffset = NSDecimalNumber(value: 24).subtracting(NSDecimalNumber(decimal: context.duration)).decimalValue

        var possibleSlots: [PossibleSlot] = []
        for i in (baseDaysOffset - 1 ..< baseDaysOffset + 3) {
            possibleSlots += getPossibleSlots(with: context, dayIndex: i, maxMinsOffset: maxMinsOffset)
        }

        if possibleSlots.isEmpty {
            for i in (context.minTarget.daysOffset ..< 90) {
                let slots = getPossibleSlots(with: context, dayIndex: i, maxMinsOffset: maxMinsOffset)
                if !slots.isEmpty {
                    possibleSlots += slots
                    break
                }
            }
        }

        var uniqueSlots: [PossibleSlot] = []
        for slot in possibleSlots {
            if !uniqueSlots.contains(slot) {
                uniqueSlots.append(slot)
            }
        }
        return uniqueSlots
    }

    private func getPossibleSlots(with context: Context, dayIndex: Int, maxMinsOffset: Decimal) -> [PossibleSlot] {
        var possibleSlots: [PossibleSlot] = []

        // exact and down
        var start = context.baseStart
        while start < maxMinsOffset {
            if isSlotPossible(with: context, dayIndex: dayIndex, start: start) {
                possibleSlots.append(PossibleSlot(daysOffset: dayIndex, start: start))
                break
            }
            start += 0.25
        }

        // exact and up
        start = context.baseStart
        while start > 0 {
            if isSlotPossible(with: context, dayIndex: dayIndex, start: start) {
                possibleSlots.append(PossibleSlot(daysOffset: dayIndex, start: start))
                break
            }
            start -= 0.25
        }

        return possibleSlots
    }

    private func isSlotPossible(with context: Context, dayIndex: Int, start: Decimal) -> Bool {
        if dayIndex < context.minTarget.daysOffset {
            return false
        } else if dayIndex == context.minTarget.daysOffset && start < context.minTarget.start {
            return false
        }
        let end = start + context.duration

        for props in (context.eventProperties.filter { $0.daysOffset == dayIndex}) {
            if start >= props.start && start < (props.start + props.duration) {
                return false
            }
            if end > props.start && end <= (props.start + props.duration) {
                return false
            }
            if props.start >= start && props.start < end {
                return false
            }
        }

        for block in (context.blocksForDayIndex[context.currentDayIndex + dayIndex] ?? []) {
            if start >= block.start && start < (block.start + block.duration) {
                return false
            }
            if end > block.start && end <= (block.start + block.duration) {
                return false
            }
            if block.start >= start && block.start < end {
                return false
            }
        }

        return true
    }
}
