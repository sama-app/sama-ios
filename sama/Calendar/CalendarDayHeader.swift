//
//  CalendarDayHeader.swift
//  sama
//
//  Created by Viktoras Laukevičius on 10/16/21.
//

import UIKit

final class CalendarDayHeader: UIView {

    let upperLabel = UILabel()
    let lowerLabel = UILabel()
    let container = UIStackView(arrangedSubviews: [])

    override init(frame: CGRect) {
        super.init(frame: frame)

        let cellSize = frame.size

        backgroundColor = .base

        let sepBtm = UIView(frame: CGRect(x: 0, y: frame.height - 1, width: cellSize.width, height: 1))
        sepBtm.backgroundColor = .calendarGrid
        sepBtm.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        let sepRhtHeight = Sama.env.ui.calendarHeaderRightSeparatorHeight
        let sepRht = UIView(frame: CGRect(x: cellSize.width - 1, y: cellSize.height - sepRhtHeight, width: 1, height: sepRhtHeight))
        sepRht.backgroundColor = .calendarGrid
        sepRht.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
        addSubview(sepBtm)
        addSubview(sepRht)

        upperLabel.translatesAutoresizingMaskIntoConstraints = false
        upperLabel.font = .systemFont(ofSize: 15, weight: .bold)
        upperLabel.textAlignment = .center
        upperLabel.layer.cornerRadius = 12
        upperLabel.layer.masksToBounds = true

        lowerLabel.font = .systemFont(ofSize: 12)
        lowerLabel.translatesAutoresizingMaskIntoConstraints = false
        lowerLabel.textColor = .neutral2

        container.addArrangedSubview(upperLabel)
        container.addArrangedSubview(lowerLabel)
        container.axis = .vertical
        container.alignment = .center
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        NSLayoutConstraint.activate([
            upperLabel.widthAnchor.constraint(equalToConstant: 24),
            upperLabel.heightAnchor.constraint(equalToConstant: 24),
            centerXAnchor.constraint(equalTo: container.centerXAnchor),
            centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
