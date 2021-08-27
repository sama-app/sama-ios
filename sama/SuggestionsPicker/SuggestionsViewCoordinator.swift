//
//  SuggestionsViewCoordinator.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/11/21.
//

import UIKit

struct MeetingProposal: Decodable {
    let proposedSlots: [MeetingSuggestedSlot]
}

struct MeetingProposalsRequest: ApiRequest {
    typealias T = EmptyBody
    typealias U = MeetingProposal
    let code: String
    var uri: String { "/meeting/by-code/\(code)" }
    let logKey = "/meeting/by-code/{meetingCode}"
    let method: HttpMethod = .get
}

struct MeetingProposalsConfirmData: Encodable {
    let slot: ProposedSlot
    let recipientEmail: String?
}

struct MeetingProposalsConfirmRequest: ApiRequest {
    typealias U = EmptyBody
    let code: String
    var uri: String { "/meeting/by-code/\(code)/confirm" }
    let logKey = "/meeting/by-code/{meetingCode}/confirm"
    let method: HttpMethod = .post
    let body: MeetingProposalsConfirmData
}

struct ProposedAvailableSlot: Equatable {
    var start: Decimal
    var duration: Decimal
    var daysOffset: Int
    var pickStart: Decimal
}

private struct DragUI {
    let repositionLink: CADisplayLink
    let recognizer: UIGestureRecognizer
}

class SuggestionsViewCoordinator {

    var api: Api
    var onSelectionChange: ((Int) -> Void)?
    var onLoad: (([ProposedAvailableSlot], Decimal) -> Void)?
    var onChange: ((Int, ProposedAvailableSlot) -> Void)?
    var onLock: ((Bool) -> Void)?

    var onReset: (() -> Void)?

    private let context: CalendarContextProvider
    private let currentDayIndex: Int
    private let cellSize: CGSize
    private let calendar: UIScrollView
    private let container: UIView

    private var refDate = Date()
    private var meetingCode: String = ""
    private var duration: Decimal = 1
    private var availableSlotProps: [ProposedAvailableSlot] = []
    private var availableSlotViews: [SlotSuggestionView] = []
    private lazy var timeInSlotPickerView: SuggestionsPickCalendarSlider = {
        let v = SuggestionsPickCalendarSlider()
        let dragRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handlePickerDrag(_:)))
        dragRecognizer.minimumPressDuration = 0.01
        v.addGestureRecognizer(dragRecognizer)
        return v
    }()

    private let hotEdge: CGFloat = 40
    // pin to 15 mins
    private let hourSplit = 4

    private let transformer = ProposedAvailableSlotsTransformer()

    private var selectionIndex = 0 {
        didSet {
            let isFullSlot = availableSlotProps[selectionIndex].duration == duration
            for (idx, view) in availableSlotViews.enumerated() {
                view.isHighlighted = idx == selectionIndex && isFullSlot
                view.setNeedsLayout()
            }
        }
    }
    private var isLocked = false

    private var dragOrigin: CGPoint = .zero
    private var dragUi: DragUI? {
        didSet {
            oldValue?.repositionLink.invalidate()
        }
    }

    private var touchableCalendarMidY: CGFloat {
        let touchableCalendarHeight = calendar.bounds.height - calendar.contentInset.bottom - Sama.env.ui.calenarHeaderHeight
        return touchableCalendarHeight / 2
    }

    init(api: Api, currentDayIndex: Int, context: CalendarContextProvider, cellSize: CGSize, calendar: UIScrollView, container: UIView) {
        self.api = api
        self.currentDayIndex = currentDayIndex
        self.context = context
        self.cellSize = cellSize
        self.calendar = calendar
        self.container = container
    }

    func present(code: String, onError: @escaping (Error) -> Void) {
        meetingCode = code
        refDate = Date()
        api.request(for: MeetingProposalsRequest(code: meetingCode)) {
            switch $0 {
            case let .success(rawProposal):
                let proposal = self.transformer.transform(proposal: rawProposal, calendar: .current, refDate: self.refDate)

                self.duration = proposal.duration
                self.availableSlotProps = proposal.slots

                self.availableSlotViews = self.availableSlotProps.enumerated().map { idx, slot in
                    let v = SlotSuggestionView()

                    let tapHandler = UITapGestureRecognizer(target: self, action: #selector(self.handleSlotTap))
                    v.addGestureRecognizer(tapHandler)

                    self.container.addSubview(v)
                    return v
                }
                self.selectionIndex = 0
                self.container.addSubview(self.timeInSlotPickerView)

                self.repositionEventViews()
                self.autoScrollToSlot(at: self.selectionIndex)

                self.onLoad?(self.availableSlotProps, self.duration)
            case let .failure(err):
                self.reset()
                onError(err)
            }
        }
    }

    func reset() {
        availableSlotProps = []
        availableSlotViews.forEach { $0.removeFromSuperview() }
        availableSlotViews = []

        timeInSlotPickerView.removeFromSuperview()

        lockPick(false)

        onReset?()
    }

    func repositionEventViews() {
        guard availableSlotProps.count > 0 else { return }

        let isFullSlot = availableSlotProps[selectionIndex].duration == duration
        timeInSlotPickerView.isHidden = !isLocked && isFullSlot

        let count = availableSlotProps.count
        for i in (0 ..< count) {
            let eventProps = availableSlotProps[i]
            let eventView = availableSlotViews[i]

            let start = eventProps.start
            let duration = eventProps.duration
            eventView.frame = CGRect(
                x: xForDaysOffset(eventProps.daysOffset),
                y: yForTimestampInDay(start),
                width: cellSize.width,
                height: CGFloat(truncating: duration as NSNumber) * cellSize.height + eventHandleExtraSpace
            )
            eventView.isHidden = isLocked
        }

        if dragUi == nil {
            let eventProps = availableSlotProps[selectionIndex]
            let start = eventProps.pickStart
            let duration = duration
            timeInSlotPickerView.frame = CGRect(
                x: xForDaysOffset(eventProps.daysOffset),
                y: yForTimestampInDay(start),
                width: cellSize.width,
                height: CGFloat(truncating: duration as NSNumber) * cellSize.height + eventHandleExtraSpace
            )
        }
    }

    func changeSelection(_ index: Int) {
        selectionIndex = index
        autoScrollToSlot(at: selectionIndex)
    }

    func lockPick(_ _isLocked: Bool) {
        isLocked = _isLocked
        onLock?(_isLocked)
        timeInSlotPickerView.isLocked = _isLocked
        repositionEventViews()
    }

    func confirm(recipientEmail: String?, completion: @escaping (Error?) -> Void) {
        let slot = availableSlotProps[selectionIndex]

        let calendar = Calendar.current
        let refDate = calendar.startOfDay(for: self.refDate)
        let formatter = ApiDateTimeFormatter.formatter

        var comps = DateComponents()
        comps.day = slot.daysOffset
        comps.second = NSDecimalNumber(decimal: slot.pickStart).multiplying(by: NSDecimalNumber(value: 3600)).intValue

        let startDate = calendar.date(byAdding: comps, to: refDate)!

        let durationInSecs = NSDecimalNumber(decimal: duration).multiplying(by: NSDecimalNumber(value: 3600)).intValue
        let endDate = calendar.date(byAdding: .second, value: durationInSecs, to: startDate)!

        let req = MeetingProposalsConfirmRequest(
            code: meetingCode,
            body: MeetingProposalsConfirmData(
                slot: ProposedSlot(
                    startDateTime: formatter.string(from: startDate),
                    endDateTime: formatter.string(from: endDate)
                ),
                recipientEmail: recipientEmail
            )
        )

        api.request(for: req) { result in
            switch result {
            case .success:
                completion(nil)
            case let .failure(err):
                completion(err)
            }
        }
    }

    @objc private func handleSlotTap(_ gesture: UIGestureRecognizer) {
        guard
            let slotIndex = availableSlotViews.firstIndex(of: gesture.view as! SlotSuggestionView),
            slotIndex != selectionIndex
        else { return }
        changeSelection(slotIndex)
        onSelectionChange?(selectionIndex)
    }

    @objc private func handlePickerDrag(_ recognizer: UIGestureRecognizer) {
        switch recognizer.state {
        case .began:
            dragOrigin = recognizer.location(in: recognizer.view)

            let repositionLink = CADisplayLink(target: self, selector: #selector(changePickerPos))
            repositionLink.add(to: RunLoop.current, forMode: .common)
            dragUi = DragUI(repositionLink: repositionLink, recognizer: recognizer)
        case .cancelled:
            resetDragState()
            repositionEventViews()
        case .ended:
            let loc = timeInSlotPickerView.frame.origin

            var slot = availableSlotProps[selectionIndex]
            slot.pickStart = target(from: loc)

            let oldVal = availableSlotProps[selectionIndex]
            if oldVal != slot {
                availableSlotProps[selectionIndex] = slot
                onChange?(selectionIndex, slot)
            }

            UIView.animate(withDuration: 0.1) {
                recognizer.view?.frame.origin.y = self.yForTimestampInDay(slot.pickStart)
            }

            resetDragState()
        case .changed:
            // display link handles changes
            break
        default:
            resetDragState()
        }
    }

    private func resetDragState() {
        dragUi = nil
        dragOrigin = .zero
    }

    @objc private func changePickerPos() {
        guard let recognizer = dragUi?.recognizer else { return }

        let slot = availableSlotProps[selectionIndex]

        let loc = recognizer.location(in: container)
        let pickerView = recognizer.view!

        let minY = yForTimestampInDay(slot.start)
        let maxY = yForTimestampInDay(slot.start + slot.duration - duration)
        let rawPosY = loc.y - dragOrigin.y
        let yPos = min(max(minY, rawPosY), maxY)
        pickerView.frame.origin.y = yPos

        if let points = contentOffsetChange(from: loc) {
            self.calendar.contentOffset.y = yOffsetNormalized(calendar.contentOffset.y + points)
        }
    }

    private func target(from loc: CGPoint) -> Decimal {
        let calcYOffset = calendar.contentOffset.y + loc.y
        let eventHeight = CGFloat(truncating: duration as NSNumber) * cellSize.height
        let maxYOffset = CGFloat(24) * cellSize.height - eventHeight
        let yOffset = min(max((calcYOffset), 0), maxYOffset)
        let totalMinsOffset = NSDecimalNumber(value: Double(yOffset))
            .multiplying(by: NSDecimalNumber(value: hourSplit))
            .dividing(by: NSDecimalNumber(value: Double(cellSize.height)))
            .rounding(accordingToBehavior: nil)
            .dividing(by: NSDecimalNumber(value: hourSplit))
        return totalMinsOffset.decimalValue
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

    private func contentOffsetChange(from loc: CGPoint) -> CGFloat? {
        let bottomThreshold = (container.frame.height - (container.safeAreaInsets.bottom + calendar.contentInset.bottom) - hotEdge)
        if loc.y < hotEdge {
            return -2 * log(max(hotEdge - loc.y, 1))
        } else if loc.y > bottomThreshold {
            return 2 * log(max(loc.y - bottomThreshold, 1))
        }

        return nil
    }

    private func xForDaysOffset(_ daysOffset: Int) -> CGFloat {
        return CGFloat(currentDayIndex + daysOffset) * cellSize.width - calendar.contentOffset.x
    }

    private func yForTimestampInDay(_ timestamp: Decimal) -> CGFloat {
        return CGFloat(truncating: timestamp as NSNumber) * cellSize.height + 1 - calendar.contentOffset.y
    }

    private func autoScrollToSlot(at index: Int) {
        let props = availableSlotProps[index]

        let timestamp = NSDecimalNumber(decimal: props.start).adding(NSDecimalNumber(decimal: props.duration).dividing(by: NSDecimalNumber(value: 2)))
        let y = CGFloat(truncating: timestamp) * cellSize.height - touchableCalendarMidY
        calendar.setContentOffset(CGPoint(
            x: CGFloat(currentDayIndex + props.daysOffset - 1) * cellSize.width,
            y: y
        ), animated: true)
    }
}
