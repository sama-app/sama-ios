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

    // pin to 15 mins
    private let hourSplit = 4
    private let hotEdge: CGFloat = 40

    private var dragState: DragState = .makeClear()
    private var dragUi: DragUI? {
        didSet {
            oldValue?.repositionLink.invalidate()
        }
    }

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
            guard i != dragState.eventIndex else { continue }

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

    @objc private func changeEventPos() {
        guard let recognizer = dragUi?.recognizer else { return }

        let loc = recognizer.location(in: container)
        let eventView = recognizer.view!
        eventView.frame.origin = CGPoint(
            x: loc.x - dragState.origin.x,
            y: loc.y - dragState.origin.y
        )

        if let change = contentOffsetChange(from: loc) {
            switch change {
            case let .horizontal(step):
                dragState.isAllowed = false
                UIView.animate(withDuration: 0.2, animations: {
                    self.calendar.contentOffset.x += CGFloat(step) * self.cellSize.width
                    self.calendar.layoutIfNeeded()
                }, completion: { _ in
                    self.dragState.isAllowed = true
                })
            case let .vertical(points):
                let y = calendar.contentOffset.y + points
                let minY = CGFloat(0)
                let maxY = calendar.contentSize.height - calendar.contentInset.bottom
                if (y >= minY && y <= maxY) {
                    self.calendar.contentOffset.y = y
                }
            }
        }
    }

    @objc private func handleEventDrag(_ recognizer: UIGestureRecognizer) {
        switch recognizer.state {
        case .began:
            guard let idx = eventViews.firstIndex(of: recognizer.view!) else { return }

            dragState = .start(
                origin: recognizer.location(in: recognizer.view),
                eventIndex: idx
            )

            let repositionLink = CADisplayLink(target: self, selector: #selector(changeEventPos))
            repositionLink.add(to: RunLoop.current, forMode: .common)
            dragUi = DragUI(repositionLink: repositionLink, recognizer: recognizer)
        case .cancelled:
            resetDragState()
            repositionEventViews()
        case .ended:
            let loc = recognizer.location(in: container)

            let totalDaysOffset = Int(round(calendar.contentOffset.x + loc.x) / cellSize.width)
            let daysOffset = totalDaysOffset - currentDayIndex

            let calcYOffset = calendar.contentOffset.y + loc.y - dragState.origin.y
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

            resetDragState()
        case .changed:
            // display link handles changes
            break
        default:
            resetDragState()
        }
    }

    private func contentOffsetChange(from loc: CGPoint) -> CalendarAutoScroll? {
        guard dragState.isAllowed else { return nil }

        // horizontal scrolling takes precedence
        if loc.x < hotEdge {
            return .horizontal(-1)
        } else if loc.x > container.frame.width - hotEdge {
            return .horizontal(1)
        }

        // vertical
        let bottomThreshold = (container.frame.height - (container.safeAreaInsets.bottom + calendar.contentInset.bottom) - hotEdge)
        if loc.y < hotEdge {
            return .vertical(-max(2 * log(hotEdge - loc.y), 0))
        } else if loc.y > bottomThreshold {
            return .vertical(min(2 * log(loc.y - bottomThreshold), hotEdge))
        }

        return nil
    }

    private func resetDragState() {
        dragUi = nil
        dragState = .makeClear()
    }
}

private enum CalendarAutoScroll {
    case horizontal(Int)
    case vertical(CGFloat)
}

private struct DragState {
    static func makeClear() -> DragState {
        return DragState(origin: .zero, eventIndex: -1, isAllowed: true)
    }

    static func start(origin: CGPoint, eventIndex: Int) -> DragState {
        return DragState(origin: origin, eventIndex: eventIndex, isAllowed: true)
    }

    let origin: CGPoint
    let eventIndex: Int
    var isAllowed: Bool
}

private struct DragUI {
    let repositionLink: CADisplayLink
    let recognizer: UIGestureRecognizer
}
