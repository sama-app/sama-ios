//
//  EventListItemView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/19/21.
//

import UIKit

class EventListItemView: UIView {

    var handleRemove: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        let removalButton = UIButton(type: .system)
        removalButton.addTarget(self, action: #selector(onRemove), for: .touchUpInside)
        removalButton.translatesAutoresizingMaskIntoConstraints = false
        removalButton.tintColor = .primary
        removalButton.setImage(UIImage(named: "cross")!, for: .normal)
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

        let titleLabel = UILabel()
        titleLabel.text = "Friday 10:00 to 11:00"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .neutral1
        titleLabel.font = .brandedFont(ofSize: 20, weight: .regular)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Saturday 23:00 in your timezone"
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textColor = .secondary
        subtitleLabel.font = .systemFont(ofSize: 12)

        textsStack.addArrangedSubview(titleLabel)
        textsStack.addArrangedSubview(subtitleLabel)

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
