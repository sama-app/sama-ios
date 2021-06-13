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
        for i in (1 ... 24) {
            UIRectFillUsingBlendMode(CGRect(x: 0, y: vOffset + CGFloat(i) * cellSize.height, width: frame.width, height: 1), .normal)
        }

        //text attributes
        let font=UIFont.systemFont(ofSize: 15)
        let text_style=NSMutableParagraphStyle()
        text_style.alignment=NSTextAlignment.center
        let defaultAttrs: [NSAttributedString.Key : Any] = [
            .font: font,
            .paragraphStyle: text_style,
            .foregroundColor: UIColor.neutral2
        ]
        let currentZoneAttrs: [NSAttributedString.Key : Any] = [
            .font: font,
            .paragraphStyle: text_style,
            .foregroundColor: UIColor.black.withAlphaComponent(0.4)
        ]

        let textBoxH: CGFloat = 24
        let baseInset = max((textBoxH - font.lineHeight) / 2, 0)

        for i in (0 ... 23) {
            let cellRect = CGRect(x: 0, y: vOffset + (CGFloat(i) * cellSize.height), width: bounds.width, height: cellSize.height)
            if targetTimezoneHoursDiff == 0 {
                i.hourToTime.draw(
                    inRect: cellRect,
                    yInset: baseInset,
                    withFontHeight: textBoxH,
                    attributes: defaultAttrs
                )
            } else {
                (i + targetTimezoneHoursDiff).hourToTime.draw(
                    inRect: cellRect,
                    yInset: baseInset - textBoxH / 2,
                    withFontHeight: textBoxH,
                    attributes: defaultAttrs
                )
                i.hourToTime.draw(
                    inRect: cellRect,
                    yInset: baseInset + textBoxH / 2,
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

        let cellHeight: CGFloat = 48
        let v = UIView(frame: CGRect(x: 0, y: headerInset, width: bounds.width, height: cellHeight))
        v.backgroundColor = .base

        let sepBtm = UIView(frame: CGRect(x: 0, y: cellHeight - 1, width: bounds.width, height: 1))
        sepBtm.backgroundColor = .calendarGrid
        let sepRht = UIView(frame: CGRect(x: bounds.width - 1, y: 0, width: 1, height: cellHeight))
        sepRht.backgroundColor = .calendarGrid
        v.addSubview(sepBtm)
        v.addSubview(sepRht)

        addSubview(v)

        header = v
    }
}

private extension Int {
    var hourToTime: String {
        let leading = (self >= 10) ? 0 : 1
        let prefix = (0 ..< leading).map { _ in " " }.joined()
        return "\(prefix)\(self):00"
    }
}

private extension String {
    func draw(inRect rect: CGRect, yInset: CGFloat, withFontHeight fontHeight: CGFloat, attributes: [NSAttributedString.Key : Any]) {
        let textY = rect.minY + (rect.height - fontHeight) / 2 + yInset
        let textRect = CGRect(x: 0, y: textY, width: rect.width, height: fontHeight)
        draw(in: textRect.integral, withAttributes: attributes)
    }
}
