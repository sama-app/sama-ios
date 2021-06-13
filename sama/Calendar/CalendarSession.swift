//
//  CalendarSession.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import Foundation

final class CalendarSession {

    var reloadHandler: () -> Void = {}
    let currentDayIndex: Int
    let blockSize = 5

    private(set) var blocksForDayIndex: [Int: [CalendarBlockedTime]] = [:]

    private let token: AuthToken
    private let refDate = Date()
    private let calendar = Calendar.current

    private var isBlockBusy: [Int: Bool] = [:]

    private lazy var dateF: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "YYYY-MM-dd"
        return f
    }()

    private lazy var utcDateF: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "YYYY-MM-dd'T'HH:mm:ss"
        return f
    }()

    init(token: AuthToken, currentDayIndex: Int) {
        self.token = token
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

        var urlComps = URLComponents(string: "https://app.yoursama.com/api/calendar/blocks")!
        urlComps.queryItems = [
            URLQueryItem(name: "startDate", value: dateF.string(from: start)),
            URLQueryItem(name: "endDate", value: dateF.string(from: end)),
            URLQueryItem(name: "timezone", value: "UTC")
        ]
        var req = URLRequest(url: urlComps.url!)
        req.httpMethod = "get"
        req.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: req) { (data, resp, err) in
            print("/calendar/blocks HTTP status code: \((resp as? HTTPURLResponse)?.statusCode ?? -1)")
            if err == nil, let data = data, let model = try? JSONDecoder().decode(CalendarBlocks.self, from: data) {

                for i in (daysBack ... (daysBack + daysForward)) {
                    let date = self.calendar.date(byAdding: .day, value: i, to: self.refDate)!
                    let result = self.filterAndTransform(blocks: model.blocks, for: date).insetOverlapping()
                    self.blocksForDayIndex[self.currentDayIndex + i] = result
                }

                DispatchQueue.main.async {
                    self.reloadHandler()
                }
            } else {
                for idx in blockIndices {
                    self.isBlockBusy[idx] = false
                }
            }
        }.resume()
    }

    private func filterAndTransform(blocks: [CalendarBlock], for date: Date) -> [CalendarBlockedTime] {
        return blocks.compactMap { block in
            let start = self.utcDateF.date(from: String(block.startDateTime.dropLast(6)))!
            if self.calendar.isDate(date, inSameDayAs: start) {
                let end = self.utcDateF.date(from: String(block.endDateTime.dropLast(6)))!
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
