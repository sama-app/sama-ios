//
//  EventView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/14/21.
//

import UIKit

let eventHandleExtraSpace: CGFloat = 4

class EventView: UIView {

    let handleView = UIView()

    var isLocked = false {
        didSet {
            isUserInteractionEnabled = !isLocked
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    private let dotsView = UIView()
    private let shadow = CALayer()
    private let background = CAGradientLayer()

    private let handle = CALayer()
    private let handleMiddle = CALayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        dotsView.backgroundColor = UIColor(patternImage: UIImage(named: "event-bg-dot")!)
        addSubview(dotsView)

        handleView.frame.size = CGSize(width: 0, height: eventHandleExtraSpace * 2 + eventRightBottomInset.y * 2)
        addSubview(handleView)

        layer.insertSublayer(shadow, at: 0)
        layer.insertSublayer(background, at: 1)
        self.handleView.layer.addSublayer(handle)
        self.handleView.layer.addSublayer(handleMiddle)
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
        handleView.frame.origin.y = frame.height - handleView.frame.height
        handleView.frame.size.width = innerFrameSize.width
        redrawLayers()
        reframeDotsView()

        let innerFrame = CGRect(origin: .zero, size: innerFrameSize)
        CALayer.performWithoutImplicitAnimations {
            self.background.bounds = innerFrame
            self.shadow.bounds = innerFrame
            self.shadow.shadowPath = UIBezierPath(roundedRect: innerFrame, cornerRadius: 8).cgPath
        }
    }

    private func reframeDotsView() {
        let space = innerFrameSize.width - 2 * 6
        let dots = floor(space / 8)
        let width = dots * 8
        let x = (innerFrameSize.width - width) / 2
        dotsView.frame = CGRect(x: x, y: 6, width: width, height: 16)

        dotsView.isHidden = isLocked || (innerFrameSize.height < 28)
    }

    private func redrawLayers() {
        shadow.shadowColor = UIColor(red: 0.467, green: 0.134, blue: 0.056, alpha: 0.15).cgColor
        shadow.shadowOpacity = 1
        shadow.shadowRadius = 12
        shadow.shadowOffset = CGSize(width: 0, height: 4)
        shadow.anchorPoint = .zero

        background.colors = [UIColor.primary.cgColor, UIColor.primaryDarker.cgColor]
        background.anchorPoint = .zero
        background.cornerRadius = 4
        background.masksToBounds = true
        layer.insertSublayer(background, at: 1)

        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)

        handle.backgroundColor = UIColor.primary.cgColor
        handle.bounds = CGRect(x: 0, y: 0, width: 36, height: 8)
        handle.cornerRadius = 4
        handle.position = CGPoint(x: handleView.bounds.midX, y: handleView.bounds.midY)
        handle.masksToBounds = true
        handle.isHidden = isLocked

        handleMiddle.backgroundColor = UIColor.base.cgColor
        handleMiddle.bounds = CGRect(x: 0, y: 0, width: 32, height: 4)
        handleMiddle.cornerRadius = 2
        handleMiddle.position = CGPoint(x: handleView.bounds.midX, y: handleView.bounds.midY)
        handleMiddle.masksToBounds = true
        handleMiddle.isHidden = isLocked

        CATransaction.commit()
    }
}
