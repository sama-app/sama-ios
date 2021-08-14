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

    private let apiDateF = ApiDateTimeFormatter()

    private var highlightedIndex = 0 {
        didSet {
            for (idx, view) in availableSlotViews.enumerated() {
                view.isHighlighted = idx == highlightedIndex
                view.setNeedsLayout()
            }
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
        api.request(for: MeetingProposalsRequest(code: "5XlvI9ZT")) {
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
                        daysOffset: daysOffset
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
                                daysOffset: finalSlot.daysOffset
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
                self.highlightedIndex = 0

                self.repositionEventViews()
                self.autoScrollToSlot(at: self.highlightedIndex)
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
    }

    @objc private func handleSlotTap(_ gesture: UIGestureRecognizer) {
        guard
            let slotIndex = availableSlotViews.firstIndex(of: gesture.view as! SlotSuggestionView),
            slotIndex != highlightedIndex
        else { return }
        highlightedIndex = slotIndex
        autoScrollToSlot(at: highlightedIndex)
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
