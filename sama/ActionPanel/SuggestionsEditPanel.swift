//
//  SuggestionsEditPanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/30/21.
//

import UIKit

class SuggestionsEditPanel: CalendarNavigationBlock {

    var coordinator: EventsCoordinator!

    private let inputField = LightTextField().forAutoLayout()
    private let blockingToggle = UISwitch().forAutoLayout()
    private var backBtn: UIButton!
    private let actionBtn = MainActionButton.make(withTitle: "Update meeting settings")

    private var enteredName: String {
        (inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    override func didLoad() {
        backBtn = addBackButton(title: "Cancel", action: #selector(onBackButton))

        let contentLabel = UILabel().forAutoLayout()
        contentLabel.makeMultiline()
        contentLabel.textColor = .secondary
        contentLabel.font = .systemFont(ofSize: 15, weight: .regular)
        contentLabel.text = "Title of a meeting that will be created after confirming time"
        addSubview(contentLabel)

        inputField.font = .brandedFont(ofSize: 20, weight: .regular)
        inputField.placeholder = coordinator.meetingSettings.title
        inputField.autocorrectionType = .no
        inputField.autocapitalizationType = .sentences
        addSubview(inputField)

        let blockTimesContainer = setupBlockTimesContainer()
        addSubview(blockTimesContainer)

        actionBtn.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
        addSubview(actionBtn)

        contentLabel.pinLeadingAndTrailing(and: [
            contentLabel.topAnchor.constraint(equalTo: backBtn.bottomAnchor, constant: 8)
        ])
        inputField.pinLeadingAndTrailing(and: [
            inputField.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 8),
            inputField.heightAnchor.constraint(equalToConstant: 48)
        ])
        blockTimesContainer.pinLeadingAndTrailing(and: [
            blockTimesContainer.topAnchor.constraint(equalTo: inputField.bottomAnchor, constant: 8)
        ])
        actionBtn.pinLeadingAndTrailing(bottom: 0, and: [
            actionBtn.heightAnchor.constraint(equalToConstant: 48),
            actionBtn.topAnchor.constraint(equalTo: blockTimesContainer.bottomAnchor, constant: 16)
        ])
    }

    private func setupBlockTimesContainer() -> UIView {
        let container = UIView().forAutoLayout()

        let label = UILabel().forAutoLayout()
        label.textColor = .secondary
        label.font = .brandedFont(ofSize: 20, weight: .regular)
        label.text = "Block times for me"

        blockingToggle.onTintColor = .primary
        blockingToggle.isOn = coordinator.meetingSettings.isBlockingEnabled

        container.addSubview(label)
        container.addSubview(blockingToggle)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 56),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.trailingAnchor.constraint(equalTo: blockingToggle.trailingAnchor),
            blockingToggle.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: blockingToggle.leadingAnchor)
        ])

        return container
    }

    @objc private func onBackButton() {
        navigation?.pop()
    }

    @objc private func onConfirm() {
        Sama.bi.track(event: "changetitle")

        backBtn.isEnabled = false
        inputField.isEnabled = false
        actionBtn.isEnabled = false

        let title = !enteredName.isEmpty ? enteredName : coordinator.meetingSettings.title
        coordinator.meetingSettings = MeetingSettings(
            title: title,
            isBlockingEnabled: blockingToggle.isOn
        )
        navigation?.pop()
    }
}
