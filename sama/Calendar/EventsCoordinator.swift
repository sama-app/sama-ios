//
//  EventsCoordinator.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/21/21.
//

import UIKit

class EventsCoordinator {
    private(set) var eventProperties: [EventProperties] = []
    private var eventViews: [UIView] = []

    private let currentDayIndex: Int
    private let cellSize: CGSize
    private let calendar: UIScrollView
    private let container: UIView

    init(currentDayIndex: Int, cellSize: CGSize, calendar: UIScrollView, container: UIView) {
        self.currentDayIndex = currentDayIndex
        self.cellSize = cellSize
        self.calendar = calendar
        self.container = container
    }

    func setupEventViews(_ props: [EventProperties]) {
        eventViews = props.map { _ in
            let eventView = EventView()
            eventView.isUserInteractionEnabled = true
            self.container.addSubview(eventView)
            return eventView
        }
        eventProperties = props

        repositionEventViews()
    }

    func remove(_ props: EventProperties) {
        if let idx = eventProperties.firstIndex(of: props) {
            eventProperties.remove(at: idx)
            eventViews[idx].removeFromSuperview()
            eventViews.remove(at: idx)
        }
    }

    func repositionEventViews() {
        let count = eventProperties.count
        for i in (0 ..< count) {
            let eventProps = eventProperties[i]
            let eventView = eventViews[i]

            let start = eventProps.start
            let duration = eventProps.duration
            eventView.frame = CGRect(
                x: CGFloat(currentDayIndex + eventProps.daysOffset) * cellSize.width - calendar.contentOffset.x,
                y: CGFloat(truncating: start as NSNumber) * cellSize.height + 1 - calendar.contentOffset.y,
                width: cellSize.width,
                height: CGFloat(truncating: duration as NSNumber) * cellSize.height
            )
        }
    }

    func resetEventViews() {
        for v in eventViews {
            v.removeFromSuperview()
        }
        eventViews = []
        eventProperties = []
    }
}
