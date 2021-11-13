//
//  EventDatesPanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/14/21.
//

import UIKit
import FirebaseCrashlytics

struct EventProperties: Equatable {
    var start: Decimal
    var duration: Decimal
    var daysOffset: Int
    let timezoneOffset: Int
}

enum EventDatesEvent {
    case reset
    case show([EventProperties])
}

struct EventSearchOptions {
    let usersTimezoneHoursFromGMT: Int
    let timezone: TimeZoneOption
    let duration: DurationOption
}

class EventDatesPanel: CalendarNavigationBlock {

    var options: EventSearchOptions!
    var coordinator: EventsCoordinator!

    private let apiDateF = ApiDateTimeFormatter()
    private let refDate = CalendarDateUtils.shared.uiRefDate
    private let calendar = Calendar.current

    private var backBtn: UIButton!
    private var actionButton: MainActionButton!
    private var secondaryBtn: UIButton!
    private let titleLabel = UILabel()
    private let loader = UIActivityIndicatorView()
    private let content = UIStackView()
    private var wrapperHeightConstraint: NSLayoutConstraint!

    private var isProposed = false
    private var cachedShareableMessage = ""

    private let isShareFlow = Sama.isShareMainFlow

    override func didLoad() {
        backBtn = addBackButton(action: #selector(onBackButton))

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .neutral1
        titleLabel.font = .brandedFont(ofSize: 20, weight: .regular)
        titleLabel.text = "Finding best slots..."
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 4)
        ])

        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        addSubview(wrapper)

        content.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .vertical
        wrapper.addSubview(content)

        wrapperHeightConstraint = wrapper.heightAnchor.constraint(equalToConstant: 180)
        NSLayoutConstraint.activate([
            wrapper.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -8),
            wrapper.topAnchor.constraint(equalTo: backBtn.bottomAnchor),
            trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            wrapperHeightConstraint,
            content.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            content.topAnchor.constraint(equalTo: wrapper.topAnchor),
            wrapper.trailingAnchor.constraint(equalTo: content.trailingAnchor),
        ])

        secondaryBtn = UIButton(type: .system)
        secondaryBtn.setTitle("Edit meeting settings", for: .normal)
        secondaryBtn.translatesAutoresizingMaskIntoConstraints = false
        secondaryBtn.setTitleColor(.primary, for: .normal)
        secondaryBtn.titleLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
        secondaryBtn.addTarget(self, action: #selector(onSecondaryActionButton), for: .touchUpInside)
        addSubview(secondaryBtn)
        secondaryBtn.pinLeadingAndTrailing()
        NSLayoutConstraint.activate([
            secondaryBtn.topAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: 8),
            secondaryBtn.heightAnchor.constraint(equalToConstant: 48)
        ])
        secondaryBtn.isHidden = true

        actionButton = addMainActionButton(
            title: isShareFlow ? "Share suggestions" : "Copy Suggestions",
            action: #selector(onMainActionButton),
            topAnchor: secondaryBtn.bottomAnchor
        )
        actionButton.isHidden = true

        loader.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loader)
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        loader.startAnimating()

        coordinator.onChanges = { [weak self] in
            self?.reloadEventsList()
        }
        searchSlots()
    }

    private func searchSlots() {
        coordinator.initiateMeeting(
            duration: options.duration.duration,
            timeZoneId: options.timezone.zoneId
        ) {
            switch $0 {
            case let .success(result):
                self.setupInitiation(with: result)
            case .failure:
                self.onBackButton()
            }
        }
    }

    private func setupInitiation(with result: MeetingInitiationResult) {
        let timezoneOffset = options.timezone.hoursFromGMT - options.usersTimezoneHoursFromGMT
        let refStart = calendar.startOfDay(for: refDate)

        let props = result.context.suggestedSlots.map { slot -> EventProperties in
            let parsedStart = self.apiDateF.date(from: slot.startDateTime)
            let startDate = self.calendar.toTimeZone(date: parsedStart)
            let parsedEnd = self.apiDateF.date(from: slot.endDateTime)
            let endDate = self.calendar.toTimeZone(date: parsedEnd)
            let startComps = self.calendar.dateComponents([.day, .second], from: refStart, to: startDate)
            let durationComps = self.calendar.dateComponents([.second], from: startDate, to: endDate)
            let start = NSDecimalNumber(value: startComps.second!).dividing(by: NSDecimalNumber(value: 3600))
            let duration = NSDecimalNumber(value: durationComps.second!).dividing(by: NSDecimalNumber(value: 3600))
            return EventProperties(
                start: start.decimalValue,
                duration: duration.decimalValue,
                daysOffset: startComps.day!,
                timezoneOffset: timezoneOffset
            )
        }.sorted(by: {
            switch true {
            case $0.daysOffset < $1.daysOffset:
                return true
            case $0.daysOffset == $1.daysOffset:
                return $0.start < $1.start
            default:
                return false
            }
        })

        self.secondaryBtn.isHidden = false
        self.actionButton.isHidden = false
        self.titleLabel.text = "Here are your best slots:"
        self.loader.stopAnimating()
        self.loader.isHidden = true
        self.coordinator.setup(
            withCode: result.context.meetingIntentCode,
            durationMins: options.duration.duration,
            settings: MeetingSettings(
                title: result.context.defaultMeetingTitle,
                isBlockingEnabled: result.isBlockingEnabled
            ),
            properties: props
        )
    }

    private func reloadEventsList() {
        let events = coordinator.eventProperties
        for subview in content.subviews {
            subview.removeFromSuperview()
        }
        let isRemovable = events.count > 1 && !isProposed
        let isButtonVisible = events.count < 3 && !isProposed
        for (index, props) in events.enumerated() {
            let itemView = EventListItemView(props: props, isRemovable: isRemovable, isFocusable: !isProposed)
            itemView.handleRemove = { [weak self] in
                Sama.bi.track(event: "deleteslot")

                self?.coordinator.remove(props)
            }
            itemView.handleFocus = { [weak self] in
                self?.coordinator.autoScrollToSlot(at: index)
            }
            self.content.addArrangedSubview(itemView)
        }
        if isButtonVisible {
            let actionBtn = UIButton(type: .system)
            actionBtn.translatesAutoresizingMaskIntoConstraints = false
            actionBtn.heightAnchor.constraint(equalToConstant: 60).isActive = true
            actionBtn.setTitle("Add another slot", for: .normal)
            actionBtn.titleLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
            actionBtn.setImage(UIImage(named: "plus")!, for: .normal)
            actionBtn.tintColor = .primary
            actionBtn.contentHorizontalAlignment = .leading
            actionBtn.contentVerticalAlignment = .center
            actionBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
            actionBtn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
            actionBtn.addTarget(self, action: #selector(onAddNewSuggestion), for: .touchUpInside)

            self.content.addArrangedSubview(actionBtn)
        }
    }

    @objc private func onBackButton() {
        coordinator.resetEventViews()
        navigation?.pop()
    }

    private func editTitle() {
        let panel = SuggestionsEditPanel()
        panel.coordinator = coordinator
        navigation?.pushBlock(panel, animated: true)
    }

    @objc private func onSecondaryActionButton() {
        if isProposed {
            if isShareFlow {
                Sama.bi.track(event: "share-again")
                coordinator.presentProposal(secondaryBtn, cachedShareableMessage, true, {})
            } else {
                Sama.bi.track(event: "copy-again")
                UIPasteboard.general.string = cachedShareableMessage
            }
        } else {
            editTitle()
        }
    }

    @objc private func onAddNewSuggestion() {
        Sama.bi.track(event: "addslot")

        coordinator.addClosestToCenter()
    }

    @objc private func onMainActionButton() {
        if isProposed {
            coordinator.resetEventViews()
            navigation?.popToRoot()
        } else {
            copySuggestions()
        }
    }

    private func copySuggestions() {
        if isShareFlow {
            Sama.bi.track(event: "share")
        } else {
            Sama.bi.track(event: "copy")
        }

        actionButton.isEnabled = false
        coordinator.proposeSlots { [weak self] in
            guard let self = self else { return }

            switch $0 {
            case let .success(result):
                self.cachedShareableMessage = result.shareableMessage

                self.coordinator.lockPick(true)
                if self.isShareFlow {
                    self.coordinator.presentProposal(self.actionButton, self.cachedShareableMessage, false, { [weak self] in
                        self?.actionButton.isEnabled = true
                        self?.confirmProposal()
                    })
                } else {
                    UIPasteboard.general.string = self.cachedShareableMessage

                    self.actionButton.isEnabled = true
                    self.confirmProposal()
                }
            case .failure:
                self.actionButton.isEnabled = true
            }
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let err = error {
                Crashlytics.crashlytics().record(error: err)
            }
        }
    }

    private func confirmProposal() {
        self.isProposed = true

        self.backBtn.isHidden = true
        self.titleLabel.isHidden = true

        let confirmationLabel = UILabel()
        confirmationLabel.translatesAutoresizingMaskIntoConstraints = false
        confirmationLabel.textColor = .neutral1
        confirmationLabel.font = .brandedFont(ofSize: 20, weight: .semibold)
        confirmationLabel.text = isShareFlow ? "You suggested these times" : "You can now paste it in any app."
        self.addSubview(confirmationLabel)
        NSLayoutConstraint.activate([
            confirmationLabel.centerYAnchor.constraint(equalTo: self.titleLabel.centerYAnchor),
            confirmationLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        ])

        self.wrapperHeightConstraint.constant = CGFloat(self.coordinator.eventProperties.count * 60)
        self.secondaryBtn.setTitle(isShareFlow ? "Share again" : "Copy again", for: .normal)
        self.actionButton.setTitle("Done", for: .normal)
        self.reloadEventsList()
    }
}
