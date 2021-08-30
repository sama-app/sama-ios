//
//  TimeConfirmedPanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/27/21.
//

import UIKit

class TimeConfirmedPanel: CalendarNavigationBlock {

    var model: SuggestionsViewCoordinator.ConfirmationResult!
    var coordinator: SuggestionsViewCoordinator!

    let calendar = Calendar.current

    private let actionBtn = MainActionButton.make(withTitle: "Done")

    override func didLoad() {
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
        titleLabel.font = .brandedFont(ofSize: 24, weight: .semibold)
        titleLabel.text = "Time confirmed"
        textsStack.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textColor = .secondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        if let recipient = model.recipientEmail {
            subtitleLabel.text = "Meeting invite is sent to \(recipient) on your behalf."
        } else {
            subtitleLabel.text = "Meeting invite is sent to you on \(model.meetingInitiator) behalf."
        }
        textsStack.addArrangedSubview(subtitleLabel)

        actionBtn.addTarget(self, action: #selector(onDone), for: .touchUpInside)

        addSubview(illustration)
        addSubview(actionBtn)
        addSubview(textsStack)

        NSLayoutConstraint.activate([
            titleLabel.heightAnchor.constraint(equalTo: illustration.heightAnchor, multiplier: 0.5),
            illustration.leadingAnchor.constraint(equalTo: leadingAnchor),
            illustration.topAnchor.constraint(equalTo: topAnchor),
            textsStack.leadingAnchor.constraint(equalTo: illustration.trailingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: textsStack.trailingAnchor),
            textsStack.topAnchor.constraint(equalTo: illustration.topAnchor)
        ])

        NSLayoutConstraint.activate([
            actionBtn.heightAnchor.constraint(equalToConstant: 48),
            actionBtn.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: actionBtn.trailingAnchor),
            bottomAnchor.constraint(equalTo: actionBtn.bottomAnchor)
        ])

        let constraintsToTopPart: (UIView) -> [NSLayoutConstraint] = { sourceView in
            return [
                sourceView.topAnchor.constraint(greaterThanOrEqualTo: textsStack.bottomAnchor, constant: 16),
                sourceView.topAnchor.constraint(greaterThanOrEqualTo: illustration.bottomAnchor, constant: 16)
            ]
        }

        if model.recipientEmail != nil {
            let detailsLabel = UILabel()
            detailsLabel.translatesAutoresizingMaskIntoConstraints = false
            detailsLabel.numberOfLines = 0

            let defaultAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.secondary,
                .font: UIFont.systemFont(ofSize: 15, weight: .regular)
            ]
            let boldAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.secondary,
                .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
            ]

            let dateText = [
                calendar.weekdayRelativeFormatted(from: Date(), to: model.startDate) + ",",
                dayFormatter.string(from: model.startDate),
                timeFormatter.string(from: model.startDate),
                "-",
                timeFormatter.string(from: model.endDate),
            ].joined(separator: " ")

            let parts = [
                ("An event called “", defaultAttrs),
                (model.meetingTitle, boldAttrs),
                ("” has been added to your calendar for \(dateText)", defaultAttrs),
            ]
            let finalText = NSMutableAttributedString()
            for (text, attrs) in parts {
                finalText.append(NSAttributedString(string: text, attributes: attrs))
            }
            detailsLabel.attributedText = finalText

            addSubview(detailsLabel)
            detailsLabel.pinLeadingAndTrailing(and: constraintsToTopPart(detailsLabel) + [actionBtn.topAnchor.constraint(equalTo: detailsLabel.bottomAnchor, constant: 16)])
        } else {
            NSLayoutConstraint.activate(constraintsToTopPart(actionBtn))
        }
    }

    @objc private func onDone() {
        coordinator.reset()
    }
}
