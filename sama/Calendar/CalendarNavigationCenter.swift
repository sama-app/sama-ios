//
//  CalendarNavigationCenter.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit

class CalendarNavigationBlock: UIView {
    weak var navigation: CalendarNavigationCenter? = nil
    func didLoad() {}
}

final class CalendarNavigationCenter: UIView {

    var onActivePanelHeightChange: ((CGFloat) -> Void)?
    private var stack: [UIView] = []
    private var stackLeadingConstraint: [NSLayoutConstraint] = []

    private var toastDismissJob: DispatchWorkItem?

    func pushBlock(_ block: CalendarNavigationBlock, animated: Bool) {
        block.translatesAutoresizingMaskIntoConstraints = false
        block.navigation = self
        block.didLoad()

        let fullBlock = UIView()
        fullBlock.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fullBlock)

        let blockWrapper = CalendarBlockWrapper()
        blockWrapper.backgroundColor = .neutralN
        blockWrapper.layer.cornerRadius = 24
        blockWrapper.translatesAutoresizingMaskIntoConstraints = false
        fullBlock.addSubview(blockWrapper)

        blockWrapper.addSubview(block)
        NSLayoutConstraint.activate([
            block.leadingAnchor.constraint(equalTo: blockWrapper.leadingAnchor, constant: 16),
            block.topAnchor.constraint(equalTo: blockWrapper.topAnchor, constant: 16),
            blockWrapper.trailingAnchor.constraint(equalTo: block.trailingAnchor, constant: 16),
            blockWrapper.bottomAnchor.constraint(equalTo: block.bottomAnchor, constant: 16),
        ])

        NSLayoutConstraint.activate([
            blockWrapper.leadingAnchor.constraint(equalTo: fullBlock.leadingAnchor, constant: 16),
            blockWrapper.topAnchor.constraint(equalTo: fullBlock.topAnchor, constant: 16),
            fullBlock.trailingAnchor.constraint(equalTo: blockWrapper.trailingAnchor, constant: 16),
            fullBlock.bottomAnchor.constraint(equalTo: blockWrapper.bottomAnchor, constant: 16),
        ])

        let leading = fullBlock.leadingAnchor.constraint(equalTo: leadingAnchor, constant: bounds.width)
        NSLayoutConstraint.activate([
            fullBlock.widthAnchor.constraint(equalTo: widthAnchor),
            leading,
            fullBlock.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        stack.append(fullBlock)

        if animated {
            setNeedsLayout()
            layoutIfNeeded()
        }

        leading.constant = 0

        stackLeadingConstraint.last?.constant = -bounds.width

        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            })
        }

        stackLeadingConstraint.append(leading)
    }

    func pop() {
        guard stack.count >= 2 else { return }

        toastDismissJob?.perform()

        let currentBlock = stack.popLast()
        stackLeadingConstraint.popLast()?.constant = bounds.width
        stackLeadingConstraint.last?.constant = 0
        UIView.animate(withDuration: 0.3, animations: {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }, completion: { _ in currentBlock?.removeFromSuperview() })
    }

    func showToast(withMessage message: String) {
        toastDismissJob?.perform()

        guard let currentBlock = stack.last?.subviews.first else { return }

        let toastView = ToastMessageView(message: message) { [weak self] in
            self?.toastDismissJob?.perform()
        }
        toastView.alpha = 0
        addSubview(toastView)

        NSLayoutConstraint.activate([
            toastView.widthAnchor.constraint(equalTo: currentBlock.widthAnchor),
            toastView.centerXAnchor.constraint(equalTo: currentBlock.centerXAnchor),
            toastView.heightAnchor.constraint(equalToConstant: 96),
            currentBlock.topAnchor.constraint(equalTo: toastView.bottomAnchor, constant: 16)
        ])

        UIView.animate(withDuration: 0.3, animations: {
            toastView.alpha = 1
        }, completion: { _ in
            self.queueToastDismiss(with: toastView)
        })
    }

    private func queueToastDismiss(with view: UIView) {
        toastDismissJob = DispatchWorkItem {
            self.toastDismissJob = nil
            UIView.animate(withDuration: 0.3, animations: {
                view.alpha = 0
            }, completion: { _ in
                view.removeFromSuperview()
            })
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: toastDismissJob!)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        onActivePanelHeightChange?(stack.last?.frame.height ?? 0)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for v in subviews {
            if let target = v.hitTest(v.convert(point, from: self), with: event) {
                return target
            }
        }
        return nil
    }
}

private final class CalendarBlockWrapper: UIView {
    private var isReady = false

    override func layoutSubviews() {
        super.layoutSubviews()
        if (!isReady) {
            isReady = true

            let middle = CGPoint(x: bounds.midX, y: bounds.midY)

            let shadowPath0 = UIBezierPath(roundedRect: bounds, cornerRadius: 24)
            let layer0 = CALayer()
            layer0.shadowPath = shadowPath0.cgPath
            layer0.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
            layer0.shadowOpacity = 1
            layer0.shadowRadius = 2
            layer0.shadowOffset = CGSize(width: 0, height: 2)
            layer0.bounds = bounds
            layer0.position = middle
            layer.insertSublayer(layer0, at: 0)

            let background = CALayer()
            background.backgroundColor = UIColor.neutralN.cgColor
            background.bounds = bounds
            background.position = middle
            background.cornerRadius = 24
            background.masksToBounds = true
            layer.insertSublayer(background, at: 1)
        }
    }
}
