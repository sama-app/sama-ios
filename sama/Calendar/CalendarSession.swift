//
//  CalendarSession.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import Foundation

struct CalendarBlocksRequest: ApiRequest {
    typealias T = EmptyBody
    typealias U = CalendarBlocks
    let uri = "/calendar/blocks"
    let method: HttpMethod = .get
    let query: [URLQueryItem]
}

protocol CalendarContextProvider {
    var blocksForDayIndex: [Int: [CalendarBlockedTime]] { get }
}

final class CalendarSession: CalendarContextProvider {

    var reloadHandler: () -> Void = {}
    let currentDayIndex: Int
    let blockSize = 5

    private(set) var blocksForDayIndex: [Int: [CalendarBlockedTime]] = [:]

    let api: Api
    private let refDate = Date()
    private let calendar = Calendar.current

    private var isBlockBusy: [Int: Bool] = [:]

    private lazy var dateF: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "YYYY-MM-dd"
        return f
    }()

    private let apiDateF = ApiDateTimeFormatter()

    init(api: Api, currentDayIndex: Int) {
        self.api = api
        self.currentDayIndex = currentDayIndex
    }

    func loadInitial() {
        loadCalendar(blockIndices: (-1 ... 1))
    }

    func loadIfAvailableBlock(at index: Int) {
        if !(isBlockBusy[index] ?? false) {
            loadCalendar(blockIndices: (index ... index))
        }
    }

    private func loadCalendar(blockIndices: ClosedRange<Int>) {
        for idx in blockIndices {
            isBlockBusy[idx] = true
        }

        print("loadCalendar(\(blockIndices))")
        let daysBack = blockIndices.lowerBound * blockSize
        let daysForward = blockIndices.count * blockSize
        let start = calendar.date(byAdding: .day, value: daysBack, to: refDate)!
        let end = calendar.date(byAdding: .day, value: daysForward, to: start)!

        let req = CalendarBlocksRequest(query: [
            URLQueryItem(name: "startDate", value: dateF.string(from: start)),
            URLQueryItem(name: "endDate", value: dateF.string(from: end)),
            URLQueryItem(name: "timezone", value: "UTC")
        ])
        api.request(for: req) {
            switch $0 {
            case let .success(model):
                for i in (daysBack ... (daysBack + daysForward)) {
                    let date = self.calendar.date(byAdding: .day, value: i, to: self.refDate)!
                    let result = self.filterAndTransform(blocks: model.blocks, for: date).insetOverlapping()
                    self.blocksForDayIndex[self.currentDayIndex + i] = result
                }

                DispatchQueue.main.async {
                    self.reloadHandler()
                }
            case .failure:
                for idx in blockIndices {
                    self.isBlockBusy[idx] = false
                }
            }
        }
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
