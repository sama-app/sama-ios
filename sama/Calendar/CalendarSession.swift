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

    init(token: AuthToken, currentDayIndex: Int) {
        self.token = token
        self.currentDayIndex = currentDayIndex
    }

    func loadInitial() {
        let daysBack = -3
        let daysForward = 10
        let start = Calendar.current.date(byAdding: .day, value: daysBack, to: Date())!
        let end = Calendar.current.date(byAdding: .day, value: daysForward, to: Date())!
        let dateF = DateFormatter()
        dateF.dateFormat = "YYYY-MM-dd"
        var urlComps = URLComponents(string: "https://app.yoursama.com/api/calendar/blocks")!
        urlComps.queryItems = [
            URLQueryItem(name: "startDate", value: dateF.string(from: start)),
            URLQueryItem(name: "endDate", value: dateF.string(from: end)),
            URLQueryItem(name: "timezone", value: "UTC")
        ]
        var req = URLRequest(url: urlComps.url!)
        req.httpMethod = "get"
        req.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")

        let utcDateF = DateFormatter()
        utcDateF.dateFormat = "YYYY-MM-dd'T'HH:mm:ss"
        URLSession.shared.dataTask(with: req) { (data, resp, err) in
            print("/calendar/blocks HTTP status code: \((resp as? HTTPURLResponse)?.statusCode ?? -1)")
            if err == nil, let data = data, let model = try? JSONDecoder().decode(CalendarBlocks.self, from: data) {

                for i in (daysBack ..< daysForward) {
                    let date = Calendar.current.date(byAdding: .day, value: i, to: Date())!
                    var result: [CalendarBlockedTime] = []
                    for block in model.blocks {
                        let start = utcDateF.date(from: String(block.startDateTime.dropLast(6)))!
                        if Calendar.current.isDate(date, inSameDayAs: start) {
                            let end = utcDateF.date(from: String(block.endDateTime.dropLast(6)))!
                            let duration = end.timeIntervalSince(start)
                            result.append(
                                CalendarBlockedTime(
                                    title: block.title,
                                    start: Decimal(start.timeIntervalSince(Calendar.current.startOfDay(for: start)) / 3600),
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

    private func fetchCalendar() {

    }
}
