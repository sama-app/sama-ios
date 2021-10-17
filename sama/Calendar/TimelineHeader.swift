//
//  TimelineHeader.swift
//  sama
//
//  Created by Viktoras Laukevičius on 10/16/21.
//

import UIKit

final class TimelineHeader: UIView {

    let upperLabel = UILabel()
    let lowerLabel = UILabel()
    let container = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .base

        let sepBtm = UIView(frame: CGRect(x: 0, y: frame.height - 1, width: frame.width, height: 1))
        sepBtm.backgroundColor = .calendarGrid
        sepBtm.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        let sepRhtTopInset = Sama.env.ui.calendarHeaderRightSeparatorTopInset
        let sepRht = UIView(frame: CGRect(x: frame.width - 1, y: sepRhtTopInset, width: 1, height: frame.height - sepRhtTopInset))
        sepRht.backgroundColor = .calendarGrid
        sepRht.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
        addSubview(sepBtm)
        addSubview(sepRht)

        container.translatesAutoresizingMaskIntoConstraints = false
        container.axis = .vertical
        container.alignment = .trailing

        upperLabel.translatesAutoresizingMaskIntoConstraints = false
        upperLabel.font = .systemFont(ofSize: 10, weight: .regular)
        upperLabel.textColor = .neutral1
        container.addArrangedSubview(upperLabel)

        lowerLabel.translatesAutoresizingMaskIntoConstraints = false
        lowerLabel.font = .systemFont(ofSize: 10, weight: .regular)
        lowerLabel.textColor = .secondary
        container.addArrangedSubview(lowerLabel)

        addSubview(container)
        NSLayoutConstraint.activate([
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 8),
            container.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
