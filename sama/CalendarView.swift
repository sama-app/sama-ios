//
//  CalendarView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/14/21.
//

import UIKit

final class CalendarView: UIView {

    var cellSize: CGSize = .zero
    var vOffset: CGFloat = 0

    var headerInset: CGFloat = 0 {
        didSet {
            for v in headerViews {
                v.frame.origin.y = headerInset
            }
        }
    }

    private var isHeaderSetUp = false
    private var headerViews: [UIView] = []

    override func draw(_ rect: CGRect) {
        //super.draw(rect)
        setupHeaderIfNeeded()

        UIColor.base.setFill()
//        UIColor.clear.setFill()
        UIRectFill(rect)

        UIColor.calendarGrid.setFill()
        for i in (1 ... 24) {
            UIRectFillUsingBlendMode(CGRect(x: 0, y: vOffset + CGFloat(i) * cellSize.height, width: frame.width, height: 1), .normal)
        }

        //text attributes
        let font=UIFont.systemFont(ofSize: 12, weight: .regular)
        let text_style = NSMutableParagraphStyle()
        text_style.lineBreakMode = .byTruncatingTail
//        text_style.alignment=NSTextAlignment.center
        let text_color = UIColor.secondary
        let attributes: [NSAttributedString.Key : Any] = [
            .font: font,
            .paragraphStyle: text_style,
            .foregroundColor: text_color
        ]

        //vertically center (depending on font)
//        let text_h=font.lineHeight

        let padding: CGFloat = 8

        for i in (0 ..< 7) {
            for hour in (8 ... 20).filter { $0 != (12 + i) } {
                let lengthHour = 1
                let x = cellSize.width * CGFloat(i)
                let y = vOffset + CGFloat(hour) * cellSize.height + 1
                UIColor.eventBackground.setFill()
                UIBezierPath(
                    roundedRect: CGRect(
                        x: x,
                        y: y,
                        width: cellSize.width - 2,
                        height: cellSize.height * CGFloat(lengthHour) - 2
                    ),
                    byRoundingCorners: .allCorners,
                    cornerRadii: CGSize(width: 4, height: 4)
                ).fill(with: .normal, alpha: 1)
                let text_y = y + padding
                let textRect = CGRect(x: x + padding, y: text_y, width: cellSize.width - padding, height: 16)
                "Lunch with Peter".draw(in: textRect.integral, withAttributes: attributes)
            }
        }
    }

    private func setupHeaderIfNeeded() {
        guard !isHeaderSetUp else { return }
        isHeaderSetUp = true

        let cellHeight: CGFloat = 48
        for i in (0 ..< 7) {
            let v = UIView(frame: CGRect(x: cellSize.width * CGFloat(i), y: headerInset, width: cellSize.width, height: cellHeight))
            v.backgroundColor = .base

            let sepBtm = UIView(frame: CGRect(x: 0, y: cellHeight - 1, width: cellSize.width, height: 1))
            sepBtm.backgroundColor = .calendarGrid
            let sepRht = UIView(frame: CGRect(x: cellSize.width - 1, y: 0, width: 1, height: cellHeight))
            sepRht.backgroundColor = .calendarGrid
            v.addSubview(sepBtm)
            v.addSubview(sepRht)

            addSubview(v)

            headerViews.append(v)
        }
    }
}
