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

        let editBtn = UIButton(type: .system)
        editBtn.setTitle("Edit meeting title", for: .normal)
        editBtn.translatesAutoresizingMaskIntoConstraints = false
        editBtn.setTitleColor(.primary, for: .normal)
        editBtn.titleLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
        editBtn.addTarget(self, action: #selector(onEdit), for: .touchUpInside)

        actionBtn.addTarget(self, action: #selector(onClose), for: .touchUpInside)

        addSubview(illustration)
        addSubview(editBtn)
        addSubview(actionBtn)
        addSubview(textsStack)

        textsStack.pinLeadingAndTrailing()
        editBtn.pinLeadingAndTrailing()
        actionBtn.pinLeadingAndTrailing()
        NSLayoutConstraint.activate([
            illustration.topAnchor.constraint(equalTo: backBtn.bottomAnchor, constant: 8),
            illustration.centerXAnchor.constraint(equalTo: centerXAnchor),
            textsStack.topAnchor.constraint(equalTo: illustration.bottomAnchor, constant: 16),
            editBtn.topAnchor.constraint(equalTo: textsStack.bottomAnchor, constant: 16),
            editBtn.heightAnchor.constraint(equalToConstant: 48),
            actionBtn.topAnchor.constraint(equalTo: editBtn.bottomAnchor, constant: 8),
            actionBtn.heightAnchor.constraint(equalToConstant: 48),
            bottomAnchor.constraint(equalTo: actionBtn.bottomAnchor)
        ])
    }

    @objc private func onEdit() {
        let panel = SuggestionsEditPanel()
        panel.coordinator = coordinator
        navigation?.pushBlock(panel, animated: true)
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
