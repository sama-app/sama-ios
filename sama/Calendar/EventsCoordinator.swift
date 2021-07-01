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

    private let context: CalendarContextProvider
    private let currentDayIndex: Int
    private let cellSize: CGSize
    private let calendar: UIScrollView
    private let container: UIView

    private var feedback = UIImpactFeedbackGenerator(style: .heavy)

    // pin to 15 mins
    private let hourSplit = 4
    private let hotEdge: CGFloat = 40

    private var dragState: DragState = .makeClear()
    private var dragUi: DragUI? {
        didSet {
            oldValue?.repositionLink.invalidate()
        }
    }

    init(currentDayIndex: Int, context: CalendarContextProvider, cellSize: CGSize, calendar: UIScrollView, container: UIView) {
        self.currentDayIndex = currentDayIndex
        self.context = context
        self.cellSize = cellSize
        self.calendar = calendar
        self.container = container
    }

    func setupEventViews(_ props: [EventProperties]) {
        eventViews = props.map { _ in self.makeEventView() }
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
                height: CGFloat(truncating: duration as NSNumber) * cellSize.height + eventHandleExtraSpace
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

    func isSlotPossible(dayIndex: Int, start: Decimal, duration: Decimal) -> Bool {
        let end = start + duration

        for props in (eventProperties.filter { $0.daysOffset == dayIndex}) {
            if start >= props.start && start < (props.start + props.duration) {
                return false
            }
            if end > props.start && end <= (props.start + props.duration) {
                return false
            }
        }

        for block in (context.blocksForDayIndex[currentDayIndex + dayIndex] ?? []) {
            if start >= block.start && start < (block.start + block.duration) {
                return false
            }
            if end > block.start && end <= (block.start + block.duration) {
                return false
            }
        }

        return true
    }

    func addClosestToCenter() {
        let xCenter = calendar.contentOffset.x + (calendar.frame.width) / 2
        let totalDaysOffset = Int(round(xCenter - (cellSize.width / 2)) / cellSize.width)
        let baseDaysOffset = totalDaysOffset - currentDayIndex

        let yCenter = calendar.contentOffset.y + (calendar.bounds.height - calendar.contentInset.bottom - 48) / 2
        let yOffset = yCenter - cellSize.height
        let totalMinsOffset = NSDecimalNumber(value: Double(yOffset))
            .multiplying(by: NSDecimalNumber(value: hourSplit))
            .dividing(by: NSDecimalNumber(value: Double(cellSize.height)))
            .rounding(accordingToBehavior: nil)
            .dividing(by: NSDecimalNumber(value: hourSplit))

        let duration = eventProperties.first!.duration
        let maxMinsOffset = NSDecimalNumber(value: 24).subtracting(NSDecimalNumber(decimal: duration)).decimalValue

        let baseStart = max(0, min(maxMinsOffset, totalMinsOffset.decimalValue))

        var possibleSlots: [(Int, Decimal)] = []
        for i in (baseDaysOffset - 1 ..< baseDaysOffset + 3) {
            // exact and down
            var start = baseStart
            while start < maxMinsOffset {
                if isSlotPossible(dayIndex: i, start: start, duration: duration) {
                    possibleSlots.append((i, start))
                    break
                }
                start += 0.25
            }

            // exact and up
            start = baseStart
            while start > 0 {
                if isSlotPossible(dayIndex: i, start: start, duration: duration) {
                    possibleSlots.append((i, start))
                    break
                }
                start -= 0.25
            }
        }

        guard !possibleSlots.isEmpty else { return }

        var idx = 0
        var minD: CGFloat = 10000
        for (i, slot) in possibleSlots.enumerated() {
            let rect = CGRect(
                x: xForDaysOffset(slot.0) + calendar.contentOffset.x,
                y: yForTimestampInDay(slot.1) + calendar.contentOffset.y,
                width: cellSize.width,
                height: CGFloat(truncating: duration as NSNumber) * cellSize.height + eventHandleExtraSpace
            )
            let xd = xCenter - rect.midX
            let yd = yCenter - rect.midY
            let d = sqrt(xd*xd + yd*yd)
            if d < minD {
                idx = i
                minD = d
            }
        }

        eventViews.append(makeEventView())
        eventProperties.append(EventProperties(
            start: possibleSlots[idx].1,
            duration: duration,
            daysOffset: possibleSlots[idx].0,
            timezoneOffset: eventProperties.first!.timezoneOffset
        ))

        repositionEventViews()
    }

    private func makeEventView() -> EventView {
        let eventView = EventView()
        eventView.isUserInteractionEnabled = true

        let dragRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleEventDrag(_:)))
        eventView.addGestureRecognizer(dragRecognizer)

        let handleRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleEventDurationDrag(_:)))
        eventView.handle.addGestureRecognizer(handleRecognizer)

        self.container.addSubview(eventView)
        return eventView
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
        let idx = eventViews.firstIndex(of: eventView)!
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

        dragState.target = validTarget(from: target(from: loc, for: idx), for: idx)
    }

    private func target(from loc: CGPoint, for idx: Int) -> RescheduleTarget {
        let totalDaysOffset = Int(round(calendar.contentOffset.x + loc.x) / cellSize.width)
        let daysOffset = totalDaysOffset - currentDayIndex

        let calcYOffset = calendar.contentOffset.y + loc.y - dragState.origin.y
        let eventHeight = CGFloat(truncating: eventProperties[idx].duration as NSNumber) * cellSize.height
        let maxYOffset = CGFloat(24) * cellSize.height - eventHeight
        let yOffset = min(max((calcYOffset), 0), maxYOffset)
        let totalMinsOffset = NSDecimalNumber(value: Double(yOffset))
            .multiplying(by: NSDecimalNumber(value: hourSplit))
            .dividing(by: NSDecimalNumber(value: Double(cellSize.height)))
            .rounding(accordingToBehavior: nil)
            .dividing(by: NSDecimalNumber(value: hourSplit))
        return RescheduleTarget(daysOffset: daysOffset, start: totalMinsOffset.decimalValue)
    }

    private func validTarget(from target: RescheduleTarget, for index: Int) -> RescheduleTarget {
        let duration = eventProperties[index].duration
        let targetEnd = NSDecimalNumber(decimal: target.start).adding(NSDecimalNumber(decimal: duration)).decimalValue
        let sameDayEvents = eventProperties
            .enumerated().filter { $0.offset != index && $0.element.daysOffset == target.daysOffset }
            .map { $0.element }

        var isValid = true
        for ev in sameDayEvents {
            let evEnd = NSDecimalNumber(decimal: ev.start).adding(NSDecimalNumber(decimal: ev.duration)).decimalValue
            let startInEvent = target.start >= ev.start && target.start < evEnd
            let endInEvent = targetEnd > ev.start && targetEnd <= evEnd
            let surroundsEvent = target.start < ev.start && targetEnd > evEnd
            if startInEvent || endInEvent || surroundsEvent {
                isValid = false
                break
            }
        }
        return isValid ? target : dragState.target
    }

    @objc private func changeEventDuration() {
        guard let recognizer = dragUi?.recognizer else { return }

        let eventView = (recognizer.view!.superview as! EventView)
        let loc = recognizer.location(in: eventView)

        guard let idx = eventViews.firstIndex(of: eventView) else { return }
        let originalHeight = CGFloat(truncating: eventProperties[idx].duration as NSNumber) * cellSize.height + eventHandleExtraSpace

        let extra = loc.y - dragState.origin.y
        let eventHeight = originalHeight + extra

        let minHeight = CGFloat(0.25) * cellSize.height + eventHandleExtraSpace
        let maxHeight = CGFloat(truncating: dragState.maxDuration as NSNumber) * cellSize.height + eventHandleExtraSpace
        let safeEvHeight = min(max(eventHeight, minHeight), maxHeight)

        eventView.frame.size.height = safeEvHeight

        let locInContainer = recognizer.location(in: container)
        let bottomThreshold = (container.frame.height - (container.safeAreaInsets.bottom + calendar.contentInset.bottom) - hotEdge)

        if (locInContainer.y < hotEdge) {
            let extra = -2 * log(max(hotEdge - locInContainer.y, 1))
            calendar.contentOffset.y += extra
        } else if (locInContainer.y > bottomThreshold) {
            let extra = 2 * log(max(locInContainer.y - bottomThreshold, 1))
            calendar.contentOffset.y += extra
        }
        eventView.frame.origin.y = yForTimestampInDay(eventProperties[idx].start)
    }

    private func getMaxDuration(for props: EventProperties) -> Decimal {
        let sameDayEvents = eventProperties
            .filter { $0.daysOffset == props.daysOffset }
            .sorted { $0.start < $1.start }
        let idx = sameDayEvents.firstIndex(where: { $0.start == props.start })!
        if idx < (sameDayEvents.count - 1) {
            let next = sameDayEvents[idx + 1]
            return NSDecimalNumber(decimal: next.start).subtracting(NSDecimalNumber(decimal: props.start)).decimalValue
        } else {
            return NSDecimalNumber(value: 24).subtracting(NSDecimalNumber(decimal: props.start)).decimalValue
        }
    }

    @objc private func handleEventDurationDrag(_ recognizer: UIGestureRecognizer) {
        switch recognizer.state {
        case .began:
            let eventView = (recognizer.view!.superview as! EventView)
            guard let idx = eventViews.firstIndex(of: eventView) else { return }
            feedback.impactOccurred()

            dragState = .start(
                origin: recognizer.location(in: eventView),
                eventIndex: idx,
                target: .none,
                maxDuration: getMaxDuration(for: eventProperties[idx])
            )

            let repositionLink = CADisplayLink(target: self, selector: #selector(changeEventDuration))
            repositionLink.add(to: RunLoop.current, forMode: .common)
            dragUi = DragUI(repositionLink: repositionLink, recognizer: recognizer)
        case .cancelled:
            resetDragState()
            repositionEventViews()
        case .ended:
            let eventView = (recognizer.view!.superview as! EventView)

            let totalMinsOffset = NSDecimalNumber(value: Double(eventView.frame.height))
                .multiplying(by: NSDecimalNumber(value: hourSplit))
                .dividing(by: NSDecimalNumber(value: Double(cellSize.height)))
                .rounding(accordingToBehavior: nil)
                .dividing(by: NSDecimalNumber(value: hourSplit))

            var event = eventProperties[dragState.eventIndex]
            event.duration = totalMinsOffset.decimalValue
            eventProperties[dragState.eventIndex] = event

            let evHeight = CGFloat(truncating: event.duration as NSNumber) * cellSize.height
            eventView.frame.size.height = evHeight

            resetDragState()
            repositionEventViews()
        case .changed:
            // display link handles changes
            break
        default:
            resetDragState()
        }
    }

    @objc private func handleEventDrag(_ recognizer: UIGestureRecognizer) {
        switch recognizer.state {
        case .began:
            guard let idx = eventViews.firstIndex(of: recognizer.view!) else { return }
            feedback.impactOccurred()

            let props = eventProperties[idx]
            dragState = .start(
                origin: recognizer.location(in: recognizer.view),
                eventIndex: idx,
                target: RescheduleTarget(daysOffset: props.daysOffset, start: props.start),
                maxDuration: eventProperties[idx].duration
            )

            let repositionLink = CADisplayLink(target: self, selector: #selector(changeEventPos))
            repositionLink.add(to: RunLoop.current, forMode: .common)
            dragUi = DragUI(repositionLink: repositionLink, recognizer: recognizer)
        case .cancelled:
            resetDragState()
            repositionEventViews()
        case .ended:
            guard let idx = eventViews.firstIndex(of: recognizer.view!) else { return }

            var event = eventProperties[idx]
            event.daysOffset = dragState.target.daysOffset
            event.start = dragState.target.start
            eventProperties[idx] = event

            UIView.animate(withDuration: 0.1) {
                recognizer.view?.frame.origin = CGPoint(
                    x: self.xForDaysOffset(event.daysOffset),
                    y: self.yForTimestampInDay(event.start)
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
            return .vertical(-2 * log(max(hotEdge - loc.y, 1)))
        } else if loc.y > bottomThreshold {
            return .vertical(2 * log(max(loc.y - bottomThreshold, 1)))
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
        return DragState(origin: .zero, eventIndex: -1, target: .none, maxDuration: 1, isAllowed: true)
    }

    static func start(origin: CGPoint, eventIndex: Int, target: RescheduleTarget, maxDuration: Decimal) -> DragState {
        return DragState(origin: origin, eventIndex: eventIndex, target: target, maxDuration: maxDuration, isAllowed: true)
    }

    let origin: CGPoint
    let eventIndex: Int
    var target: RescheduleTarget
    let maxDuration: Decimal
    var isAllowed: Bool
}

private struct DragUI {
    let repositionLink: CADisplayLink
    let recognizer: UIGestureRecognizer
}

private struct RescheduleTarget {
    static var none: RescheduleTarget {
        return RescheduleTarget(daysOffset: 0, start: 0)
    }

    let daysOffset: Int
    let start: Decimal
}
