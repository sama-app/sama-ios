//
//  SuggestionsPickerViewCell.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/16/21.
//

import UIKit

class SuggestionsPickerViewCell: UICollectionViewCell {

    var slot: ProposedAvailableSlot!
    var confirmHandler: (() -> Void)?

    let titleLabel = UILabel()
    let rangeIndication = UILabel()
    let valueLabel = UILabel()
    let actionBtn = MainActionButton.make(withTitle: "Confirm")

    private let shadow = CALayer()
    private let background = CALayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.insertSublayer(shadow, at: 0)
        layer.insertSublayer(background, at: 1)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .neutral1
        titleLabel.font = .brandedFont(ofSize: 18, weight: .regular)
        titleLabel.text = "Alternative 1"
        addSubview(titleLabel)

        rangeIndication.translatesAutoresizingMaskIntoConstraints = false
        rangeIndication.textColor = .primary
        rangeIndication.font = .brandedFont(ofSize: 18, weight: .regular)
        rangeIndication.text = "Range"
        addSubview(rangeIndication)

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.textColor = .neutral1
        valueLabel.font = .brandedFont(ofSize: 24, weight: .regular)
        valueLabel.text = "Tuesday 11am-12pm"
        addSubview(valueLabel)

        actionBtn.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
        addSubview(actionBtn)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            rangeIndication.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: rangeIndication.trailingAnchor, constant: 16),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            actionBtn.heightAnchor.constraint(equalToConstant: 48),
            actionBtn.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: actionBtn.trailingAnchor, constant: 16),
            bottomAnchor.constraint(equalTo: actionBtn.bottomAnchor, constant: 16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        redrawLayers()
    }

    private func redrawLayers() {
        background.backgroundColor = UIColor.neutralN.cgColor
        background.cornerRadius = 24
        background.masksToBounds = true
        background.bounds = bounds
        background.anchorPoint = .zero

        shadow.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 24).cgPath
        shadow.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        shadow.shadowOpacity = 1
        shadow.shadowRadius = 2
        shadow.shadowOffset = CGSize(width: 0, height: 2)
        shadow.bounds = bounds
        shadow.anchorPoint = .zero
    }

    @objc private func onConfirm() {
        confirmHandler?()
    }
}
