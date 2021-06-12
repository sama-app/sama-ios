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

    func pushBlock(_ block: CalendarNavigationBlock, animated: Bool) {
        block.translatesAutoresizingMaskIntoConstraints = false
        block.navigation = self
        block.didLoad()

        let fullBlock = UIView()
        fullBlock.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fullBlock)

        let blockWrapper = UIView()
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

        let currentBlock = stack.popLast()
        stackLeadingConstraint.popLast()?.constant = bounds.width
        stackLeadingConstraint.last?.constant = 0
        UIView.animate(withDuration: 0.3, animations: {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }, completion: { _ in currentBlock?.removeFromSuperview() })
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        onActivePanelHeightChange?(stack.last?.frame.height ?? 0)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let block = stack.last else { return nil }
        return block.hitTest(block.convert(point, from: self), with: event)
    }
}
