//
//  LightTextField.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/22/21.
//

import UIKit

class LightTextField: UITextField {

    private let border = CALayer()
    private let backgroundLayer = CALayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.addSublayer(backgroundLayer)
        layer.addSublayer(border)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: -1, dy:-1), cornerRadius:8)
        let cutout = UIBezierPath(roundedRect: bounds, cornerRadius:8).reversing()
        path.append(cutout)

        backgroundLayer.backgroundColor = UIColor.white.cgColor
        backgroundLayer.cornerRadius = 8
        backgroundLayer.frame = bounds

        border.frame = bounds
        border.shadowPath = path.cgPath
        border.masksToBounds = true
        border.shadowColor = UIColor(red: 107.0/255.0, green: 88.0/255.0, blue: 68.0/255.0, alpha: 1).cgColor
        border.shadowOffset = CGSize(width: 0, height: 1)
        border.shadowOpacity = 1
        border.shadowRadius = 1
        border.cornerRadius = 8
        border.backgroundColor = UIColor.clear.cgColor
        border.borderWidth = 1
        border.borderColor = UIColor(red: 0.898, green: 0.859, blue: 0.812, alpha: 1).cgColor
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 16, dy: 0)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 16, dy: 0)
    }
}
