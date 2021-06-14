//
//  EventDatesPanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/14/21.
//

import UIKit

enum EventDatesEvent {
    case reset
    case show
}

class EventDatesPanel: CalendarNavigationBlock {

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
        onEvent?(.show)
    }

    @objc private func onBackButton() {
        onEvent?(.reset)
        navigation?.pop()
    }
}
