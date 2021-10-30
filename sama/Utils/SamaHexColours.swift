//
//  SamaHexColours.swift
//  sama
//
//  Created by Viktoras Laukevičius on 10/30/21.
//

import UIKit

extension Int {
    static var samaHexBase: Int {
        0x6B5844
    }
    var samafiedHex: Int {
        let colourBase = Int.samaHexBase
        let redBase = Double((colourBase >> 16) & 0xFF)
        let greenBase = Double((colourBase >> 8) & 0xFF)
        let blueBase = Double(colourBase & 0xFF)

        let externalColour = self
        let externalColourRed = Double((externalColour >> 16) & 0xFF)
        let externalColourGreen = Double((externalColour >> 8) & 0xFF)
        let externalColourBlue = Double(externalColour & 0xFF)

        let red = Int((redBase + externalColourRed) / 2)
        let green = Int((greenBase + externalColourGreen) / 2)
        let blue = Int((blueBase + externalColourBlue) / 2)

        return (red << 16) + (green << 8) + blue
    }
}

extension String {
    var fromHex: Int? {
        let hexStr = starts(with: "#") ? String(dropFirst()) : self
        return Int(hexStr, radix: 16)
    }
}

extension Optional where Wrapped == String {
    var samafiedHex: Int {
        return self?.fromHex?.samafiedHex ?? Int.samaHexBase
    }
}

extension Int {
    func fromHexToColour() -> UIColor {
        return UIColor(
            red: CGFloat((self >> 16) & 0xFF) / 255.0,
            green: CGFloat((self >> 8) & 0xFF) / 255.0,
            blue: CGFloat(self & 0xFF) / 255.0,
            alpha: 1
        )
    }
}
