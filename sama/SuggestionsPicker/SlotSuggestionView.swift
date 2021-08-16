//
//  SlotSuggestionView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/12/21.
//

import UIKit

class SlotSuggestionView: UIView {

    var isHighlighted = false {
        didSet {
            setShadowsVisibility()
        }
    }

    private let outShadow = CALayer()
    private let inShadow = CALayer()
    private let background = CAGradientLayer()

    init() {
        super.init(frame: .zero)

        layer.insertSublayer(outShadow, at: 0)
        layer.insertSublayer(inShadow, at: 1)
        layer.insertSublayer(background, at: 2)

        setShadowsVisibility()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var innerFrameSize: CGSize {
        return CGSize(
            width: bounds.width - eventRightBottomInset.x,
            height: bounds.height - eventHandleExtraSpace - eventRightBottomInset.y
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        redrawLayers()

        let innerFrame = CGRect(origin: .zero, size: innerFrameSize)
        CALayer.performWithoutImplicitAnimations {
            self.background.bounds = innerFrame

            self.outShadow.bounds = innerFrame
            self.outShadow.shadowPath = UIBezierPath(roundedRect: innerFrame, cornerRadius: 8).cgPath

            inShadow.frame = innerFrame
            let path = UIBezierPath(rect: inShadow.bounds.insetBy(dx: -1, dy: -1))
            let cutout = UIBezierPath(rect: inShadow.bounds).reversing()
            path.append(cutout)
            inShadow.shadowPath = path.cgPath
        }
    }

    private func setShadowsVisibility() {
        outShadow.isHidden = !isHighlighted
        inShadow.isHidden = isHighlighted
    }

    private func redrawLayers() {
        outShadow.shadowColor = UIColor(red: 0.467, green: 0.134, blue: 0.056, alpha: 0.15).cgColor
        outShadow.shadowOpacity = 1
        outShadow.shadowRadius = 12
        outShadow.shadowOffset = CGSize(width: 0, height: 4)
        outShadow.anchorPoint = .zero

        inShadow.masksToBounds = true
        inShadow.shadowColor = UIColor(white: 0, alpha: 0.15).cgColor
        inShadow.shadowOffset = CGSize.zero
        inShadow.shadowOpacity = 1
        inShadow.shadowRadius = 3

        if isHighlighted {
            background.colors = [UIColor.primary.cgColor, UIColor.primaryDarker.cgColor]
        } else {
            background.colors = [UIColor.primaryPale.cgColor, UIColor.primaryPaleDarker.cgColor]
        }

        background.anchorPoint = .zero
        background.cornerRadius = 4
        background.masksToBounds = true
        layer.insertSublayer(background, at: 1)
    }
}
