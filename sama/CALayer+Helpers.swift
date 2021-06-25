//
//  CALayer+Helpers.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/25/21.
//

import UIKit

extension CALayer {
    class func performWithoutImplicitAnimations(_ closure: () -> Void) {
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        closure()
        CATransaction.commit()
    }
}
