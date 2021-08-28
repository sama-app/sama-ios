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

protocol UnstyledCalendarNavigationBlock: AnyObject {
    var navigation: CalendarNavigationCenter? { get set }
    func didLoad()
}

final class CalendarNavigationCenter: UIView {

    var onActivePanelHeightChange: ((CGFloat) -> Void)?

    private var stack: [UIView] = []
    private var stackLeadingConstraint: [NSLayoutConstraint] = []
    private var bottomConstraints: [NSLayoutConstraint] = []

    private var toastDismissJob: DispatchWorkItem?

    private var isMinimized = false
    private var yPan: CGFloat = 0

    private var pan: UIPanGestureRecognizer!

    init() {
        super.init(frame: .zero)
        pan = UIPanGestureRecognizer(target: self, action: #selector(onPan))
        pan.minimumNumberOfTouches = 1
        addGestureRecognizer(pan)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func pushUnstyledBlock(_ fullBlock: (UIView & UnstyledCalendarNavigationBlock), animated: Bool) {
        fullBlock.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fullBlock)

        fullBlock.navigation = self

        setup(fullBlock: fullBlock, animated: animated) {
            fullBlock.didLoad()
        }
    }

    func pushBlock(_ block: CalendarNavigationBlock, animated: Bool) {
        block.translatesAutoresizingMaskIntoConstraints = false
        block.navigation = self

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

        setup(fullBlock: fullBlock, animated: animated) {
            block.didLoad()
        }
    }

    private func setup(fullBlock: UIView, animated: Bool, onLoad: () -> Void) {
        let leading = fullBlock.leadingAnchor.constraint(equalTo: leadingAnchor, constant: bounds.width)
        let bottom = fullBlock.bottomAnchor.constraint(equalTo: bottomAnchor)
        NSLayoutConstraint.activate([
            fullBlock.widthAnchor.constraint(equalTo: widthAnchor),
            leading,
            bottom
        ])
        stack.append(fullBlock)
        onLoad()

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
        bottomConstraints.append(bottom)
    }

    @objc private func onPan(_ recognizer: UIPanGestureRecognizer) {
        guard let panel = stack.last else { return }

        let translation = recognizer.translation(in: recognizer.view!)
        let velocity = recognizer.velocity(in: recognizer.view!)
        let bottomConstraint = bottomConstraints.last

        if recognizer.state == .changed {
            bottomConstraint?.constant = yPan + translation.y
        } else if recognizer.state == .ended {
            let yEnd: CGFloat
            if (velocity.y < -100) {
                yEnd = 0
                isMinimized = false
            } else if (velocity.y > 100) {
                yEnd = panel.frame.height - 50
                isMinimized = true
            } else if (yPan + translation.y <= 50) {
                yEnd = 0
                isMinimized = false
            } else {
                yEnd = panel.frame.height - 50
                isMinimized = true
            }
            yPan = yEnd

            bottomConstraint?.constant = yPan

            UIView.animate(withDuration: 0.3, animations: {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }, completion: nil)
        }
    }

    func pop() {
        prepareForPop()

        guard stack.count >= 2 else { return }

        let currentBlock = stack.popLast()

        stackLeadingConstraint.popLast()?.constant = bounds.width
        stackLeadingConstraint.last?.constant = 0

        bottomConstraints.removeLast()

        UIView.animate(withDuration: 0.3, animations: {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }, completion: {
            _ in currentBlock?.removeFromSuperview()
            self.pan.isEnabled = true
        })
    }

    func popToRoot() {
        prepareForPop()

        guard stack.count >= 2 else { return }

        let currentBlock = stack.popLast()

        stackLeadingConstraint.last?.constant = bounds.width
        stackLeadingConstraint.first?.constant = 0

        if stack.count >= 2 {
            // if there are intermediate elements - remove them
            stack.suffix(from: 1).forEach { $0.removeFromSuperview() }
        }

        stackLeadingConstraint = [stackLeadingConstraint.first!]
        bottomConstraints = [bottomConstraints.first!]

        UIView.animate(withDuration: 0.3, animations: {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }, completion: {
            _ in currentBlock?.removeFromSuperview()
            self.pan.isEnabled = true
        })
    }

    func showToast(withMessage message: String) {
        toastDismissJob?.perform()

        guard let currentBlock = stack.last else { return }

        let toastView = ToastMessageView(message: message) { [weak self] in
            self?.toastDismissJob?.perform()
        }
        toastView.alpha = 0
        addSubview(toastView)

        NSLayoutConstraint.activate([
            toastView.leadingAnchor.constraint(equalTo: currentBlock.leadingAnchor, constant: 16),
            currentBlock.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: 16),
            toastView.centerXAnchor.constraint(equalTo: currentBlock.centerXAnchor),
            currentBlock.topAnchor.constraint(equalTo: toastView.bottomAnchor, constant: 16)
        ])

        UIView.animate(withDuration: 0.3, animations: {
            toastView.alpha = 1
        }, completion: { _ in
            self.queueToastDismiss(with: toastView)
        })
    }

    private func prepareForPop() {
        pan.isEnabled = false
        yPan = 0
        isMinimized = false

        toastDismissJob?.perform()
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
        let bottomConstraint = bottomConstraints.last
        onActivePanelHeightChange?((stack.last?.frame.height ?? 0) - (bottomConstraint?.constant ?? 0))
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for v in subviews where v.frame.contains(point) {
            if isMinimized {
                return self
            } else {
                return v.hitTest(v.convert(point, from: self), with: event)
            }
        }
        return nil
    }
}

private final class CalendarBlockWrapper: UIView {

    private let shadow = CALayer()
    private let background = CALayer()

    private let handle = UIView()

    init() {
        super.init(frame: .zero)

        layer.insertSublayer(shadow, at: 0)
        layer.insertSublayer(background, at: 1)

        handle.translatesAutoresizingMaskIntoConstraints = false
        handle.layer.cornerRadius = 2
        handle.layer.masksToBounds = true
        handle.backgroundColor = UIColor.secondary.withAlphaComponent(0.15)
        addSubview(handle)

        NSLayoutConstraint.activate([
            handle.widthAnchor.constraint(equalToConstant: 42),
            handle.heightAnchor.constraint(equalToConstant: 5),
            handle.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            handle.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        redrawLayers()
    }

    private func redrawLayers() {
        background.backgroundColor = UIColor.neutralN.cgColor
        background.cornerRadius = 24
        background.masksToBounds = true
        background.bounds = bounds
        background.anchorPoint = .zero

        shadow.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 24).cgPath
        shadow.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        shadow.shadowOpacity = 1
        shadow.shadowRadius = 2
        shadow.shadowOffset = CGSize(width: 0, height: 2)
        shadow.bounds = bounds
        shadow.anchorPoint = .zero

        bringSubviewToFront(handle)
    }
}
