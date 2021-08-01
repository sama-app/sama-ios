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
}

struct MeetingSuggestedSlot: Decodable {
    let startDateTime: String
    let endDateTime: String
}

struct MeetingInitiationResult: Decodable {
    let meetingIntentCode: String
    let durationMinutes: Int
    let suggestedSlots: [MeetingSuggestedSlot]
}

struct MeetingInitiationRequest: ApiRequest {
    typealias T = EventSearchRequestData
    typealias U = MeetingInitiationResult
    let uri = "/meeting/initiate"
    let logKey = "/meeting/initiate"
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
        let data = EventSearchRequestData(
            durationMinutes: options.duration.duration,
            timeZone: options.timezone.id,
            suggestionSlotCount: 3
        )
        api.request(for: MeetingInitiationRequest(body: data)) {
            switch $0 {
            case let .success(result):
                self.setupInitiation(with: result)
            case .failure:
                self.onBackButton()
            }
        }
    }

    private func setupInitiation(with result: MeetingInitiationResult) {
        let timezoneOffset = options.timezone.hoursFromGMT - options.usersTimezoneHoursFromGMT
        let refStart = calendar.startOfDay(for: refDate)

        let props = result.suggestedSlots.map { slot -> EventProperties in
            let parsedStart = self.apiDateF.date(from: slot.startDateTime)
            let startDate = self.calendar.toTimeZone(date: parsedStart)
            let parsedEnd = self.apiDateF.date(from: slot.endDateTime)
            let endDate = self.calendar.toTimeZone(date: parsedEnd)
            let startComps = self.calendar.dateComponents([.day, .second], from: refStart, to: startDate)
            let durationComps = self.calendar.dateComponents([.second], from: startDate, to: endDate)
            let start = NSDecimalNumber(value: startComps.second!).dividing(by: NSDecimalNumber(value: 3600))
            let duration = NSDecimalNumber(value: durationComps.second!).dividing(by: NSDecimalNumber(value: 3600))
            return EventProperties(
                start: start.decimalValue,
                duration: duration.decimalValue,
                daysOffset: startComps.day!,
                timezoneOffset: timezoneOffset
            )
        }.sorted(by: {
            switch true {
            case $0.daysOffset < $1.daysOffset:
                return true
            case $0.daysOffset == $1.daysOffset:
                return $0.start < $1.start
            default:
                return false
            }
        })

        self.actionButton.isHidden = false
        self.titleLabel.text = "Here are your best slots:"
        self.loader.stopAnimating()
        self.loader.isHidden = true
        self.coordinator.setup(
            withCode: result.meetingIntentCode,
            durationMins: options.duration.duration,
            properties: props
        )
    }

    private func reloadEventsList() {
        let events = coordinator.eventProperties
        for subview in content.subviews {
            subview.removeFromSuperview()
        }
        let isRemovable = events.count > 1
        let isButtonVisible = events.count < 3
        for props in events {
            let itemView = EventListItemView(props: props, isRemovable: isRemovable)
            itemView.handleRemove = { [weak self] in
                Sama.bi.track(event: "deleteslot")

                self?.coordinator.remove(props)
            }
            self.content.addArrangedSubview(itemView)
        }
        if isButtonVisible {
            let actionBtn = UIButton(type: .system)
            actionBtn.translatesAutoresizingMaskIntoConstraints = false
            actionBtn.heightAnchor.constraint(equalToConstant: 60).isActive = true
            actionBtn.setTitle("Add another slot", for: .normal)
            actionBtn.titleLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
            actionBtn.setImage(UIImage(named: "plus")!, for: .normal)
            actionBtn.tintColor = .primary
            actionBtn.contentHorizontalAlignment = .leading
            actionBtn.contentVerticalAlignment = .center
            actionBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
            actionBtn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
            actionBtn.addTarget(self, action: #selector(onAddNewSuggestion), for: .touchUpInside)

            self.content.addArrangedSubview(actionBtn)
        }
    }

    @objc private func onBackButton() {
        coordinator.resetEventViews()
        navigation?.pop()
    }

    @objc private func onAddNewSuggestion() {
        Sama.bi.track(event: "addslot")

        coordinator.addClosestToCenter()
    }

    @objc private func onCopySuggestions() {
        Sama.bi.track(event: "copy")

        actionButton.isEnabled = false
        coordinator.proposeSlots { [weak self] in
            guard let self = self else { return }
            self.actionButton.isEnabled = true

            switch $0 {
            case let .success(result):
                UIPasteboard.general.string = result.shareableMessage
                self.navigation?.showToast(withMessage: "Copied to clipboard.")
            case .failure:
                break
            }
        }
    }
}
