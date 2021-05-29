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

    var headerInset: CGFloat = 0 {
        didSet {
            header?.frame.origin.y = headerInset
        }
    }

    private var header: UIView?

    override func draw(_ rect: CGRect) {
        UIColor.base.setFill()
        UIRectFill(rect)

        UIColor.calendarGrid.setFill()
        for i in (1 ... 24) {
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

        let cellHeight: CGFloat = 48
        let v = UIView(frame: CGRect(x: 0, y: headerInset, width: rect.width, height: cellHeight))
        v.backgroundColor = .base

        let sepBtm = UIView(frame: CGRect(x: 0, y: cellHeight - 1, width: rect.width, height: 1))
        sepBtm.backgroundColor = .calendarGrid
        let sepRht = UIView(frame: CGRect(x: rect.width - 1, y: 0, width: 1, height: cellHeight))
        sepRht.backgroundColor = .calendarGrid
        v.addSubview(sepBtm)
        v.addSubview(sepRht)

        addSubview(v)

        header = v
    }
}
