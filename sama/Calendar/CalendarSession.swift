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

    private(set) var blocksForDayIndex: [Int: [CalendarBlockedTime]] = [:]

    private let token: AuthToken
    private let blockSize = 5
    private let refDate = Date()
    private let calendar = Calendar.current

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

    private func loadCalendar(blockIndices: ClosedRange<Int>) {
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
                    var result: [CalendarBlockedTime] = []
                    for block in model.blocks {
                        let start = self.utcDateF.date(from: String(block.startDateTime.dropLast(6)))!
                        if self.calendar.isDate(date, inSameDayAs: start) {
                            let end = self.utcDateF.date(from: String(block.endDateTime.dropLast(6)))!
                            let duration = end.timeIntervalSince(start)
                            result.append(
                                CalendarBlockedTime(
                                    title: block.title,
                                    start: Decimal(start.timeIntervalSince(self.calendar.startOfDay(for: start)) / 3600),
                                    duration: Decimal(duration / 3600)
                                )
                            )
                        }
                    }
                    self.blocksForDayIndex[self.currentDayIndex + i] = result
                }

                DispatchQueue.main.async {
                    self.reloadHandler()
                }
            }
        }.resume()
    }
}
