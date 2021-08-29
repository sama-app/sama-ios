//
//  InvitationCopiedPanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/28/21.
//

import UIKit

class InvitationCopiedPanel: CalendarNavigationBlock {

    var coordinator: EventsCoordinator!

    private let actionBtn = MainActionButton.make(withTitle: "Close")

    override func didLoad() {
        let backBtn = addBackButton(title: "Adjust Suggestions", action: #selector(onBack))

        let illustration = UIImageView(image: UIImage(named: "check-logo")!)
        illustration.translatesAutoresizingMaskIntoConstraints = false
        illustration.setContentHuggingPriority(.required, for: .horizontal)
        illustration.setContentHuggingPriority(.required, for: .vertical)

        let textsStack = UIStackView()
        textsStack.translatesAutoresizingMaskIntoConstraints = false
        textsStack.axis = .vertical

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .neutral1
        titleLabel.numberOfLines = 0
        titleLabel.font = .brandedFont(ofSize: 20, weight: .semibold)
        titleLabel.text = "Suggestions copied to clipboard."
        titleLabel.textAlignment = .center
        textsStack.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textColor = .neutral1
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = .brandedFont(ofSize: 20, weight: .regular)
        subtitleLabel.text = "You can now paste it in any app."
        subtitleLabel.textAlignment = .center
        textsStack.addArrangedSubview(subtitleLabel)

        actionBtn.addTarget(self, action: #selector(onClose), for: .touchUpInside)

        addSubview(illustration)
        addSubview(actionBtn)
        addSubview(textsStack)

        textsStack.pinLeadingAndTrailing()
        NSLayoutConstraint.activate([
            illustration.topAnchor.constraint(equalTo: backBtn.bottomAnchor, constant: 8),
            illustration.centerXAnchor.constraint(equalTo: centerXAnchor),
            textsStack.topAnchor.constraint(equalTo: illustration.bottomAnchor, constant: 16),
            actionBtn.topAnchor.constraint(equalTo: textsStack.bottomAnchor, constant: 16),
            actionBtn.heightAnchor.constraint(equalToConstant: 48),
            actionBtn.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: actionBtn.trailingAnchor),
            bottomAnchor.constraint(equalTo: actionBtn.bottomAnchor)
        ])
    }

    @objc private func onBack() {
        coordinator.lockPick(false)
        navigation?.pop()
    }

    @objc private func onClose() {
        coordinator.resetEventViews()
        navigation?.popToRoot()
    }
}
