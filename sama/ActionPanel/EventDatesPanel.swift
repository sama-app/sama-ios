//
//  EventDatesPanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/14/21.
//

import UIKit

struct EventProperties {
    let start: Decimal
    let duration: Decimal
    let daysOffset: Int
}

enum EventDatesEvent {
    case reset
    case show([EventProperties])
}

struct EventSearchOptions {
    let timezone: TimeZoneOption
    let duration: DurationOption
}

class EventDatesPanel: CalendarNavigationBlock {

    var options: EventSearchOptions!
    var onEvent: ((EventDatesEvent) -> Void)?

    override func didLoad() {
        let backBtn = addBackButton(action: #selector(onBackButton))
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.topAnchor.constraint(equalTo: backBtn.bottomAnchor),
            trailingAnchor.constraint(equalTo: content.trailingAnchor),
            bottomAnchor.constraint(equalTo: content.bottomAnchor),
            content.heightAnchor.constraint(equalToConstant: 180)
        ])
        let duration = NSDecimalNumber(value: options.duration.duration).dividing(by: NSDecimalNumber(value: 60)).decimalValue
        let props = [
            EventProperties(start: 16, duration: duration, daysOffset: 0),
            EventProperties(start: 12.75, duration: duration, daysOffset: 1),
            EventProperties(start: 18.25, duration: duration, daysOffset: 1)
        ]
        onEvent?(.show(props))
    }

    @objc private func onBackButton() {
        onEvent?(.reset)
        navigation?.pop()
    }
}
