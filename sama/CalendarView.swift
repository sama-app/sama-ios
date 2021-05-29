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

    override func draw(_ rect: CGRect) {
        //super.draw(rect)
        UIColor.base.setFill()
//        UIColor.clear.setFill()
        UIRectFill(rect)

        UIColor.calendarGrid.setFill()
        for i in (0 ... 24) {
            UIRectFillUsingBlendMode(CGRect(x: 0, y: vOffset + CGFloat(i) * cellSize.height, width: frame.width, height: 1), .normal)
        }

        //text attributes
        let font=UIFont.systemFont(ofSize: 15, weight: .semibold)
        let text_style=NSMutableParagraphStyle()
//        text_style.alignment=NSTextAlignment.center
        let text_color = UIColor.secondary
        let attributes: [NSAttributedString.Key : Any] = [
            .font: font,
            .paragraphStyle: text_style,
            .foregroundColor: text_color
        ]

        //vertically center (depending on font)
//        let text_h=font.lineHeight

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
                        width: cellSize.width - 1,
                        height: cellSize.height * CGFloat(lengthHour) - 2
                    ),
                    byRoundingCorners: .allCorners,
                    cornerRadii: CGSize(width: 4, height: 4)
                ).fill(with: .normal, alpha: 1)
                let text_y = y + 6
                let text_rect=CGRect(x: x + 4, y: text_y, width: cellSize.width - 8, height: 30)
                "Lunch with Peter".draw(in: text_rect.integral, withAttributes: attributes)
            }
        }



//        UIRectFillUsingBlendMode(CGRect(x: 0, y: offsetY + CGFloat(i) * hourHeight, width: frame.width, height: 1), .normal)
//        for i in (0 ..< Int(rect.width / 10)) {
//            for j in (0 ..< Int(rect.height / 10)) {
//                UIColor(red: CGFloat.random(in: (0 ..< 256)) / 255.0, green: CGFloat.random(in: (0 ..< 256)) / 255.0, blue: CGFloat.random(in: (0 ..< 256)) / 255.0, alpha: 1.0).setFill()
//                UIRectFill(CGRect(x: i * 10, y: j * 10, width: 10, height: 10))
//            }
//        }
    }
}
