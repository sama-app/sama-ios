//
//  TimelineView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/16/21.
//

import UIKit

final class TimelineView: UIView {

    var cellSize: CGSize = .zero
    var vOffset: CGFloat = 0

    override func draw(_ rect: CGRect) {
        UIColor(red: 248/255.0, green: 224/255.0, blue: 197/255.0, alpha: 1).setFill()
        UIRectFill(rect)

        UIColor(red: 107/255.0, green: 88/255.0, blue: 69/255.0, alpha: 0.1).setFill()
        for i in (0 ... 24) {
            UIRectFillUsingBlendMode(CGRect(x: 0, y: vOffset + CGFloat(i) * cellSize.height, width: frame.width, height: 1), .normal)
        }

        //text attributes
        let font=UIFont.systemFont(ofSize: 15)
        let text_style=NSMutableParagraphStyle()
        text_style.alignment=NSTextAlignment.center
        let text_color=UIColor(red: 50/255.0, green: 45/255.0, blue: 39/255.0, alpha: 1)
        let attributes: [NSAttributedString.Key : Any] = [
            .font: font,
            .paragraphStyle: text_style,
            .foregroundColor: text_color
        ]

        //vertically center (depending on font)
        let text_h=font.lineHeight

        for i in (0 ... 23) {
            let text_y = vOffset + (CGFloat(i) * cellSize.height) + (cellSize.height-text_h)/2
            let text_rect=CGRect(x: 10, y: text_y, width: rect.width - 10, height: text_h)
            let leading = (i >= 10) ? 0 : 1
            let prefix = (0 ..< leading).map { _ in " " }.joined()
            "\(prefix)\(i):00".draw(in: text_rect.integral, withAttributes: attributes)
        }
    }
}
