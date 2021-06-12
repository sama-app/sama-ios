//
//  FindTimePanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/9/21.
//

import UIKit

class FindTimePanel: CalendarNavigationBlock {
    override func didLoad() {
        let text = UILabel()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.text = "Find me a time for a 1 hour meeting with someone in my timezone"
        text.textColor = .neutral1
        text.font = .brandedFont(ofSize: 20, weight: .regular)
        text.numberOfLines = 0
        text.lineBreakMode = .byWordWrapping
        addSubview(text)
        NSLayoutConstraint.activate([
            text.topAnchor.constraint(equalTo: topAnchor),
            text.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: text.trailingAnchor),
        ])

        let actionBtn = UIButton(type: .system)
        actionBtn.setTitle("Find Time", for: .normal)
        actionBtn.translatesAutoresizingMaskIntoConstraints = false
        actionBtn.setTitleColor(.primary, for: .normal)
        actionBtn.titleLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
        actionBtn.addTarget(self, action: #selector(onFindTimeButton), for: .touchUpInside)
        addSubview(actionBtn)
        NSLayoutConstraint.activate([
            actionBtn.topAnchor.constraint(equalTo: text.bottomAnchor, constant: 16),
            actionBtn.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: actionBtn.trailingAnchor),
            bottomAnchor.constraint(equalTo: actionBtn.bottomAnchor)
        ])
    }

    @objc private func onFindTimeButton() {
        navigation?.pushBlock(TimeZonePickerPanel(), animated: true)
    }
}
