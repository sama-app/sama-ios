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
        let backBtn = addBackButton(action: #selector(onBackButton))

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .primary
        titleLabel.font = .brandedFont(ofSize: 20, weight: .semibold)
        titleLabel.text = "Change selection"
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 4)
        ])

        let contentLabel = UILabel()
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.textColor = .secondary
        contentLabel.font = .systemFont(ofSize: 15, weight: .regular)
        contentLabel.text = "Enter the email of the other person"
        addSubview(contentLabel)

        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.addTarget(self, action: #selector(onEmailChange), for: .editingChanged)
        inputField.font = .brandedFont(ofSize: 20, weight: .regular)
        inputField.placeholder = "other@email.com"
        inputField.keyboardType = .emailAddress
        inputField.autocorrectionType = .no
        inputField.autocapitalizationType = .none
        addSubview(inputField)

        actionBtn.isEnabled = false
        actionBtn.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
        addSubview(actionBtn)

        contentLabel.pinLeadingAndTrailing(and: [
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16)
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
        coordinator.lockPick(false)
        navigation?.pop()
    }

    @objc private func onEmailChange() {
        actionBtn.isEnabled = !enteredEmail.isEmpty
    }

    @objc private func onConfirm() {
        inputField.isEnabled = false
        actionBtn.isEnabled = false

        coordinator.confirm(recipientEmail: enteredEmail) { [weak self] in
            guard let self = self else { return }

            self.inputField.isEnabled = true
            self.actionBtn.isEnabled = true

            switch $0 {
            case let .success(result):
                let panel = TimeConfirmedPanel()
                panel.coordinator = self.coordinator
                panel.model = result
                self.navigation?.pushBlock(panel, animated: true)
            case .failure:
                break
            }
        }
    }
}
