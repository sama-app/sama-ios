//
//  EventListItemView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/19/21.
//

import UIKit

class EventListItemView: UIView {

    var handleRemove: (() -> Void)?

    init(props: EventProperties, isRemovable: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

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
            textsStack.leadingAnchor.constraint(equalTo: removalButton.trailingAnchor, constant: 4),
            textsStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            trailingAnchor.constraint(equalTo: textsStack.trailingAnchor),
        ])

        let refDate = Calendar.current.startOfDay(for: Date())

        let timeF = DateFormatter()
        timeF.dateStyle = .none
        timeF.timeStyle = .short

        let dateF = DateFormatter()
        dateF.setLocalizedDateFormatFromTemplate("ddMMM")

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .neutral1
        titleLabel.font = .brandedFont(ofSize: 20, weight: .regular)
        textsStack.addArrangedSubview(titleLabel)

        let startDay = Calendar.current.date(byAdding: .day, value: props.daysOffset, to: refDate)!
        let startDate = startDay.addingTimeInterval(3600 * (props.start as NSDecimalNumber).doubleValue)

        if props.timezoneOffset != 0 {
            let startDateTargetTimezone = startDate.addingTimeInterval(3600 * Double(props.timezoneOffset))
            let endDateTargetTimezone = startDateTargetTimezone.addingTimeInterval(3600 * (props.duration as NSDecimalNumber).doubleValue)

            titleLabel.text = "\(dateF.string(from: startDateTargetTimezone)) \(timeF.string(from: startDateTargetTimezone)) to \(timeF.string(from: endDateTargetTimezone))"

            let subtitleLabel = UILabel()
            subtitleLabel.text = "\(dateF.string(from: startDate)) \(timeF.string(from: startDate)) in your timezone"
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
            subtitleLabel.textColor = .secondary
            subtitleLabel.font = .systemFont(ofSize: 12)
            textsStack.addArrangedSubview(subtitleLabel)
        } else {
            let endDate = startDate.addingTimeInterval(3600 * (props.duration as NSDecimalNumber).doubleValue)
            titleLabel.text = "\(dateF.string(from: startDay)) \(timeF.string(from: startDate)) to \(timeF.string(from: endDate))"
        }

        heightAnchor.constraint(equalToConstant: 60).isActive = true

        NSLayoutConstraint.activate([
            removalButton.widthAnchor.constraint(equalToConstant: 44),
            removalButton.heightAnchor.constraint(equalToConstant: 44),
            removalButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            removalButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onRemove() {
        handleRemove?()
    }
}
