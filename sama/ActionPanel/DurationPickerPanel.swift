//
//  DurationPickerPanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/12/21.
//

import UIKit

struct DurationOption {
    let text: String
    /// in minutes
    let duration: Int
}

class DurationPickerPanel: CalendarNavigationBlock, UITableViewDataSource, UITableViewDelegate {

    var optionPickHandler: ((DurationOption) -> Void)?

    private let options: [DurationOption] = [
        DurationOption(text: "15 minutes", duration: 15),
        DurationOption(text: "30 minutes", duration: 30),
        DurationOption(text: "45 minutes", duration: 45),
        DurationOption(text: "1 hour", duration: 60),
        DurationOption(text: "1 hour 30 minutes", duration: 90),
        DurationOption(text: "2 hours", duration: 120),
        DurationOption(text: "3 hours", duration: 180),
    ]

    override func didLoad() {
        let backBtn = addBackButton(action: #selector(onBackButton))
        addPanelContentTableView(withLeftView: backBtn, withDelegate: self)
    }

    @objc private func onBackButton() {
        navigation?.pop()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Meeting duration"
        default:
            cell.textLabel?.text = options[itemIndex(from: indexPath)].text
        }
        if indexPath.row > 0 {
            cell.textLabel?.textColor = .primary
            cell.textLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
        } else {
            cell.textLabel?.textColor = .neutral1
            cell.textLabel?.font = .brandedFont(ofSize: 20, weight: .regular)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row > 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row > 0 {
            optionPickHandler?(options[itemIndex(from: indexPath)])
            navigation?.pop()
        }
    }

    private func itemIndex(from indexPath: IndexPath) -> Int {
        return indexPath.row - 1
    }
}
