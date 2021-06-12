//
//  TimeZonePickerPanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/9/21.
//

import UIKit

class TimeZonePickerPanel: CalendarNavigationBlock {
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

        let contentView = UIScrollView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 376),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor),
            trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    @objc private func onBackButton() {
        navigation?.pop()
    }
}
