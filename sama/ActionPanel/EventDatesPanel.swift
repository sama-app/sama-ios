//
//  EventDatesPanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/14/21.
//

import UIKit

struct EventProperties: Equatable {
    let start: Decimal
    let duration: Decimal
    let daysOffset: Int
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

class EventDatesPanel: CalendarNavigationBlock {

    var options: EventSearchOptions!
    var token: AuthToken!
    var coordinator: EventsCoordinator!

    private var actionButton: MainActionButton!
    private let titleLabel = UILabel()
    private let loader = UIActivityIndicatorView()
    private let content = UIStackView()

    private var events: [EventProperties] = []

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

        searchSlots()
    }

    private func searchSlots() {
        let data = EventSearchRequestData(
            durationMinutes: options.duration.duration,
            timeZone: options.timezone.id,
            suggestionSlotCount: 3,
            suggestionDayCount: 4
        )

        let urlComps = URLComponents(string: "https://app.yoursama.com/api/meeting/initiate")!
        var req = URLRequest(url: urlComps.url!)
        req.httpMethod = "post"
        req.allHTTPHeaderFields = [
            "Content-Type": "application/json"
        ]
        req.httpBody = try? JSONEncoder().encode(data)
        req.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: req) { (data, resp, err) in
            print("/meeting/initiate HTTP status code: \((resp as? HTTPURLResponse)?.statusCode ?? -1)")

            if err == nil && (resp as? HTTPURLResponse)?.statusCode == 200 {
                let duration = NSDecimalNumber(value: self.options.duration.duration).dividing(by: NSDecimalNumber(value: 60)).decimalValue
                let timezoneOffset = self.options.timezone.hoursFromGMT - self.options.usersTimezoneHoursFromGMT
                let props = [
                    EventProperties(start: 16, duration: duration, daysOffset: 0, timezoneOffset: timezoneOffset),
                    EventProperties(start: 12.75, duration: duration, daysOffset: 1, timezoneOffset: timezoneOffset),
                    EventProperties(start: 18.25, duration: duration, daysOffset: 1, timezoneOffset: timezoneOffset)
                ]
                DispatchQueue.main.async {
                    self.displayEventsList(props)
                    self.actionButton.isHidden = false
                    self.titleLabel.text = "Here are your best slots:"
                    self.loader.stopAnimating()
                    self.loader.isHidden = true
                    self.coordinator.setupEventViews(props)
                }
            } else {
                DispatchQueue.main.async {
                    self.onBackButton()
                }
            }
        }.resume()
    }

    private func displayEventsList(_ events: [EventProperties]) {
        self.events = events

        for subview in content.subviews {
            subview.removeFromSuperview()
        }
        let isRemovable = events.count > 1
        for props in events {
            let itemView = EventListItemView(props: props, isRemovable: isRemovable)
            itemView.handleRemove = { [weak self] in
                guard let self = self else { return }
                self.coordinator.remove(props)
                self.displayEventsList(self.coordinator.eventProperties)
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
