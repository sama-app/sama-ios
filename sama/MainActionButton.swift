//
//  MainActionButton.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/12/21.
//

import UIKit

class MainActionButton: UIButton {

    class func make(withTitle title: String) -> MainActionButton {
        let btn = MainActionButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.neutralN, for: .normal)
        btn.titleLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
        return btn
    }

    private var isReady = false
    private var backgroundLayer: CALayer?

    override var isHighlighted: Bool {
        didSet {
            backgroundLayer?.opacity = isHighlighted ? 0.4 : 1
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !isReady {
            isReady = true
            setupLayers()
        }
    }

    private func setupLayers() {
        let middle = CGPoint(x: bounds.midX, y: bounds.midY)

        let shadow = CALayer()
        shadow.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 8).cgPath
        shadow.shadowColor = UIColor(red: 0.467, green: 0.134, blue: 0.056, alpha: 0.15).cgColor
        shadow.shadowOpacity = 1
        shadow.shadowRadius = 12
        shadow.shadowOffset = CGSize(width: 0, height: 4)
        shadow.bounds = bounds
        shadow.position = middle
        layer.insertSublayer(shadow, at: 0)

        let background = CAGradientLayer()
        background.colors = [UIColor.primary.cgColor, UIColor.primaryDarker.cgColor]
        background.bounds = bounds
        background.position = middle
        background.cornerRadius = 8
        background.masksToBounds = true
        layer.insertSublayer(background, at: 1)

        backgroundLayer = background
    }
}
