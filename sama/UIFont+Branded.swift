//
//  UIFont+Branded.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit

extension UIFont {

    enum RecoletaAltWeight: String {
        case regular = "Regular"
        case semibold = "SemiBold"
    }

    class func brandedFont(ofSize size: CGFloat, weight: RecoletaAltWeight) -> UIFont {
        return UIFont(name: "RecoletaAlt-\(weight.rawValue)", size: size)!
    }
}
