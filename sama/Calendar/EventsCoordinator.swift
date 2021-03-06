//
//  EventsCoordinator.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/21/21.
//

import UIKit

struct ProposedSlot: Encodable {
    let startDateTime: String
    let endDateTime: String
}

struct MeetingProposalBody: Encodable {
    let meetingIntentCode: String
    let proposedSlots: [ProposedSlot]
    let title: String
    let blockOutSlots: Bool
}

struct MeetingProposalResult: Decodable {
    struct Meeting: Decodable {
        let title: String
    }
    let meeting: Meeting
    let meetingCode: String
    let shareableMessage: String
}

struct MeetingProposalRequest: ApiRequest {
    typealias U = MeetingProposalResult
    let uri = "/meeting/propose"
    let logKey = "/meeting/propose"
    let method: HttpMethod = .post
    let body: MeetingProposalBody
}

struct MeetingTitleUpdateBody: Encodable {
    let title: String
}

struct MeetingTitleUpdateRequest: ApiRequest {
    typealias U = EmptyBody
    var uri: String { "/meeting/by-code/\(code)/update-title" }
    let code: String
    let logKey = "/meeting/by-code/{meetingCode}/update-title"
    let method: HttpMethod = .post
    let body: MeetingTitleUpdateBody
}

struct EventSearchRequestData: Encodable {
    let durationMinutes: Int
    let timeZone: String
    let suggestionSlotCount: Int
}

struct MeetingSuggestedSlot: Decodable {
    let startDateTime: String
    let endDateTime: String
}

struct MeetingInitiationContext: Decodable {
    let meetingIntentCode: String
    let durationMinutes: Int
    let defaultMeetingTitle: String
    let suggestedSlots: [MeetingSuggestedSlot]
}

struct MeetingInitiationResult {
    let context: MeetingInitiationContext
    let isBlockingEnabled: Bool
}

struct MeetingInitiationRequest: ApiRequest {
    typealias T = EventSearchRequestData
    typealias U = MeetingInitiationContext
    let uri = "/meeting/initiate"
    let logKey = "/meeting/initiate"
    let method: HttpMethod = .post
    var body: EventSearchRequestData
}

struct MeetingSettings {
    let title: String
    let isBlockingEnabled: Bool
}

class EventsCoordinator {

    var onChanges: (() -> Void)?
    var presentError: (ApiError) -> Void = { _ in }
    var presentProposal: (UIView, String, Bool, @escaping () -> Void) -> Void = { _, _, _, _ in }
    var api: Api
    var columnsCenterOffset = 0
    var topInset: CGFloat = 0
    var cellSize: CGSize = .zero {
        didSet {
            repositionEventViews()
        }
    }

    var meetingSettings = MeetingSettings(title: "", isBlockingEnabled: false)

    private var constraints = EventConstraints(duration: 0.25, min: RescheduleTarget(daysOffset: 0, start: 0))
    private var intentCode = ""
    private var meetingCode = ""

    private(set) var eventProperties: [EventProperties] = [] {
        didSet {
            onChanges?()
        }
    }

    private var eventViews: [EventView] = []

    private let context: CalendarContextProvider
    private let currentDayIndex: Int
    private let calendar: UIScrollView
    private let container: UIView

    private var feedback = UIImpactFeedbackGenerator(style: .heavy)

    // pin to 15 mins
    private let hourSplit = 4
    private let minsBase = 15
    private let hotEdge: CGFloat = 40

    private var dragState: DragState = .makeClear()
    private var dragUi: DragUI? {
        didSet {
            oldValue?.repositionLink.invalidate()
        }
    }
    private var scrollOffsetAnimation: ScrollOffsetAnimation!

    private let finder = SlotFinder()

    private var minTarget: RescheduleTarget {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: CalendarDateUtils.shared.dateNow)
        let next = Int(floor(Double(comps.minute!) / Double(minsBase))) + 1
        let minsNormalized = NSDecimalNumber(value: next * minsBase).dividing(by: NSDecimalNumber(value: 60))
        let start = NSDecimalNumber(value: comps.hour!).adding(minsNormalized).decimalValue
        if start == 25 {
            return RescheduleTarget(daysOffset: 1, start: 0)
        } else {
            return RescheduleTarget(daysOffset: 0, start: start)
        }
    }

    private var touchableCalendarMidY: CGFloat {
        let touchableCalendarHeight = calendar.bounds.height - calendar.contentInset.bottom - topInset
        return touchableCalendarHeight / 2
    }

    init(api: Api, currentDayIndex: Int, context: CalendarContextProvider, calendar: UIScrollView, container: UIView) {
        self.api = api
        self.currentDayIndex = currentDayIndex
        self.context = context
        self.calendar = calendar
        self.container = container
    }

    func timezonesDiffWithSelection(_ timezone: TimeZoneOption) -> TimeZonesDiff? {
        let offset = timezone.hoursFromGMT
        let current = TimeZone.current
        let hoursDiff = offset - Int(round(Double(current.secondsFromGMT()) / 3600))
        if hoursDiff != 0 {
            return TimeZonesDiff(
                targetTitle: timezone.offsetTitle,
                currentTitle: TimeZoneOption.from(timeZone: current, usersTimezone: current).offsetTitle,
                hours: hoursDiff
            )
        } else {
            return nil
        }
    }

    func initiateMeeting(duration: Int, timeZoneId: String, completion: @escaping (Result<MeetingInitiationResult, ApiError>) -> Void) {
        var error: ApiError?
        var isBlockingEnabled: Bool?
        var context: MeetingInitiationContext?

        let group = DispatchGroup()
        group.enter()
        api.request(for: UserSettingsRequest()) {
            switch $0 {
            case let .success(settings):
                isBlockingEnabled = settings.meetingPreferences.blockOutSlots
            case let .failure(err):
                error = err
            }
            group.leave()
        }

        group.enter()
        let data = EventSearchRequestData(
            durationMinutes: duration,
            timeZone: timeZoneId,
            suggestionSlotCount: 3
        )
        api.request(for: MeetingInitiationRequest(body: data)) {
            switch $0 {
            case let .success(result):
                context = result
            case let .failure(err):
                error = err
            }
            group.leave()
        }

        group.notify(queue: .main) {
            if let err = error {
                self.presentError(err)
                completion(.failure(err))
            } else {
                let result = MeetingInitiationResult(
                    context: context!,
                    isBlockingEnabled: isBlockingEnabled!
                )
                completion(.success(result))
            }
        }
    }

    func setup(withCode code: String, durationMins: Int, settings: MeetingSettings, properties props: [EventProperties]) {
        intentCode = code
        meetingCode = ""
        meetingSettings = settings
        eventViews = props.map { _ in self.makeEventView() }
        eventProperties = props

        constraints = EventConstraints(
            duration: NSDecimalNumber(value: durationMins).dividing(by: NSDecimalNumber(value: 60)).decimalValue,
            min: minTarget
        )

        autoScrollToSlot(at: 0)
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

    func proposeSlots(with completion: @escaping (Result<MeetingProposalResult, ApiError>) -> Void) {
        let calendar = Calendar.current
        let refDate = calendar.startOfDay(for: CalendarDateUtils.shared.uiRefDate)
        let formatter = ApiDateTimeFormatter.formatter

        let slots: [ProposedSlot] = eventProperties.map { ev in
            var comps = DateComponents()
            comps.day = ev.daysOffset
            comps.second = NSDecimalNumber(decimal: ev.start).multiplying(by: NSDecimalNumber(value: 3600)).intValue

            let startDate = calendar.date(byAdding: comps, to: refDate)!

            let durationInSecs = NSDecimalNumber(decimal: ev.duration).multiplying(by: NSDecimalNumber(value: 3600)).intValue
            let endDate = calendar.date(byAdding: .second, value: durationInSecs, to: startDate)!

            return ProposedSlot(
                startDateTime: formatter.string(from: startDate),
                endDateTime: formatter.string(from: endDate)
            )
        }

        let req = MeetingProposalRequest(
            body: MeetingProposalBody(
                meetingIntentCode: intentCode,
                proposedSlots: slots,
                title: meetingSettings.title,
                blockOutSlots: meetingSettings.isBlockingEnabled
            )
        )

        api.request(for: req) {
            switch $0 {
            case let .success(result):
                self.meetingSettings = MeetingSettings(
                    title: result.meeting.title,
                    isBlockingEnabled: false
                )
                self.meetingCode = result.meetingCode
            case let .failure(err):
                self.presentError(err)
            }
            completion($0)
        }
    }

    func addClosestToCenter() {
        let xCenter = calendar.contentOffset.x + (calendar.frame.width) / 2
        let totalDaysOffset = Int(round(xCenter - (cellSize.width / 2)) / cellSize.width)

        let yCenter = calendar.contentOffset.y + touchableCalendarMidY
        let yOffset = yCenter - cellSize.height
        let totalMinsOffset = NSDecimalNumber(value: Double(yOffset))
            .multiplying(by: NSDecimalNumber(value: hourSplit))
            .dividing(by: NSDecimalNumber(value: Double(cellSize.height)))
            .rounding(accordingToBehavior: nil)
            .dividing(by: NSDecimalNumber(value: hourSplit))

        let maxMinsOffset = NSDecimalNumber(value: 24).subtracting(NSDecimalNumber(decimal: constraints.duration)).decimalValue

        let possibleSlots = finder.getPossibleSlots(
            with: SlotFinder.Context(
                eventProperties: eventProperties,
                blocksForDayIndex: context.blocksForDayIndex,
                totalDaysOffset: totalDaysOffset,
                currentDayIndex: currentDayIndex,
                minTarget: minTarget,
                baseStart: max(0, min(maxMinsOffset, totalMinsOffset.decimalValue)),
                duration: constraints.duration
            )
        )

        guard !possibleSlots.isEmpty else { return }

        var idx = 0
        var minD: CGFloat = 10000
        for (i, slot) in possibleSlots.enumerated() {
            let rect = CGRect(
                x: xForDaysOffset(slot.daysOffset) + calendar.contentOffset.x,
                y: yForTimestampInDay(slot.start) + calendar.contentOffset.y,
                width: cellSize.width,
                height: CGFloat(truncating: constraints.duration as NSNumber) * cellSize.height + eventHandleExtraSpace
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
            start: possibleSlots[idx].start,
            duration: constraints.duration,
            daysOffset: possibleSlots[idx].daysOffset,
            timezoneOffset: eventProperties.first!.timezoneOffset
        ))

        repositionEventViews()
        autoScrollToSlot(at: eventProperties.count - 1)
    }

    func lockPick(_ _isLocked: Bool) {
        eventViews.forEach { $0.isLocked = _isLocked }
        repositionEventViews()
    }

    func autoScrollToSlot(at index: Int) {
        let props = eventProperties[index]

        let timestamp = NSDecimalNumber(decimal: props.start).adding(NSDecimalNumber(decimal: props.duration).dividing(by: NSDecimalNumber(value: 2)))
        let y = CGFloat(truncating: timestamp) * cellSize.height - touchableCalendarMidY
        calendar.setContentOffset(CGPoint(
            x: CGFloat(currentDayIndex + props.daysOffset + columnsCenterOffset) * cellSize.width,
            y: y
        ), animated: true)
    }

    private func makeEventView() -> EventView {
        let eventView = EventView()
        eventView.isUserInteractionEnabled = true

        let dragRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleEventDrag(_:)))
        dragRecognizer.minimumPressDuration = 0.02
        eventView.addGestureRecognizer(dragRecognizer)

        let handleRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleEventDurationDrag(_:)))
        handleRecognizer.minimumPressDuration = 0.01
        eventView.handleView.addGestureRecognizer(handleRecognizer)

        self.container.addSubview(eventView)
        return eventView
    }

    private func xForDaysOffset(_ daysOffset: Int) -> CGFloat {
        return CGFloat(currentDayIndex + daysOffset) * cellSize.width - calendar.contentOffset.x
    }

    private func yForTimestampInDay(_ timestamp: Decimal) -> CGFloat {
        return CGFloat(truncating: timestamp as NSNumber) * cellSize.height + 1 - calendar.contentOffset.y
    }

    private func yOffsetNormalized(_ y: CGFloat) -> CGFloat {
        let minY = CGFloat(0)
        let maxY = calendar.contentSize.height - calendar.contentInset.bottom
        if (y < minY) {
            return minY
        } else if (y > maxY) {
            return maxY
        } else {
            return y
        }
    }

    @objc private func animateContentOffset() {
        let animDuration = CGFloat(scrollOffsetAnimation.duration)
        let timeDiff = min(CGFloat(Date().timeIntervalSince(scrollOffsetAnimation.srcTimestamp)), animDuration)
        let offsetFromTime = (timeDiff * scrollOffsetAnimation.offset) / animDuration
        self.calendar.contentOffset.x = scrollOffsetAnimation.srcOffsetX + offsetFromTime
        if Date().timeIntervalSince(scrollOffsetAnimation.srcTimestamp) > (TimeInterval(animDuration) + 0.1) {
            scrollOffsetAnimation.displayLink.invalidate()
            dragState.isAllowed = true
        }
    }

    @objc private func changeEventPos() {
        guard let recognizer = dragUi?.recognizer else { return }

        let loc = recognizer.location(in: container)
        let eventView = recognizer.view as! EventView
        let idx = eventViews.firstIndex(of: eventView)!
        eventView.frame.origin = CGPoint(
            x: loc.x - dragState.origin.x,
            y: loc.y - dragState.origin.y
        )

        if let change = contentOffsetChange(from: loc) {
            switch change {
            case let .horizontal(step):
                dragState.isAllowed = false

                let displayLink = CADisplayLink(target: self, selector: #selector(animateContentOffset))
                displayLink.add(to: RunLoop.current, forMode: .common)

                scrollOffsetAnimation = ScrollOffsetAnimation(
                    displayLink: displayLink,
                    srcTimestamp: Date(),
                    srcOffsetX: self.calendar.contentOffset.x,
                    offset: CGFloat(step) * self.cellSize.width,
                    duration: 0.3
                )
            case let .vertical(points):
                self.calendar.contentOffset.y = yOffsetNormalized(calendar.contentOffset.y + points)
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

        switch true {
        case target.daysOffset < constraints.min.daysOffset:
            isValid = false
        case target.daysOffset == constraints.min.daysOffset && target.start < constraints.min.start:
            isValid = false
        default:
            break
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

        let minHeight = CGFloat(truncating: constraints.duration as NSNumber) * cellSize.height + eventHandleExtraSpace
        let maxHeight = CGFloat(truncating: dragState.maxDuration as NSNumber) * cellSize.height + eventHandleExtraSpace
        let safeEvHeight = min(max(eventHeight, minHeight), maxHeight)

        eventView.frame.size.height = safeEvHeight

        let locInContainer = recognizer.location(in: container)
        let bottomThreshold = (container.frame.height - (container.safeAreaInsets.bottom + calendar.contentInset.bottom) - hotEdge)

        if (locInContainer.y < hotEdge) {
            let extra = -2 * log(max(hotEdge - locInContainer.y, 1))
            calendar.contentOffset.y = yOffsetNormalized(calendar.contentOffset.y + extra)
        } else if (locInContainer.y > bottomThreshold) {
            let extra = 2 * log(max(locInContainer.y - bottomThreshold, 1))
            calendar.contentOffset.y = yOffsetNormalized(calendar.contentOffset.y + extra)
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
            let oldVal = eventProperties[dragState.eventIndex]
            if oldVal != event {
                Sama.bi.track(event: "range")
                eventProperties[dragState.eventIndex] = event
            }

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
            let eventView = recognizer.view as! EventView
            guard let idx = eventViews.firstIndex(of: eventView) else { return }
            eventView.superview!.bringSubviewToFront(eventView)

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
            guard let idx = eventViews.firstIndex(of: recognizer.view as! EventView) else { return }

            var event = eventProperties[idx]
            event.daysOffset = dragState.target.daysOffset
            event.start = dragState.target.start

            let oldVal = eventProperties[idx]
            if oldVal != event {
                Sama.bi.track(event: "moveslot")
                eventProperties[idx] = event
            }

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

private struct ScrollOffsetAnimation {
    let displayLink: CADisplayLink
    let srcTimestamp: Date
    let srcOffsetX: CGFloat
    let offset: CGFloat
    let duration: TimeInterval
}

struct RescheduleTarget {
    static var none: RescheduleTarget {
        return RescheduleTarget(daysOffset: 0, start: 0)
    }

    let daysOffset: Int
    let start: Decimal
}

private struct EventConstraints {
    let duration: Decimal
    let min: RescheduleTarget
}
