//
//  SuggestionsEditPanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/30/21.
//

import UIKit

class SuggestionsEditPanel: CalendarNavigationBlock {

    var coordinator: EventsCoordinator!

    private let inputField = LightTextField()
    private var backBtn: UIButton!
    private let actionBtn = MainActionButton.make(withTitle: "Rename meeting")

    private var enteredName: String {
        (inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    override func didLoad() {
        backBtn = addBackButton(title: "Cancel", action: #selector(onBackButton))

        let contentLabel = UILabel()
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.textColor = .secondary
        contentLabel.font = .systemFont(ofSize: 15, weight: .regular)
        contentLabel.text = "Title of a meeting that will be created after confirming time"
        addSubview(contentLabel)

        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.addTarget(self, action: #selector(onValueChange), for: .editingChanged)
        inputField.font = .brandedFont(ofSize: 20, weight: .regular)
        inputField.placeholder = coordinator.meetingTitle
        inputField.autocorrectionType = .no
        inputField.autocapitalizationType = .sentences
        addSubview(inputField)

        actionBtn.isEnabled = false
        actionBtn.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
        addSubview(actionBtn)

        contentLabel.pinLeadingAndTrailing(and: [
            contentLabel.topAnchor.constraint(equalTo: backBtn.bottomAnchor, constant: 8)
        ])
        inputField.pinLeadingAndTrailing(and: [
            inputField.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 8),
            inputField.heightAnchor.constraint(equalToConstant: 48)
        ])
        actionBtn.pinLeadingAndTrailing(bottom: 0, and: [
            actionBtn.heightAnchor.constraint(equalToConstant: 48),
            actionBtn.topAnchor.constraint(equalTo: inputField.bottomAnchor, constant: 16)
        ])
    }

    @objc private func onBackButton() {
        navigation?.pop()
    }

    @objc private func onValueChange() {
        actionBtn.isEnabled = !enteredName.isEmpty
    }

    @objc private func onConfirm() {
        backBtn.isEnabled = false
        inputField.isEnabled = false
        actionBtn.isEnabled = false

        let title = enteredName
        coordinator.updateMeetingTitle(with: title) { [weak self] in
            self?.backBtn.isEnabled = true
            self?.inputField.isEnabled = true
            self?.actionBtn.isEnabled = true

            switch $0 {
            case .success:
                self?.navigation?.pop()
                self?.navigation?.showToast(withMessage: "Meeting title changed to “\(title)”")
            case .failure:
                break
            }
        }
    }
}
