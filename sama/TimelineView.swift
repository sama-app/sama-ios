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
    var targetTimezoneHoursDiff: Int = 0 {
        didSet {
            setNeedsDisplay()
            layoutIfNeeded()
        }
    }

    var headerInset: CGFloat = 0 {
        didSet {
            header?.frame.origin.y = headerInset
        }
    }

    private var isHeaderSetup = false
    private var header: UIView?

    override func draw(_ rect: CGRect) {
        setupHeaderIfNeeded()

        UIColor.base.setFill()
        UIRectFill(rect)

        UIColor.calendarGrid.setFill()
        let sepWidth: CGFloat = 4
        for i in (1 ... 24) {
            UIRectFillUsingBlendMode(CGRect(x: frame.width - sepWidth, y: vOffset + CGFloat(i) * cellSize.height, width: sepWidth, height: 1), .normal)
        }

        //text attributes
        let text_style=NSMutableParagraphStyle()
        text_style.alignment=NSTextAlignment.right
        let defaultAttrs: [NSAttributedString.Key : Any] = [
            .font: UIFont.systemFont(ofSize: 15),
            .paragraphStyle: text_style,
            .foregroundColor: UIColor.neutral2
        ]
        let currentZoneAttrs: [NSAttributedString.Key : Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .paragraphStyle: text_style,
            .foregroundColor: UIColor.secondary.withAlphaComponent(0.7)
        ]

        let textBoxH: CGFloat = 20
        let baseInset = max((textBoxH - UIFont.systemFont(ofSize: 15).lineHeight) / 2, 0)
        let rightInset: CGFloat = sepWidth + 4

        for i in (0 ... 23) {
            let cellRect = CGRect(x: 0, y: vOffset + (CGFloat(i) * cellSize.height), width: bounds.width - rightInset, height: cellSize.height)
            if targetTimezoneHoursDiff == 0 {
                i.hourToTime.draw(
                    inRect: cellRect,
                    yInset: baseInset,
                    withFontHeight: textBoxH,
                    attributes: defaultAttrs
                )
            } else {
                (i + targetTimezoneHoursDiff).toHour.hourToTime.draw(
                    inRect: cellRect,
                    yInset: baseInset,
                    withFontHeight: textBoxH,
                    attributes: defaultAttrs
                )
                i.hourToTime.draw(
                    inRect: cellRect,
                    yInset: baseInset + textBoxH,
                    withFontHeight: textBoxH,
                    attributes: currentZoneAttrs
                )
            }
        }

        UIColor.calendarGrid.setFill()
        UIRectFillUsingBlendMode(CGRect(x: frame.width - 1, y: 0, width: 1, height: frame.height), .normal)
    }

    private func setupHeaderIfNeeded() {
        guard !isHeaderSetup else { return }
        isHeaderSetup = true

        let cellHeight = Sama.env.ui.calenarHeaderHeight
        let v = UIView(frame: CGRect(x: 0, y: headerInset, width: bounds.width, height: cellHeight))
        v.backgroundColor = .base

        let sepBtm = UIView(frame: CGRect(x: 0, y: v.frame.height - 1, width: bounds.width, height: 1))
        sepBtm.backgroundColor = .calendarGrid
        let sepRhtHeight = Sama.env.ui.calendarHeaderRightSeparatorHeight
        let sepRht = UIView(frame: CGRect(x: bounds.width - 1, y: v.frame.height - sepRhtHeight, width: 1, height: sepRhtHeight))
        sepRht.backgroundColor = .calendarGrid
        v.addSubview(sepBtm)
        v.addSubview(sepRht)

        addSubview(v)

        header = v
    }
}

private extension Int {
    var toHour: Int {
        let hr = self % 24
        return hr < 0 ? (24 + hr) : hr
    }
    var hourToTime: String {
        let leading = (self >= 10) ? 0 : 1
        let prefix = (0 ..< leading).map { _ in " " }.joined()
        return "\(prefix)\(self):00"
    }
}

private extension String {
    func draw(inRect rect: CGRect, yInset: CGFloat, withFontHeight fontHeight: CGFloat, attributes: [NSAttributedString.Key : Any]) {
        let textY = rect.minY - fontHeight / 2 + yInset
        let textRect = CGRect(x: 0, y: textY, width: rect.width, height: fontHeight)
        draw(in: textRect.integral, withAttributes: attributes)
    }
}
