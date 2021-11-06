//
//  MeetingPreferencesScreen.swift
//  sama
//
//  Created by Viktoras Laukevičius on 11/6/21.
//

import UIKit

class MeetingPreferencesScreen: UIViewController {

    var api: Api!

    private let titleLabel = UILabel().forAutoLayout()
    private let blockingToggle = UISwitch().forAutoLayout()
    private let inputField = LightTextField().forAutoLayout()

    private var topBar: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        isModalInPresentation = true

        addNavigationBar()

        titleLabel.text = "Meeting Preferences"
        titleLabel.makeMultiline()
        titleLabel.font = .brandedFont(ofSize: 28, weight: .semibold)
        titleLabel.textColor = .neutral1
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            view.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 40),
            titleLabel.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 16)
        ])

        api.request(for: UserSettingsRequest()) {
            switch $0 {
            case let .success(settings):
                self.displayPreferences(settings.meetingPreferences)
            case .failure:
                break
            }
        }
    }

    private func addNavigationBar() {
        topBar = UIView().forAutoLayout()
        view.addSubview(topBar)
        topBar.pinLeadingAndTrailing(top: 0, and: [topBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44)])

        let backBtn = UIButton(type: .system)
        backBtn.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.setImage(UIImage(named: "arrow-back")!, for: .normal)
        backBtn.setTitle("Back", for: .normal)
        backBtn.titleLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
        backBtn.titleEdgeInsets.left = 8
        backBtn.titleEdgeInsets.right = -8
        backBtn.contentEdgeInsets.right = 8
        backBtn.tintColor = .primary
        backBtn.tintAdjustmentMode = .normal

        view.addSubview(backBtn)

        NSLayoutConstraint.activate([
            backBtn.heightAnchor.constraint(equalToConstant: 44),
            backBtn.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 8),
            backBtn.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])
    }

    private func displayPreferences(_ preferences: DomainUserSettings.Meeting) {
        let inputTitle = UILabel().forAutoLayout()
        inputTitle.textColor = .secondary
        inputTitle.font = .brandedFont(ofSize: 14, weight: .semibold)
        inputTitle.attributedText = NSAttributedString(string: "DEFAULT MEETING TITLE", attributes: [.kern: 1.5])
        view.addSubview(inputTitle)
        NSLayoutConstraint.activate([
            inputTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            view.trailingAnchor.constraint(equalTo: inputTitle.trailingAnchor, constant: 40),
            inputTitle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 48)
        ])

        inputField.font = .brandedFont(ofSize: 20, weight: .regular)
        inputField.placeholder = preferences.defaultTitle ?? ""
        inputField.autocorrectionType = .no
        inputField.autocapitalizationType = .sentences
        view.addSubview(inputField)
        NSLayoutConstraint.activate([
            inputField.heightAnchor.constraint(equalToConstant: 48),
            inputField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            view.trailingAnchor.constraint(equalTo: inputField.trailingAnchor, constant: 40),
            inputField.topAnchor.constraint(equalTo: inputTitle.bottomAnchor, constant: 8)
        ])

        let blockingTimesContainer = setupBlockTimesContainer(isOn: preferences.blockOutSlots)
        view.addSubview(blockingTimesContainer)
        NSLayoutConstraint.activate([
            blockingTimesContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            view.trailingAnchor.constraint(equalTo: blockingTimesContainer.trailingAnchor, constant: 40),
            blockingTimesContainer.topAnchor.constraint(equalTo: inputField.bottomAnchor, constant: 24)
        ])
    }

    private func setupBlockTimesContainer(isOn: Bool) -> UIView {
        let container = UIView().forAutoLayout()

        let label = UILabel().forAutoLayout()
        label.makeMultiline()
        label.textColor = .neutral1
        label.font = .brandedFont(ofSize: 20, weight: .regular)
        label.text = "Block proposed times by default"
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        blockingToggle.onTintColor = .primary
        blockingToggle.isOn = isOn

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

    @objc private func onBack() {
        navigationController?.popViewController(animated: true)
    }
}
