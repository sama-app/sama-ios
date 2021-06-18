//
//  TimeZonePickerPanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/9/21.
//

import UIKit

struct TimeZoneOption {
    let id: String
    let title: String
    let hoursFromGMT: Int
    let isUsersTimezone: Bool

    static func from(timeZone: TimeZone, usersTimezone: TimeZone) -> TimeZoneOption {
        let id = timeZone.identifier
        let hoursFromGMT = Int(round(Double(TimeZone(identifier: id)!.secondsFromGMT()) / 3600))
        let sign = hoursFromGMT >= 0 ? "+" : ""
        return TimeZoneOption(
            id: id,
            title: "\(id) \(sign)\(hoursFromGMT)",
            hoursFromGMT: hoursFromGMT,
            isUsersTimezone: timeZone.secondsFromGMT() == usersTimezone.secondsFromGMT()
        )
    }
}

class TimeZonePickerPanel: CalendarNavigationBlock, UITableViewDataSource, UITableViewDelegate {

    var optionPickHandler: ((TimeZoneOption) -> Void)?

    private let myTimezone = TimeZoneOption.from(timeZone: .current, usersTimezone: .current)
    private let allTimezones: [TimeZoneOption] = TimeZone.knownTimeZoneIdentifiers.map {
        TimeZoneOption.from(timeZone: TimeZone(identifier: $0)!, usersTimezone: .current)
    }.sorted { $0.hoursFromGMT < $1.hoursFromGMT }

    override func didLoad() {
        let backBtn = addBackButton(action: #selector(onBackButton))
        addPanelContentTableView(withLeftView: backBtn, withDelegate: self)
    }

    @objc private func onBackButton() {
        navigation?.pop()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allTimezones.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "My Timezone"
        case 1:
            cell.textLabel?.text = myTimezone.title
        case 2:
            cell.textLabel?.text = "Recipient Timezone"
        default:
            cell.textLabel?.text = timezoneFromAll(forRow: indexPath.row).title
        }

        if indexPath.row == 0 || indexPath.row == 2 {
            cell.textLabel?.textColor = .neutral1
            cell.textLabel?.font = .brandedFont(ofSize: 20, weight: .regular)
        } else {
            cell.textLabel?.textColor = .primary
            cell.textLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 0 && indexPath.row != 2
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            optionPickHandler?(myTimezone)
        } else if indexPath.row > 2 {
            optionPickHandler?(timezoneFromAll(forRow: indexPath.row))
        }
        navigation?.pop()
    }

    private func timezoneFromAll(forRow row: Int) -> TimeZoneOption {
        return allTimezones[row - 3]
    }
}
