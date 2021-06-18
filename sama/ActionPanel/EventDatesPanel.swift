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

struct EventSearchRequestData: Encodable {
    let durationMinutes: Int
    let timeZone: String
    let suggestionSlotCount: Int
    let suggestionDayCount: Int
}

class EventDatesPanel: CalendarNavigationBlock {

    var options: EventSearchOptions!
    var token: AuthToken!
    var onEvent: ((EventDatesEvent) -> Void)?

    private let loader = UIActivityIndicatorView()

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
                let props = [
                    EventProperties(start: 16, duration: duration, daysOffset: 0),
                    EventProperties(start: 12.75, duration: duration, daysOffset: 1),
                    EventProperties(start: 18.25, duration: duration, daysOffset: 1)
                ]
                DispatchQueue.main.async {
                    self.loader.stopAnimating()
                    self.loader.isHidden = true
                    self.onEvent?(.show(props))
                }
            } else {
                DispatchQueue.main.async {
                    self.onBackButton()
                }
            }
        }.resume()
    }

    @objc private func onBackButton() {
        onEvent?(.reset)
        navigation?.pop()
    }
}
