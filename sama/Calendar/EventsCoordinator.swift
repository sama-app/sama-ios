//
//  EventsCoordinator.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/21/21.
//

import UIKit

class EventsCoordinator {

    var onChanges: (() -> Void)?

    private(set) var eventProperties: [EventProperties] = [] {
        didSet {
            onChanges?()
        }
    }
    private var eventViews: [UIView] = []

    private let currentDayIndex: Int
    private let cellSize: CGSize
    private let calendar: UIScrollView
    private let container: UIView

    private var draggableOrigin: CGPoint = .zero
    // pin to 15 mins
    private let hourSplit = 4

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

            let dragRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleEventDrag(_:)))
            eventView.addGestureRecognizer(dragRecognizer)

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
                x: xForDaysOffset(eventProps.daysOffset),
                y: yForTimestampInDay(start),
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

    private func xForDaysOffset(_ daysOffset: Int) -> CGFloat {
        return CGFloat(currentDayIndex + daysOffset) * cellSize.width - calendar.contentOffset.x
    }

    private func yForTimestampInDay(_ timestamp: Decimal) -> CGFloat {
        return CGFloat(truncating: timestamp as NSNumber) * cellSize.height + 1 - calendar.contentOffset.y
    }

    @objc private func handleEventDrag(_ recognizer: UIGestureRecognizer) {
        switch recognizer.state {
        case .began:
            draggableOrigin = recognizer.location(in: recognizer.view)
        case .cancelled:
            repositionEventViews()
        case .ended:
            let loc = recognizer.location(in: container)

            let totalDaysOffset = Int(round(calendar.contentOffset.x + loc.x) / cellSize.width)
            let daysOffset = totalDaysOffset - currentDayIndex

            let calcYOffset = calendar.contentOffset.y + loc.y - draggableOrigin.y
            let maxYOffset = CGFloat(24) * cellSize.height - recognizer.view!.frame.height
            let yOffset = min(max((calcYOffset), 0), maxYOffset)
            let totalMinsOffset = NSDecimalNumber(value: Double(yOffset))
                .multiplying(by: NSDecimalNumber(value: hourSplit))
                .dividing(by: NSDecimalNumber(value: Double(cellSize.height)))
                .rounding(accordingToBehavior: nil)
                .dividing(by: NSDecimalNumber(value: hourSplit))

            guard let idx = eventViews.firstIndex(of: recognizer.view!) else { return }

            var event = eventProperties[idx]
            event.daysOffset = daysOffset
            event.start = totalMinsOffset.decimalValue
            eventProperties[idx] = event

            UIView.animate(withDuration: 0.1) {
                recognizer.view?.frame.origin = CGPoint(
                    x: self.xForDaysOffset(daysOffset),
                    y: self.yForTimestampInDay(totalMinsOffset.decimalValue)
                )
            }
        case .changed:
            let loc = recognizer.location(in: container)
            recognizer.view?.frame.origin = CGPoint(
                x: loc.x - draggableOrigin.x,
                y: loc.y - draggableOrigin.y
            )
        default:
            break
        }
    }
}
