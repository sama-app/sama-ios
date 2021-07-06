//
//  BlockedTimesForDaysTransformer.swift
//  sama
//
//  Created by Viktoras Laukevičius on 7/6/21.
//

import Foundation

struct BlockedTimesForDaysTransformer {

    let currentDayIndex: Int
    let refDate: Date
    let calendar: Calendar

    private let apiDateF = ApiDateTimeFormatter()

    func transform(model: CalendarBlocks, in range: ClosedRange<Int>) -> [Int: [CalendarBlockedTime]] {
        var result: [Int: [CalendarBlockedTime]] = [:]
        for i in range {
            let date = self.calendar.date(byAdding: .day, value: i, to: self.refDate)!
            result[self.currentDayIndex + i] = self.filterAndTransform(
                blocks: model.blocks,
                for: date
            ).insetOverlapping()
        }
        return result
    }

    private func filterAndTransform(blocks: [CalendarBlock], for date: Date) -> [CalendarBlockedTime] {
        return blocks.compactMap { block in
            let parsedStart = self.apiDateF.date(from: block.startDateTime)
            let start = self.calendar.toTimeZone(date: parsedStart)
            if self.calendar.isDate(date, inSameDayAs: start) {
                let parsedEnd = self.apiDateF.date(from: block.endDateTime)
                let end = self.calendar.toTimeZone(date: parsedEnd)
                let duration = end.timeIntervalSince(start)
                return CalendarBlockedTime(
                    title: block.title,
                    start: Decimal(start.timeIntervalSince(self.calendar.startOfDay(for: start)) / 3600),
                    duration: Decimal(duration / 3600),
                    depth: 0
                )
            } else {
                return nil
            }
        }.sorted(by: { $0.start < $1.start || ($0.start == $1.start && $0.duration > $1.duration) })
    }
}


private extension Collection where Element == CalendarBlockedTime {
    func insetOverlapping() -> [CalendarBlockedTime] {
        var prev: [CalendarBlockedTime] = []
        return map { block in
            var depth = 0
            for prevBlock in prev {
                if block.start >= prevBlock.start && block.start <= (prevBlock.start + prevBlock.duration - 1) {
                    depth += 1
                }
            }
            var newBlock = block
            newBlock.depth = depth
            prev.append(block)
            return newBlock
        }
    }
}
