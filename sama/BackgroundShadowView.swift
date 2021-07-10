//
//  BackgroundShadowView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 7/6/21.
//

import UIKit

class BackgroundShadowView: UIView {

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
        background.backgroundColor = UIColor.neutral3.cgColor
        background.cornerRadius = 24
        background.masksToBounds = true
        background.bounds = bounds
        background.anchorPoint = .zero

        shadow.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 8).cgPath
        shadow.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        shadow.shadowOpacity = 1
        shadow.shadowRadius = 4
        shadow.shadowOffset = CGSize(width: 0, height: 2)
        shadow.bounds = bounds
        shadow.anchorPoint = .zero
    }
}
