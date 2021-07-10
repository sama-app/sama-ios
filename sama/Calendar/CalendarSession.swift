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
    let logKey = "calendar/blocks"
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

    private let transformer: BlockedTimesForDaysTransformer

    init(api: Api, currentDayIndex: Int) {
        self.api = api
        self.currentDayIndex = currentDayIndex
        self.transformer = BlockedTimesForDaysTransformer(currentDayIndex: currentDayIndex, refDate: refDate, calendar: calendar)
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
                let daysRange = (daysBack ... (daysBack + daysForward))
                for (k, v) in self.transformer.transform(model: model, in: daysRange) {
                    self.blocksForDayIndex[k] = v
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
}
