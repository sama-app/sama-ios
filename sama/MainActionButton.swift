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

    override var isHighlighted: Bool {
        didSet {
            changeBgOpacity()
        }
    }
    override var isEnabled: Bool {
        didSet {
            changeBgOpacity()
        }
    }

    private let shadow = CALayer()
    private let background = CAGradientLayer()

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
        shadow.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 8).cgPath
        shadow.shadowColor = UIColor(red: 0.467, green: 0.134, blue: 0.056, alpha: 0.15).cgColor
        shadow.shadowOpacity = 1
        shadow.shadowRadius = 12
        shadow.shadowOffset = CGSize(width: 0, height: 4)
        shadow.bounds = bounds
        shadow.anchorPoint = .zero

        background.colors = [UIColor.primary.cgColor, UIColor.primaryDarker.cgColor]
        background.bounds = bounds
        background.anchorPoint = .zero
        background.cornerRadius = 8
        background.masksToBounds = true
    }

    private func changeBgOpacity() {
        background.opacity = (isHighlighted || !isEnabled) ? 0.4 : 1
    }
}
