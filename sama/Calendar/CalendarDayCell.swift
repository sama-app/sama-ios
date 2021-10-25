//
//  CalendarDayCell.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/14/21.
//

import UIKit

struct CalendarBlockedTime: Equatable {
    let id: AccountCalendarId
    let title: String
    let start: Decimal
    let duration: Decimal
    var depth: Int
    var colour: Int?
}

let eventRightBottomInset = CGPoint(x: 3, y: 2)

final class CalendarDayCell: UICollectionViewCell {

    var cellSize: CGSize = .zero

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
                headerView.frame.origin.y = headerInset
            }
        }
    }

    private let headerView = CalendarDayHeader(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

    private var topInset: CGFloat = 0
    private var isGreyedOut = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(headerView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        headerView.frame.size.width = cellSize.width

        UIColor.base.setFill()
        UIRectFillUsingBlendMode(rect, .normal)
        (isGreyedOut ? UIColor.secondary10 : UIColor.base).setFill()
        UIRectFillUsingBlendMode(rect, .normal)

        UIColor.calendarGrid.setFill()
        UIRectFillUsingBlendMode(CGRect(x: frame.width - 1, y: 0, width: 1, height: frame.height), .normal)
        for i in (1 ... 24) {
            UIRectFillUsingBlendMode(CGRect(x: 0, y: topInset + CGFloat(i) * cellSize.height, width: frame.width, height: 1), .normal)
        }

        //text attributes
        let font = UIFont.systemFont(ofSize: 12, weight: .regular)
        let text_style = NSMutableParagraphStyle()
        text_style.lineBreakMode = .byWordWrapping

        //vertically center (depending on font)
//        let text_h=font.lineHeight

        let padding: CGFloat = 8

        for block in blockedTimes {
            let baseColor = (block.colour?.fromHexToColour() ?? UIColor.eventBackground)
            let text_color = baseColor
            let attributes: [NSAttributedString.Key : Any] = [
                .font: font,
                .paragraphStyle: text_style,
                .foregroundColor: text_color
            ]

            let lengthHour = CGFloat(truncating: block.duration as NSNumber)

            let x: CGFloat = CGFloat(block.depth) * 8
            let y = topInset + CGFloat(truncating: block.start as NSNumber) * cellSize.height + 1
            baseColor.withAlphaComponent(0.17).setFill()

            let boxWidth = cellSize.width - eventRightBottomInset.x - x
            let boxHeight = cellSize.height * CGFloat(lengthHour) - eventRightBottomInset.y
            UIBezierPath(
                roundedRect: CGRect(
                    x: x,
                    y: y,
                    width: boxWidth,
                    height: boxHeight
                ),
                byRoundingCorners: .allCorners,
                cornerRadii: CGSize(width: 4, height: 4)
            ).fill(with: .normal, alpha: 1)
            let text_y = y + padding
            let textRect = CGRect(x: x + padding, y: text_y, width: boxWidth - padding, height: boxHeight - padding)
            block.title.draw(in: textRect.integral, withAttributes: attributes)
        }
    }

    func showDateInHeader(_ isVisible: Bool, headerHeight: CGFloat) {
        topInset = headerHeight
        headerView.frame.size.height = headerHeight
        headerView.container.isHidden = !isVisible
    }

    private func setInfo() {
        let dayF = DateFormatter()
        dayF.dateFormat = "d"
        let wkF = DateFormatter()
        wkF.dateFormat = "E"

        let weekday = Calendar.current.component(.weekday, from: date)
        isGreyedOut = (weekday == 1 || weekday == 7)

        headerView.upperLabel.text = dayF.string(from: date)
        headerView.lowerLabel.text = wkF.string(from: date)

        if isCurrentDay {
            headerView.upperLabel.backgroundColor = .primary
            headerView.upperLabel.textColor = .neutralN
        } else {
            headerView.upperLabel.backgroundColor = .clear
            headerView.upperLabel.textColor = .neutral1
        }
    }
}

private extension Int {
    func fromHexToColour() -> UIColor {
        return UIColor(
            red: CGFloat((self >> 16) & 0xFF) / 255.0,
            green: CGFloat((self >> 8) & 0xFF) / 255.0,
            blue: CGFloat(self & 0xFF) / 255.0,
            alpha: 1
        )
    }
}
