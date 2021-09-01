//
//  UIColors+Branded.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/29/21.
//

import UIKit

extension UIColor {

    /// #FFF8F0
    static var base = UIColor(red: 255/255.0, green: 248/255.0, blue: 240/255.0, alpha: 1)

    /// #D16E54
    static var primary = UIColor(red: 209/255.0, green: 110/255.0, blue: 84/255.0, alpha: 1)

    /// #CA5A40
    static var primaryDarker = UIColor(red: 202/255.0, green: 90/255.0, blue: 64/255.0, alpha: 1)

    /// #E7B3A0
    static var primaryPale = UIColor(red: 210/255.0, green: 113/255.0, blue: 87/255.0, alpha: 0.5)

    /// #E4A998
    static var primaryPaleDarker = UIColor(red: 202/255.0, green: 90/255.0, blue: 64/255.0, alpha: 0.5)

    /// #6B5844
    static var secondary = UIColor(red: 107/255.0, green: 88/255.0, blue: 68/255.0, alpha: 1)

    /// #6B5844 0.1
    static var secondaryPale = UIColor(red: 107/255.0, green: 88/255.0, blue: 68/255.0, alpha: 0.1)

    /// #333230
    static var neutral1 = UIColor(red: 51/255.0, green: 50/255.0, blue: 48/255.0, alpha: 1)

    /// #333230 0.8
    static var neutral2 = UIColor(red: 51/255.0, green: 50/255.0, blue: 48/255.0, alpha: 1).withAlphaComponent(0.8)

    /// #FFFFFF
    static var neutralN = UIColor.white

    /// #684c2b 0.17
    static var eventBackground = UIColor(red: 104/255.0, green: 76/255.0, blue: 43/255.0, alpha: 0.17)

    /// #684c2b 0.1
    static var calendarGrid = UIColor(red: 104/255.0, green: 76/255.0, blue: 43/255.0, alpha: 0.1)
}
