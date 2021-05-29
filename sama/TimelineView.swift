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
        UIColor.base.setFill()
        UIRectFill(rect)

        UIColor.calendarGrid.setFill()
        for i in (0 ... 24) {
            UIRectFillUsingBlendMode(CGRect(x: 0, y: vOffset + CGFloat(i) * cellSize.height, width: frame.width, height: 1), .normal)
        }

        //text attributes
        let font=UIFont.systemFont(ofSize: 15)
        let text_style=NSMutableParagraphStyle()
        text_style.alignment=NSTextAlignment.center
        let text_color = UIColor.neutral2
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
