//
//  SuggestionsPickCalendarSlider.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/22/21.
//

import UIKit

class SuggestionsPickCalendarSlider: UIView {

    var isLocked = false {
        didSet {
            isUserInteractionEnabled = !isLocked
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    private let shadow = CALayer()
    private let background = CAGradientLayer()

    private let dotsView = UIView()

    private let arrowUp = UIImageView(image: UIImage(named: "drag-arrow-up")!)
    private let arrowDown = UIImageView(image: UIImage(named: "drag-arrow-down")!)

    init() {
        super.init(frame: .zero)

        dotsView.backgroundColor = UIColor(patternImage: UIImage(named: "event-bg-dot")!)
        addSubview(dotsView)

        layer.insertSublayer(shadow, at: 0)
        layer.insertSublayer(background, at: 1)

        setupArrows()
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

            self.shadow.bounds = innerFrame
            self.shadow.shadowPath = UIBezierPath(roundedRect: innerFrame, cornerRadius: 8).cgPath
        }

        if isLocked {
            arrowDown.isHidden = true
            arrowUp.isHidden = true
            dotsView.isHidden = true
        } else {
            let isIndicatorHidden = arrowDown.frame.minY < arrowUp.frame.maxY
            arrowDown.isHidden = isIndicatorHidden
            arrowUp.isHidden = isIndicatorHidden
            reframeDotsView()
        }
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
    }

    private func reframeDotsView() {
        let space = innerFrameSize.width - 2 * 6
        let dots = floor(space / 8)
        let width = dots * 8
        let x = (innerFrameSize.width - width) / 2
        dotsView.frame = CGRect(x: x, y: (innerFrameSize.height / 2) - 8, width: width, height: 16)

        let spaceBetweenArrows = arrowDown.frame.minY - arrowUp.frame.maxY
        dotsView.isHidden = spaceBetweenArrows < 28
    }

    private func setupArrows() {
        arrowUp.translatesAutoresizingMaskIntoConstraints = false
        addSubview(arrowUp)
        arrowDown.translatesAutoresizingMaskIntoConstraints = false
        addSubview(arrowDown)

        NSLayoutConstraint.activate([
            arrowUp.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -1),
            arrowUp.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            arrowDown.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -1),
            bottomAnchor.constraint(equalTo: arrowDown.bottomAnchor, constant: 14)
        ])
    }
}
