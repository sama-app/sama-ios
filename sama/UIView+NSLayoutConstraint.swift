//
//  UIView+NSLayoutConstraint.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/29/21.
//

import UIKit

extension UIView {
    func pinLeadingAndTrailing(top: CGFloat? = nil, bottom: CGFloat? = nil, and additional: [NSLayoutConstraint] = []) {
        NSLayoutConstraint.activate(([
            top.flatMap { topAnchor.constraint(equalTo: superview!.topAnchor, constant: $0) },
            leadingAnchor.constraint(equalTo: superview!.leadingAnchor),
            superview!.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottom.flatMap { superview!.bottomAnchor.constraint(equalTo: bottomAnchor, constant: $0) }
        ] as [NSLayoutConstraint?]).compactMap { $0 } + additional)
    }
}
