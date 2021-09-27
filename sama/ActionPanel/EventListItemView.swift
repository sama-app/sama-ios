//
//  EventListItemView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/19/21.
//

import UIKit

class EventListItemView: UIView {

    var handleRemove: (() -> Void)?
    var handleFocus: (() -> Void)?
    let calendar = Calendar.current

    init(props: EventProperties, isRemovable: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let focusButton = UIButton(type: .system)
        focusButton.addTarget(self, action: #selector(onFocus), for: .touchUpInside)
        focusButton.translatesAutoresizingMaskIntoConstraints = false
        focusButton.tintColor = .primary
        focusButton.setImage(UIImage(named: "focus")!, for: .normal)
        addSubview(focusButton)

        let removalButton = UIButton(type: .system)
        removalButton.addTarget(self, action: #selector(onRemove), for: .touchUpInside)
        removalButton.translatesAutoresizingMaskIntoConstraints = false
        removalButton.tintColor = .primary
        removalButton.setImage(UIImage(named: "cross")!, for: .normal)
        removalButton.isHidden = !isRemovable
        addSubview(removalButton)

        let textsStack = UIStackView()
        textsStack.translatesAutoresizingMaskIntoConstraints = false
        textsStack.axis = .vertical
        addSubview(textsStack)
        NSLayoutConstraint.activate([
            textsStack.leadingAnchor.constraint(equalTo: focusButton.trailingAnchor, constant: 4),
            textsStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            focusButton.leadingAnchor.constraint(equalTo: leadingAnchor),
        ])

        let refDate = calendar.startOfDay(for: CalendarDateUtils.shared.uiRefDate)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .neutral1
        titleLabel.font = .brandedFont(ofSize: 20, weight: .regular)
        textsStack.addArrangedSubview(titleLabel)

        let startDay = calendar.date(byAdding: .day, value: props.daysOffset, to: refDate)!
        let startDate = startDay.addingTimeInterval(3600 * (props.start as NSDecimalNumber).doubleValue)

        if props.timezoneOffset != 0 {
            let startDateTargetTimezone = startDate.addingTimeInterval(3600 * Double(props.timezoneOffset))
            let endDateTargetTimezone = startDateTargetTimezone.addingTimeInterval(3600 * (props.duration as NSDecimalNumber).doubleValue)

            titleLabel.text = DateFormatter.formatDateRange(from: startDateTargetTimezone, to: endDateTargetTimezone)

            let subtitleLabel = UILabel()

            subtitleLabel.text = [
                calendar.relativeFormatted(from: CalendarDateUtils.shared.dateNow, to: startDay),
                timeFormatter.string(from: startDate),
                "in your timezone"
            ].joined(separator: " ")
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
            subtitleLabel.textColor = .secondary
            subtitleLabel.font = .systemFont(ofSize: 12)
            textsStack.addArrangedSubview(subtitleLabel)
        } else {
            let endDate = startDate.addingTimeInterval(3600 * (props.duration as NSDecimalNumber).doubleValue)
            titleLabel.text = DateFormatter.formatDateRange(from: startDate, to: endDate)
        }

        heightAnchor.constraint(equalToConstant: 60).isActive = true

        NSLayoutConstraint.activate([
            removalButton.widthAnchor.constraint(equalToConstant: 44),
            removalButton.heightAnchor.constraint(equalToConstant: 44),
            trailingAnchor.constraint(equalTo: removalButton.trailingAnchor, constant: -8),
            removalButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            focusButton.widthAnchor.constraint(equalToConstant: 44),
            focusButton.heightAnchor.constraint(equalToConstant: 44),
            focusButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            focusButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onRemove() {
        handleRemove?()
    }

    @objc private func onFocus() {
        handleFocus?()
    }
}

private extension DateFormatter {
    static func formatDateRange(from start: Date, to end: Date) -> String {
        return [
            "\(dayFormatter.string(from: start)),",
            timeFormatter.string(from: start),
            "to",
            timeFormatter.string(from: end)
        ].joined(separator: " ")
    }
}
