//
//  UIFont+Branded.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit

extension UIFont {

    enum RufinaWeight: String {
        case regular = "Regular"
        case semibold = "Bold"
    }

    class func brandedFont(ofSize size: CGFloat, weight: RufinaWeight) -> UIFont {
        return UIFont(name: "Rufina-\(weight.rawValue)", size: size)!
    }
}
