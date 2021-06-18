//
//  ScrollLock.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/18/21.
//

import CoreGraphics

enum ScrollDirection {
    case horizontal
    case verical
}

struct ScrollLock {
    private(set) var direction: ScrollDirection?
    let origin: CGPoint

    init(origin: CGPoint) {
        self.origin = origin
    }

    mutating func lockIfUnlockedAndAdjust(offset: CGPoint) -> CGPoint {
        if direction == nil {
            let hDiff = abs(offset.x - origin.x)
            let vDiff = abs(offset.y - origin.y)
            direction = hDiff > vDiff ? .horizontal : .verical
        }
        return CGPoint(
            x: direction == .horizontal ? offset.x : origin.x,
            y: direction == .verical ? offset.y : origin.y
        )
    }
}
