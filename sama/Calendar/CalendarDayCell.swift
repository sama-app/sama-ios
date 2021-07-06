//
//  CalendarDayCell.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/14/21.
//

import UIKit

struct CalendarBlockedTime {
    let title: String
    let start: Decimal
    let duration: Decimal
    var depth: Int
}

let eventRightBottomInset = CGPoint(x: 3, y: 2)

final class CalendarDayCell: UICollectionViewCell {

    var cellSize: CGSize = .zero
    var vOffset: CGFloat = 0

    var blockedTimes: [CalendarBlockedTime] = []
    var date: Date! {
        didSet {
            setInfo()
        }
    }
    var isCurrentDay = false

    var headerInset: CGFloat = 0 {
        didSet {
            CALayer.performWithoutImplicitAnimations {
                for v in headerViews {
                    v.frame.origin.y = headerInset
                }
            }
        }
    }

    private var isHeaderSetUp = false
    private var headerViews: [UIView] = []

    private var l1: UILabel?
    private var l2: UILabel?

    override func draw(_ rect: CGRect) {
        //super.draw(rect)
        setupHeaderIfNeeded()

        UIColor.base.setFill()
//        UIColor.clear.setFill()
        UIRectFill(rect)

        UIColor.calendarGrid.setFill()
        UIRectFillUsingBlendMode(CGRect(x: frame.width - 1, y: 0, width: 1, height: frame.height), .normal)
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

        for block in blockedTimes {
            let lengthHour = CGFloat(truncating: block.duration as NSNumber)

            let x: CGFloat = CGFloat(block.depth) * 8
            let y = vOffset + CGFloat(truncating: block.start as NSNumber) * cellSize.height + 1
            UIColor.eventBackground.setFill()
            UIBezierPath(
                roundedRect: CGRect(
                    x: x,
                    y: y,
                    width: cellSize.width - eventRightBottomInset.x - x,
                    height: cellSize.height * CGFloat(lengthHour) - eventRightBottomInset.y
                ),
                byRoundingCorners: .allCorners,
                cornerRadii: CGSize(width: 4, height: 4)
            ).fill(with: .normal, alpha: 1)
            let text_y = y + padding
            let textRect = CGRect(x: x + padding, y: text_y, width: cellSize.width - padding, height: 16)
            block.title.draw(in: textRect.integral, withAttributes: attributes)
        }
    }

    private func setupHeaderIfNeeded() {
        guard !isHeaderSetUp else { return }
        isHeaderSetUp = true

        let cellHeight = Sama.env.ui.calenarHeaderHeight

//        let v: [(String, String)] = (0 ..< days).map {
//            let date = calendar.date(byAdding: .day, value: $0, to: dt)!
//            return (
//                dayF.string(from: date),
//                wkF.string(from: date)
//            )
//        }

//        for (i, o) in v.enumerated() {
            let v = UIView(frame: CGRect(x: 0, y: headerInset, width: cellSize.width, height: cellHeight))
            v.backgroundColor = .base

            let sepBtm = UIView(frame: CGRect(x: 0, y: cellHeight - 1, width: cellSize.width, height: 1))
            sepBtm.backgroundColor = .calendarGrid
            let sepRht = UIView(frame: CGRect(x: cellSize.width - 1, y: 0, width: 1, height: cellHeight))
            sepRht.backgroundColor = .calendarGrid
            v.addSubview(sepBtm)
            v.addSubview(sepRht)

            addSubview(v)

            let l1 = UILabel()
            l1.translatesAutoresizingMaskIntoConstraints = false
            l1.font = .systemFont(ofSize: 15, weight: .bold)
//            l1.text = o.0
            l1.textAlignment = .center
            l1.layer.cornerRadius = 12
            l1.layer.masksToBounds = true

            let l2 = UILabel()
            l2.font = .systemFont(ofSize: 12)
            l2.translatesAutoresizingMaskIntoConstraints = false
//            l2.text = o.1
            l2.textColor = .neutral2

            let sv = UIStackView(arrangedSubviews: [l1, l2])
            sv.axis = .vertical
            sv.alignment = .center
            sv.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(sv)

            NSLayoutConstraint.activate([
                l1.widthAnchor.constraint(equalToConstant: 24),
                l1.heightAnchor.constraint(equalToConstant: 24),
                v.centerXAnchor.constraint(equalTo: sv.centerXAnchor),
                v.centerYAnchor.constraint(equalTo: sv.centerYAnchor)
            ])

        self.l1 = l1
        self.l2 = l2
            headerViews.append(v)
//        }
        setInfo()
    }

    private func setInfo() {
        let dayF = DateFormatter()
        dayF.dateFormat = "d"
        let wkF = DateFormatter()
        wkF.dateFormat = "E"

        l1?.text = dayF.string(from: date)
        l2?.text = wkF.string(from: date)

        if isCurrentDay {
            l1?.backgroundColor = .primary
            l1?.textColor = .neutralN
        } else {
            l1?.backgroundColor = .clear
            l1?.textColor = .neutral1
        }
    }
}
