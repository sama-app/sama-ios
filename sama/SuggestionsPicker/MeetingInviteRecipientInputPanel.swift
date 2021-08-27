//
//  MeetingInviteRecipientInputPanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/19/21.
//

import UIKit

class MeetingInviteRecipientInputPanel: CalendarNavigationBlock {

    var coordinator: SuggestionsViewCoordinator!

    private let inputField = LightTextField()
    private let actionBtn = MainActionButton.make(withTitle: "Send invite")

    private var enteredEmail: String {
        (inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    override func didLoad() {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .secondary
        titleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        titleLabel.text = "Enter the email of the other person"
        addSubview(titleLabel)

        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.addTarget(self, action: #selector(onEmailChange), for: .editingChanged)
        inputField.placeholder = "other@email.com"
        inputField.keyboardType = .emailAddress
        inputField.autocorrectionType = .no
        inputField.autocapitalizationType = .none
        addSubview(inputField)

        actionBtn.isEnabled = false
        actionBtn.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
        addSubview(actionBtn)

        titleLabel.pinLeadingAndTrailing(top: 0)
        inputField.pinLeadingAndTrailing(and: [
            inputField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            inputField.heightAnchor.constraint(equalToConstant: 48)
        ])
        actionBtn.pinLeadingAndTrailing(bottom: 0, and: [
            actionBtn.heightAnchor.constraint(equalToConstant: 48),
            actionBtn.topAnchor.constraint(equalTo: inputField.bottomAnchor, constant: 16)
        ])
    }

    @objc private func onEmailChange() {
        actionBtn.isEnabled = !enteredEmail.isEmpty
    }

    @objc private func onConfirm() {
        inputField.isEnabled = false
        actionBtn.isEnabled = false

        coordinator.confirm(recipientEmail: enteredEmail) { [weak self] err in
            self?.inputField.isEnabled = true
            self?.actionBtn.isEnabled = true

            if err != nil {

            } else {
                self?.coordinator.reset()
            }
        }
    }
}
