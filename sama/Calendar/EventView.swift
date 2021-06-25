//
//  EventView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/14/21.
//

import UIKit

let eventHandleExtraSpace: CGFloat = 4

class EventView: UIView {

    let handle = UIView()

    private var isReady = false
    private var backgroundLayer: CALayer?

    private let dotsView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        dotsView.backgroundColor = UIColor(patternImage: UIImage(named: "event-bg-dot")!)
        addSubview(dotsView)

        handle.frame.size = CGSize(width: 0, height: eventHandleExtraSpace * 2 + eventRightBottomInset.y * 2)
        addSubview(handle)
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
        handle.frame.origin.y = frame.height - handle.frame.height
        handle.frame.size.width = innerFrameSize.width
        if !isReady {
            isReady = true
            setupLayers()
        }
        reframeDotsView()
    }

    private func reframeDotsView() {
        let space = innerFrameSize.width - 2 * 6
        let dots = floor(space / 8)
        let width = dots * 8
        let x = (innerFrameSize.width - width) / 2
        dotsView.frame = CGRect(x: x, y: 6, width: width, height: 16)
    }

    private func setupLayers() {
        let innerFrame = CGRect(origin: .zero, size: innerFrameSize)
        let shadow = CALayer()
        shadow.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 8).cgPath
        shadow.shadowColor = UIColor(red: 0.467, green: 0.134, blue: 0.056, alpha: 0.15).cgColor
        shadow.shadowOpacity = 1
        shadow.shadowRadius = 12
        shadow.shadowOffset = CGSize(width: 0, height: 4)
        shadow.bounds = innerFrame
        shadow.anchorPoint = .zero
        layer.insertSublayer(shadow, at: 0)

        let background = CAGradientLayer()
        background.colors = [UIColor.primary.cgColor, UIColor.primaryDarker.cgColor]
        background.bounds = innerFrame
        background.anchorPoint = .zero
        background.cornerRadius = 4
        background.masksToBounds = true
        layer.insertSublayer(background, at: 1)

        backgroundLayer = background

        let handle = CALayer()
        handle.backgroundColor = UIColor.primary.cgColor
        handle.bounds = CGRect(x: 0, y: 0, width: 36, height: 8)
        handle.cornerRadius = 4
        handle.position = CGPoint(x: self.handle.bounds.midX, y: self.handle.bounds.midY)
        handle.masksToBounds = true
        self.handle.layer.addSublayer(handle)

        let handleMiddle = CALayer()
        handleMiddle.backgroundColor = UIColor.base.cgColor
        handleMiddle.bounds = CGRect(x: 0, y: 0, width: 32, height: 4)
        handleMiddle.cornerRadius = 2
        handleMiddle.position = CGPoint(x: self.handle.bounds.midX, y: self.handle.bounds.midY)
        handleMiddle.masksToBounds = true
        self.handle.layer.addSublayer(handleMiddle)
    }
}
