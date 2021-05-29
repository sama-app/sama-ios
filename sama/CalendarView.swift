//
//  CalendarView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/14/21.
//

import UIKit

final class CalendarView: UIView {

    override func draw(_ rect: CGRect) {
        //super.draw(rect)
        UIColor(red: 248/255.0, green: 224/255.0, blue: 197/255.0, alpha: 1).setFill()
//        UIColor.clear.setFill()
        UIRectFill(rect)

        let offsetY: CGFloat = 20
        let offsetX: CGFloat = 0
        let hourHeight = (rect.size.height - offsetY * 2) / 24

        UIColor(red: 107/255.0, green: 88/255.0, blue: 69/255.0, alpha: 0.1).setFill()
        for i in (0 ... 24) {
            UIRectFillUsingBlendMode(CGRect(x: 0, y: offsetY + CGFloat(i) * hourHeight, width: frame.width, height: 1), .normal)
        }
//
//        //text attributes
//        let font=UIFont.systemFont(ofSize: 15)
//        let text_style=NSMutableParagraphStyle()
//        text_style.alignment=NSTextAlignment.center
//        let text_color=UIColor(red: 50/255.0, green: 45/255.0, blue: 39/255.0, alpha: 1)
//        let attributes: [NSAttributedString.Key : Any] = [
//            .font: font,
//            .paragraphStyle: text_style,
//            .foregroundColor: text_color
//        ]
//
//        //vertically center (depending on font)
//        let text_h=font.lineHeight
//
//        for i in (0 ... 23) {
//            let text_y = offsetY + (CGFloat(i) * hourHeight) + (hourHeight-text_h)/2
//            let text_rect=CGRect(x: 10, y: text_y, width: offsetX - 10, height: text_h)
//            let leading = (i >= 10) ? 0 : 1
//            let prefix = (0 ..< leading).map { _ in " " }.joined()
//            "\(prefix)\(i):00".draw(in: text_rect.integral, withAttributes: attributes)
//        }

        //text attributes
        let font=UIFont.systemFont(ofSize: 15, weight: .semibold)
        let text_style=NSMutableParagraphStyle()
//        text_style.alignment=NSTextAlignment.center
        let text_color=UIColor(red: 107/255.0, green: 88/255.0, blue: 69/255.0, alpha: 1)
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
                let x = offsetX + CGFloat(220 * i)
                let y = offsetY + CGFloat(hour) * hourHeight + 1
                UIColor(red: 107/255.0, green: 88/255.0, blue: 69/255.0, alpha: 0.15).setFill()
                UIBezierPath(
                    roundedRect: CGRect(
                        x: x,
                        y: y,
                        width: 220 - 1,
                        height: hourHeight * CGFloat(lengthHour) - 2
                    ),
                    byRoundingCorners: .allCorners,
                    cornerRadii: CGSize(width: 4, height: 4)
                ).fill(with: .normal, alpha: 1)
                let text_y = y + 6
                let text_rect=CGRect(x: x + 4, y: text_y, width: 210, height: 30)
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
