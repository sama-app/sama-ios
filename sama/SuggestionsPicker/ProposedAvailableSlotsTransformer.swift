//
//  ProposedAvailableSlotsTransformer.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/22/21.
//

import Foundation

struct MeetingProposals {
    let duration: Decimal
    let slots: [ProposedAvailableSlot]
}

struct ProposedAvailableSlotsTransformer {

    private let apiDateF = ApiDateTimeFormatter()

    func transform(proposal: MeetingProposal, calendar: Calendar, refDate: Date) -> MeetingProposals {
        let rawSlots: [ProposedAvailableSlot] = proposal.proposedSlots.map { slot in
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
        mergedSlots.sort(by: {
            switch true {
            case $0.daysOffset < $1.daysOffset:
                return true
            case $0.daysOffset == $1.daysOffset:
                return $0.start < $1.start
            default:
                return false
            }
        })

        return MeetingProposals(
            duration: rawSlots.first?.duration ?? 1,
            slots: mergedSlots
        )
    }
}
