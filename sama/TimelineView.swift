//
//  TimelineView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/16/21.
//

import UIKit

struct TimeZonesDiff {
    let targetTitle: String
    let currentTitle: String
    let hours: Int
}

final class TimelineView: UIView {

    var cellSize: CGSize = .zero
    var vOffset: CGFloat = 0
    var timezonesDiff: TimeZonesDiff? = nil {
        didSet {
            headerView.upperLabel.text = timezonesDiff?.targetTitle ?? ""
            headerView.lowerLabel.text = timezonesDiff?.currentTitle ?? ""

            setNeedsDisplay()
            layoutIfNeeded()
        }
    }

    var headerInset: CGFloat = 0 {
        didSet {
            headerView.frame.origin.y = headerInset
        }
    }

    private let headerView = TimelineHeader(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(headerView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        headerView.frame.size.width = bounds.width

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
            if let timezonesDiff = self.timezonesDiff {
                (i + timezonesDiff.hours).toHour.hourToTime.draw(
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
            } else {
                i.hourToTime.draw(
                    inRect: cellRect,
                    yInset: baseInset,
                    withFontHeight: textBoxH,
                    attributes: defaultAttrs
                )
            }
        }

        UIColor.calendarGrid.setFill()
        UIRectFillUsingBlendMode(CGRect(x: frame.width - 1, y: 0, width: 1, height: frame.height), .normal)
    }

    func showInfoInHeader(_ isVisible: Bool) {
        if isVisible {
            headerView.frame.size.height = Sama.env.ui.calenarHeaderHeight
            headerView.container.isHidden = false
        } else {
            headerView.frame.size.height = Sama.env.ui.calenarNoHeaderHeight
            headerView.container.isHidden = true
        }
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
