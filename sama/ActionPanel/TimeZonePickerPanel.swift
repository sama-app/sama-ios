//
//  TimeZonePickerPanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/9/21.
//

import UIKit

struct TimeZoneOption {
    let title: String
    let hoursFromGMT: Int

    fileprivate static func from(timeZone: TimeZone) -> TimeZoneOption {
        let id = timeZone.identifier
        let hoursFromGMT = Int(round(Double(TimeZone(identifier: id)!.secondsFromGMT()) / 3600))
        let sign = hoursFromGMT >= 0 ? "+" : ""
        return TimeZoneOption(
            title: "\(id) \(sign)\(hoursFromGMT)",
            hoursFromGMT: hoursFromGMT
        )
    }
}

class TimeZonePickerPanel: CalendarNavigationBlock, UITableViewDataSource, UITableViewDelegate {

    private let myTimezone = TimeZoneOption.from(timeZone: .current)
    private let allTimezones: [TimeZoneOption] = TimeZone.knownTimeZoneIdentifiers.map {
        TimeZoneOption.from(timeZone: TimeZone(identifier: $0)!)
    }.sorted { $0.hoursFromGMT < $1.hoursFromGMT }

    override func didLoad() {
        let backBtn = UIButton(type: .system)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.tintColor = .primary
        backBtn.setImage(UIImage(named: "arrow-back")!, for: .normal)
        backBtn.addTarget(self, action: #selector(onBackButton), for: .touchUpInside)
        addSubview(backBtn)
        NSLayoutConstraint.activate([
            backBtn.widthAnchor.constraint(equalToConstant: 44),
            backBtn.heightAnchor.constraint(equalToConstant: 44),
            backBtn.topAnchor.constraint(equalTo: topAnchor, constant: -4),
            backBtn.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -8)
        ])

        let contentView = UITableView()
        contentView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        contentView.dataSource = self
        contentView.separatorStyle = .none
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.showsVerticalScrollIndicator = false
        contentView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        contentView.contentOffset = CGPoint(x: 0, y: -8)
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 376),
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: -16),
            contentView.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor),
            trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
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
            cell.textLabel?.text = allTimezones[indexPath.row - 3].title
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
        return 38
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 0 && indexPath.row != 2
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {

        } else if indexPath.row > 2 {

        }
    }
}
