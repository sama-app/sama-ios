//
//  EventView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/14/21.
//

import UIKit

class EventView: UIView {

    private var isReady = false
    private var backgroundLayer: CALayer?

    private let dotsView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        dotsView.backgroundColor = UIColor(patternImage: UIImage(named: "event-bg-dot")!)
        addSubview(dotsView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var innerFrameWidth: CGFloat {
        bounds.width - eventRightBottomInset.x
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !isReady {
            isReady = true
            setupLayers()
        }
        reframeDotsView()
    }

    private func reframeDotsView() {
        let space = innerFrameWidth - 2 * 6
        let dots = floor(space / 8)
        let width = dots * 8
        let x = (innerFrameWidth - width) / 2
        dotsView.frame = CGRect(x: x, y: 6, width: width, height: 16)
    }

    private func setupLayers() {
        let middle = CGPoint(x: bounds.midX - (eventRightBottomInset.x / 2), y: bounds.midY - (eventRightBottomInset.y / 2))

        let innerFrame = CGRect(x: 0, y: 0, width: innerFrameWidth, height: bounds.height - eventRightBottomInset.y)
        let shadow = CALayer()
        shadow.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 8).cgPath
        shadow.shadowColor = UIColor(red: 0.467, green: 0.134, blue: 0.056, alpha: 0.15).cgColor
        shadow.shadowOpacity = 1
        shadow.shadowRadius = 12
        shadow.shadowOffset = CGSize(width: 0, height: 4)
        shadow.bounds = innerFrame
        shadow.position = middle
        layer.insertSublayer(shadow, at: 0)

        let background = CAGradientLayer()
        background.colors = [UIColor.primary.cgColor, UIColor.primaryDarker.cgColor]
        background.bounds = innerFrame
        background.position = middle
        background.cornerRadius = 4
        background.masksToBounds = true
        layer.insertSublayer(background, at: 1)

        backgroundLayer = background
    }
}
