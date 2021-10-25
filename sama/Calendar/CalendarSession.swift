//
//  CalendarSession.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import Foundation

struct CalendarEventsRequest: ApiRequest {
    typealias T = EmptyBody
    typealias U = CalendarBlocks
    let uri = "/calendar/events"
    let logKey = "/calendar/events"
    let method: HttpMethod = .get
    let query: [URLQueryItem]
}

struct CalendarMetadata: Decodable, Equatable {
    let accountId: String
    let calendarId: String
    let colour: String?
}

struct CalendarsResponse: Decodable {
    let calendars: [CalendarMetadata]
}

struct AccountCalendarId: Hashable {
    let accountId: String
    let calendarId: String
}

struct CalendarsRequest: ApiRequest {
    typealias T = EmptyBody
    typealias U = CalendarsResponse
    let uri = "/calendar/calendars"
    let logKey = "/calendar/calendars"
    let method: HttpMethod = .get
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

struct DomainUser: Decodable {
    let userId: String
}

struct DomainUserSettings: Decodable {
    struct Marketing: Decodable {
        let newsletterSubscriptionEnabled: Bool?
    }

    let marketingPreferences: Marketing
}

struct UserDetailsRequest: ApiRequest {
    typealias U = DomainUser
    let uri = "/user/me/"
    let logKey = "/user/me/"
    let method: HttpMethod = .get
}

struct UserSettingsRequest: ApiRequest {
    typealias U = DomainUserSettings
    let uri = "/user/me/settings"
    let logKey = "/user/me/settings"
    let method: HttpMethod = .get
}

enum DataReadiness<T>: Equatable where T: Equatable {
    case idle
    case failed
    case loading
    case ready(T)

    var isDisplayable: Bool {
        switch self {
        case .idle, .loading: return false
        case .failed, .ready: return true
        }
    }
}

struct CalendarUiMetadata: Equatable {
    let colours: [AccountCalendarId: Int?]
}

final class CalendarSession: CalendarContextProvider {

    var reloadHandler: () -> Void = {}
    var userIdUpdateHandler: ((String) -> Void)?
    var presentError: (ApiError) -> Void = { _ in }
    let currentDayIndex: Int
    let blockSize = 5

    private(set) var blocksForDayIndex: [Int: [CalendarBlockedTime]] = [:]
    private var queuedBlocksForDayIndex: [Int: [CalendarBlockedTime]] = [:]

    let api: Api
    let refDate = CalendarDateUtils.shared.uiRefDate
    private let calendar = Calendar.current

    private var isBlockBusy: [Int: Bool] = [:]
    private var calendarMetadataReadiness: DataReadiness<CalendarUiMetadata> = .idle

    private lazy var dateF: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "YYYY-MM-dd"
        return f
    }()

    private let transformer: BlockedTimesForDaysTransformer

    private var lastTimeZoneUpdate = Date(timeIntervalSince1970: 0)
    private var isUserUpdated = false

    init(api: Api, currentDayIndex: Int) {
        self.api = api
        self.currentDayIndex = currentDayIndex
        self.transformer = BlockedTimesForDaysTransformer(currentDayIndex: currentDayIndex, refDate: refDate, calendar: calendar)
    }

    func firstFocusDayIndex(centerOffset: Int) -> Int {
        let weekday = Calendar.current.component(.weekday, from: CalendarDateUtils.shared.dateNow)
        if weekday == 1 || weekday == 7 {
            return currentDayIndex + centerOffset
        } else {
            // 2 monday num
            return currentDayIndex - (weekday - 2)
        }
    }

    func focusDay(isSingleDay: Bool, visibleColumnIndices: [Int]) -> Int {
        let todayIndex = 5000
        if isSingleDay {
            return visibleColumnIndices.contains(todayIndex) ? todayIndex : (visibleColumnIndices.first ?? todayIndex)
        } else {
            return visibleColumnIndices.first ?? todayIndex
        }
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
        let timestamp = CalendarDateUtils.shared.dateNow
        guard timestamp.timeIntervalSince(lastTimeZoneUpdate) > 24 * 60 * 60 else { return }
        lastTimeZoneUpdate = timestamp

        let req = UpdateTimeZoneRequest(body: UpdateTimeZoneBody(timeZone: TimeZone.current.identifier))
        api.request(for: req) { _ in }
    }

    private func updateUserIfNeeded() {
        guard !isUserUpdated else { return }
        isUserUpdated = true

        api.request(for: UserDetailsRequest()) {
            switch $0 {
            case let .success(user):
                self.userIdUpdateHandler?(user.userId)
            case .failure:
                self.isUserUpdated = false
            }
        }
    }

    private func loadCalendarsMetadataIfNeeded() {
        guard calendarMetadataReadiness == .idle || calendarMetadataReadiness == .failed else { return }

        calendarMetadataReadiness = .loading

        api.request(for: CalendarsRequest()) {
            switch $0 {
            case let .success(response):
                var result: [AccountCalendarId: Int] = [:]

                let colourBase = 0x6B5844
                let redBase = Double((colourBase >> 16) & 0xFF)
                let greenBase = Double((colourBase >> 8) & 0xFF)
                let blueBase = Double(colourBase & 0xFF)

                for calendar in response.calendars {
                    let id = AccountCalendarId(
                        accountId: calendar.accountId,
                        calendarId: calendar.calendarId
                    )
                    let externalColour = 0x7886CB
                    let externalColourRed = Double((externalColour >> 16) & 0xFF)
                    let externalColourGreen = Double((externalColour >> 8) & 0xFF)
                    let externalColourBlue = Double(externalColour & 0xFF)

                    let red = Int((redBase + externalColourRed) / 2)
                    let green = Int((greenBase + externalColourGreen) / 2)
                    let blue = Int((blueBase + externalColourBlue) / 2)

                    let colour = (red << 16) + (green << 8) + blue

                    result[id] = colour
//                    if let colour = calendar.colour {
//                        result[id] = 0x0
//                    } else {
//                        result[id] = nil
//                    }
                }

                self.calendarMetadataReadiness = .ready(CalendarUiMetadata(colours: result))
            case .failure:
                self.calendarMetadataReadiness = .failed
            }
            self.enrichBlocksWithContextAndReload(keys: nil)
        }
    }

    private func enrichBlocksWithContextAndReload(keys: [Int]?) {
        switch calendarMetadataReadiness {
        case let .ready(metadata):
            for key in (keys ?? Array(queuedBlocksForDayIndex.keys)) {
                blocksForDayIndex[key] = queuedBlocksForDayIndex[key]?.map {
                    var r = $0
                    r.colour = metadata.colours[$0.id] ?? nil
                    return r
                }
            }
            self.reloadHandler()
        default:
            self.reloadHandler()
        }
    }

    private func loadCalendar(blockIndices: ClosedRange<Int>) {
        updateTimeZoneIfNeeded()
        updateUserIfNeeded()
        loadCalendarsMetadataIfNeeded()

        for idx in blockIndices {
            isBlockBusy[idx] = true
        }

        print("loadCalendar(\(blockIndices))")
        let daysBack = blockIndices.lowerBound * blockSize
        let daysForward = blockIndices.count * blockSize
        let start = calendar.date(byAdding: .day, value: daysBack, to: refDate)!
        let end = calendar.date(byAdding: .day, value: daysForward, to: start)!

        let req = CalendarEventsRequest(query: [
            URLQueryItem(name: "startDate", value: dateF.string(from: start)),
            URLQueryItem(name: "endDate", value: dateF.string(from: end)),
            URLQueryItem(name: "timezone", value: "UTC")
        ])
        api.request(for: req) {
            switch $0 {
            case let .success(model):
                let daysRange = (daysBack ... (daysBack + daysForward))
                let result = self.transformer.transform(model: model, in: daysRange)
                let touchedKeys = Array(result.keys)
                for (k, v) in result {
                    self.queuedBlocksForDayIndex[k] = v
                }

                DispatchQueue.main.async {
                    if self.calendarMetadataReadiness.isDisplayable {
                        self.enrichBlocksWithContextAndReload(keys: touchedKeys)
                    }
                }
            case let .failure(err):
                for idx in blockIndices {
                    self.isBlockBusy[idx] = false
                }
                self.presentError(err)
            }
        }
    }
}
