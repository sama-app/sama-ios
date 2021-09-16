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
    let logKey = "/calendar/blocks"
    let method: HttpMethod = .get
    let query: [URLQueryItem]
}

protocol CalendarContextProvider {
    var blocksForDayIndex: [Int: [CalendarBlockedTime]] { get }
}

struct RegisterDeviceRequest: ApiRequest {
    typealias U = EmptyBody
    let uri = "/user/me/register-device"
    let logKey = "/user/me/register-device"
    let method: HttpMethod = .post
    let body: RegisterDeviceData
}

struct UpdateTimeZoneBody: Encodable {
    let timeZone: String
}

struct UpdateTimeZoneRequest: ApiRequest {
    typealias U = EmptyBody
    let uri = "/user/me/update-time-zone"
    let logKey = "/user/me/update-time-zone"
    let method: HttpMethod = .post
    let body: UpdateTimeZoneBody
}

final class CalendarSession: CalendarContextProvider {

    var reloadHandler: () -> Void = {}
    let currentDayIndex: Int
    let blockSize = 5

    private(set) var blocksForDayIndex: [Int: [CalendarBlockedTime]] = [:]

    let api: Api
    let refDate = Date()
    private let calendar = Calendar.current

    private var isBlockBusy: [Int: Bool] = [:]

    private lazy var dateF: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "YYYY-MM-dd"
        return f
    }()

    private let transformer: BlockedTimesForDaysTransformer

    private var lastTimeZoneUpdate = Date(timeIntervalSince1970: 0)

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

    func invalidateAndLoadBlocks(_ indices: ClosedRange<Int>) {
        blocksForDayIndex = [:]
        isBlockBusy = [:]

        loadCalendar(blockIndices: indices)
    }

    func setupNotificationsTokenObserver() {
        RemoteNotificationsTokenSync.shared.observer = { [weak self] data in
            self?.api.request(for: RegisterDeviceRequest(body: data)) { _ in }
        }
        RemoteNotificationsTokenSync.shared.syncToken()
    }

    private func updateTimeZoneIfNeeded() {
        let timestamp = Date()
        guard timestamp.timeIntervalSince(lastTimeZoneUpdate) > 24 * 60 * 60 else { return }
        lastTimeZoneUpdate = timestamp

        let req = UpdateTimeZoneRequest(body: UpdateTimeZoneBody(timeZone: TimeZone.current.identifier))
        api.request(for: req) { _ in }
    }

    private func loadCalendar(blockIndices: ClosedRange<Int>) {
        updateTimeZoneIfNeeded()

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
