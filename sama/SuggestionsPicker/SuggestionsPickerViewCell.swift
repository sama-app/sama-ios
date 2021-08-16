//
//  SuggestionsPickerViewCell.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/16/21.
//

import UIKit

class SuggestionsPickerViewCell: UICollectionViewCell {
    private let shadow = CALayer()
    private let background = CALayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.insertSublayer(shadow, at: 0)
        layer.insertSublayer(background, at: 1)
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
}
