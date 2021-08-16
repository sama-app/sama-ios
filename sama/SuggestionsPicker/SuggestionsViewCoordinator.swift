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

    private let context: CalendarContextProvider
    private let currentDayIndex: Int
    private let cellSize: CGSize
    private let calendar: UIScrollView
    private let container: UIView

    private var duration: Decimal = 1
    private var availableSlotProps: [ProposedAvailableSlot] = []
    private var availableSlotViews: [SlotSuggestionView] = []
    private var timeInSlotPickerView: UIView?

    private let hotEdge: CGFloat = 40
    // pin to 15 mins
    private let hourSplit = 4

    private let apiDateF = ApiDateTimeFormatter()

    private var selectionIndex = 0 {
        didSet {
            let isFullSlot = availableSlotProps[selectionIndex].duration == duration
            if isFullSlot {
                timeInSlotPickerView?.removeFromSuperview()
                timeInSlotPickerView = nil
            } else if timeInSlotPickerView == nil {
                let v = SlotSuggestionView()
                v.isHighlighted = true

                let dragRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handlePickerDrag(_:)))
                dragRecognizer.minimumPressDuration = 0.01
                v.addGestureRecognizer(dragRecognizer)

                self.container.addSubview(v)
                timeInSlotPickerView = v
            }

            for (idx, view) in availableSlotViews.enumerated() {
                view.isHighlighted = idx == selectionIndex && isFullSlot
                view.setNeedsLayout()
            }
        }
    }

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

    func present() {
        api.request(for: MeetingProposalsRequest(code: "n3HQNbFr")) {
            switch $0 {
            case let .success(proposals):
                let calendar = Calendar.current
                let refDate = Date()
                let rawSlots: [ProposedAvailableSlot] = proposals.proposedSlots.map { slot in
                    let parsedStart = self.apiDateF.date(from: slot.startDateTime)
                    let startDate = calendar.toTimeZone(date: parsedStart)
                    let parsedEnd = self.apiDateF.date(from: slot.endDateTime)
                    let endDate = calendar.toTimeZone(date: parsedEnd)
                    let startInDay = startDate.timeIntervalSince(calendar.startOfDay(for: startDate))
                    let durationVal = endDate.timeIntervalSince(startDate)
                    let duration = NSDecimalNumber(value: durationVal).dividing(by: NSDecimalNumber(value: 3600)).decimalValue
                    let start = NSDecimalNumber(value: startInDay).dividing(by: NSDecimalNumber(value: 3600)).decimalValue
                    let daysOffset = calendar.dateComponents(
                        [.day],
                        from: calendar.startOfDay(for: refDate),
                        to: calendar.startOfDay(for: startDate)
                    ).day!
                    return ProposedAvailableSlot(
                        start: start,
                        duration: duration,
                        daysOffset: daysOffset,
                        pickStart: start
                    )
                }

                // merging slots
                var mergedSlots: [ProposedAvailableSlot] = []
                for slot in rawSlots {
                    var isMerged = false
                    for (idx, finalSlot) in mergedSlots.enumerated() {
                        if slot.daysOffset == finalSlot.daysOffset && slot.start >= finalSlot.start && slot.start < (finalSlot.start + finalSlot.duration) {
                            let end = slot.start + slot.duration
                            let duration = end - finalSlot.start

                            mergedSlots[idx] = ProposedAvailableSlot(
                                start: finalSlot.start,
                                duration: duration,
                                daysOffset: finalSlot.daysOffset,
                                pickStart: finalSlot.pickStart
                            )

                            isMerged = true
                            break
                        }
                    }
                    if !isMerged {
                        mergedSlots.append(slot)
                    }
                }

                if let firstSlot = rawSlots.first {
                    // first slot defines duration
                    self.duration = firstSlot.duration
                }
                self.availableSlotProps = mergedSlots

                self.availableSlotViews = mergedSlots.enumerated().map { idx, slot in
                    let v = SlotSuggestionView()

                    let tapHandler = UITapGestureRecognizer(target: self, action: #selector(self.handleSlotTap))
                    v.addGestureRecognizer(tapHandler)

                    self.container.addSubview(v)
                    return v
                }
                self.selectionIndex = 0

                self.repositionEventViews()
                self.autoScrollToSlot(at: self.selectionIndex)
            case let .failure(err):
                print(err)
            }
        }
    }

    func repositionEventViews() {
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
        }

        if dragUi == nil, let pickerView = timeInSlotPickerView {
            let eventProps = availableSlotProps[selectionIndex]
            let start = eventProps.pickStart
            let duration = duration
            pickerView.frame = CGRect(
                x: xForDaysOffset(eventProps.daysOffset),
                y: yForTimestampInDay(start),
                width: cellSize.width,
                height: CGFloat(truncating: duration as NSNumber) * cellSize.height + eventHandleExtraSpace
            )
        }
    }

    @objc private func handleSlotTap(_ gesture: UIGestureRecognizer) {
        guard
            let slotIndex = availableSlotViews.firstIndex(of: gesture.view as! SlotSuggestionView),
            slotIndex != selectionIndex
        else { return }
        selectionIndex = slotIndex
        autoScrollToSlot(at: selectionIndex)
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
            let loc = timeInSlotPickerView!.frame.origin

            var slot = availableSlotProps[selectionIndex]
            slot.pickStart = target(from: loc)

            let oldVal = availableSlotProps[selectionIndex]
            if oldVal != slot {
                availableSlotProps[selectionIndex] = slot
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
