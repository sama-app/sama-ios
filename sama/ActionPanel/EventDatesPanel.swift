//
//  EventDatesPanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/14/21.
//

import UIKit

struct EventProperties: Equatable {
    var start: Decimal
    var duration: Decimal
    var daysOffset: Int
    let timezoneOffset: Int
}

enum EventDatesEvent {
    case reset
    case show([EventProperties])
}

struct EventSearchOptions {
    let usersTimezoneHoursFromGMT: Int
    let timezone: TimeZoneOption
    let duration: DurationOption
}

struct EventSearchRequestData: Encodable {
    let durationMinutes: Int
    let timeZone: String
    let suggestionSlotCount: Int
    let suggestionDayCount: Int
}

struct MeetingSuggestedSlot: Decodable {
    let startDateTime: String
    let endDateTime: String
}

struct MeetingInitiationResult: Decodable {
    let durationMinutes: Int
    let suggestedSlots: [MeetingSuggestedSlot]
}

struct MeetingInitiationRequest: ApiRequest {
    typealias T = EventSearchRequestData
    typealias U = MeetingInitiationResult
    let uri = "/meeting/initiate"
    let method: HttpMethod = .post
    var body: EventSearchRequestData
}

class EventDatesPanel: CalendarNavigationBlock {

    var options: EventSearchOptions!
    var api: Api!
    var coordinator: EventsCoordinator!

    private let apiDateF = ApiDateTimeFormatter()
    private let refDate = Date()
    private let calendar = Calendar.current

    private var actionButton: MainActionButton!
    private let titleLabel = UILabel()
    private let loader = UIActivityIndicatorView()
    private let content = UIStackView()

    override func didLoad() {
        let backBtn = addBackButton(action: #selector(onBackButton))

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .neutral1
        titleLabel.font = .brandedFont(ofSize: 20, weight: .regular)
        titleLabel.text = "Finding best slots..."
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 4)
        ])

        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        addSubview(wrapper)

        content.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .vertical
        wrapper.addSubview(content)

        NSLayoutConstraint.activate([
            wrapper.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -8),
            wrapper.topAnchor.constraint(equalTo: backBtn.bottomAnchor),
            trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            wrapper.heightAnchor.constraint(equalToConstant: 180),
            content.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            content.topAnchor.constraint(equalTo: wrapper.topAnchor),
            wrapper.trailingAnchor.constraint(equalTo: content.trailingAnchor),
        ])

        actionButton = addMainActionButton(title: "Copy Suggestions", action: #selector(onCopySuggestions), topAnchor: wrapper.bottomAnchor)
        actionButton.isHidden = true

        loader.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loader)
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        loader.startAnimating()

        coordinator.onChanges = { [weak self] in
            self?.reloadEventsList()
        }
        searchSlots()
    }

    private func searchSlots() {
        let timezoneOffset = self.options.timezone.hoursFromGMT - self.options.usersTimezoneHoursFromGMT

        let data = EventSearchRequestData(
            durationMinutes: options.duration.duration,
            timeZone: options.timezone.id,
            suggestionSlotCount: 3,
            suggestionDayCount: 4
        )
        let refStart = self.calendar.startOfDay(for: refDate)
        api.request(for: MeetingInitiationRequest(body: data)) {
            switch $0 {
            case let .success(result):
                let props = result.suggestedSlots.map { slot -> EventProperties in
                    let startDate = self.apiDateF.date(from: slot.startDateTime)
                    let endDate = self.apiDateF.date(from: slot.endDateTime)
                    let startComps = self.calendar.dateComponents([.day, .second], from: refStart, to: startDate)
                    let endComps = self.calendar.dateComponents([.day, .second], from: refStart, to: endDate)
                    let durationSecs = endComps.second! - startComps.second!
                    let duration = NSDecimalNumber(value: durationSecs).dividing(by: NSDecimalNumber(value: 3600))
                    return EventProperties(
                        start: 16,
                        duration: duration.decimalValue,
                        daysOffset: startComps.day!,
                        timezoneOffset: timezoneOffset
                    )
                }
//                let props = [
//                    EventProperties(start: 16, duration: duration, daysOffset: 0, timezoneOffset: timezoneOffset),
//                    EventProperties(start: 12.75, duration: duration, daysOffset: 1, timezoneOffset: timezoneOffset),
//                    EventProperties(start: 18.25, duration: duration, daysOffset: 1, timezoneOffset: timezoneOffset)
//                ]
                DispatchQueue.main.async {
                    self.actionButton.isHidden = false
                    self.titleLabel.text = "Here are your best slots:"
                    self.loader.stopAnimating()
                    self.loader.isHidden = true
                    self.coordinator.setupEventViews(props)
                }
            case .failure:
                self.onBackButton()
            }
        }
    }

    private func reloadEventsList() {
        let events = coordinator.eventProperties
        for subview in content.subviews {
            subview.removeFromSuperview()
        }
        let isRemovable = events.count > 1
        for props in events {
            let itemView = EventListItemView(props: props, isRemovable: isRemovable)
            itemView.handleRemove = { [weak self] in
                self?.coordinator.remove(props)
            }
            self.content.addArrangedSubview(itemView)
        }
    }

    @objc private func onBackButton() {
        coordinator.resetEventViews()
        navigation?.pop()
    }

    @objc private func onCopySuggestions() {

    }
}
