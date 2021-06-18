//
//  FindTimePanel.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/9/21.
//

import UIKit

enum FindTimeAction: Equatable {
    case pickDuration
    case pickTimezone
}

struct FindTimeActionTrigger: Equatable {
    let action: FindTimeAction
    let range: Range<Int>
}

struct FindTimePart {
    let trigger: FindTimeActionTrigger?
    let text: String

    static func make(from parts: [(String, FindTimeAction?)]) -> [FindTimePart] {
        var cumulativeIdx = 0
        return parts.map { (base, action) in
            if let action = action {
                let singleLineStr = base.replacingOccurrences(of: " ", with: "\u{00A0}")
                let extendedBtnStr = "\u{00A0}\(singleLineStr)\u{00A0}"
                let startIdx = cumulativeIdx
                // +1 because actions have right icon which couts as 1 character
                let endIdx = startIdx + extendedBtnStr.count + 1
                cumulativeIdx = endIdx
                return FindTimePart(
                    trigger: FindTimeActionTrigger(action: action, range: (startIdx ..< endIdx)),
                    text: extendedBtnStr
                )
            } else {
                cumulativeIdx += base.count
                return FindTimePart(trigger: nil, text: base)
            }
        }
    }
}

class FindTimePanel: CalendarNavigationBlock {

    var token: AuthToken!
    var targetTimezoneChangeHandler: ((Int) -> Void)?
    var onEventDatesEvent: ((EventDatesEvent) -> Void)?

    private var durationOption = DurationOption(text: "1 hour", duration: 60) {
        didSet {
            text.setup(withParts: parts)
        }
    }
    private var timezoneOption = TimeZoneOption.from(timeZone: .current, usersTimezone: .current) {
        didSet {
            text.setup(withParts: parts)
            targetTimezoneChangeHandler?(timezoneOption.hoursFromGMT)
        }
    }

    private var parts: [FindTimePart] {
        return FindTimePart.make(from: [
            ("Find me a time for a ", nil),
            (durationOption.text, .pickDuration),
            (" meeting with someone in", nil),
            (timezoneOption.isUsersTimezone ? "my timezone" : timezoneOption.title, .pickTimezone),
            (" ", nil)
        ])
    }

    private var text = FindTimeLabel()

    override func didLoad() {
        text.translatesAutoresizingMaskIntoConstraints = false
        text.isUserInteractionEnabled = true
        text.numberOfLines = 0
        text.lineBreakMode = .byWordWrapping
        addSubview(text)
        NSLayoutConstraint.activate([
            text.topAnchor.constraint(equalTo: topAnchor),
            text.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: text.trailingAnchor),
        ])
        text.actionHandler = { [weak self] in self?.onAction($0) }
        text.setup(withParts: parts)

        let actionBtn = MainActionButton.make(withTitle: "Find Time")
        actionBtn.addTarget(self, action: #selector(onFindTimeButton), for: .touchUpInside)
        addSubview(actionBtn)
        NSLayoutConstraint.activate([
            actionBtn.heightAnchor.constraint(equalToConstant: 48),
            actionBtn.topAnchor.constraint(equalTo: text.bottomAnchor, constant: 16),
            actionBtn.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: actionBtn.trailingAnchor),
            bottomAnchor.constraint(equalTo: actionBtn.bottomAnchor)
        ])
    }

    private func onAction(_ action: FindTimeAction) {
        switch action {
        case .pickDuration:
            let block = DurationPickerPanel()
            block.optionPickHandler = { [weak self] in
                self?.durationOption = $0
            }
            navigation?.pushBlock(block, animated: true)
        case .pickTimezone:
            let block = TimeZonePickerPanel()
            block.optionPickHandler = { [weak self] in
                self?.timezoneOption = $0
            }
            navigation?.pushBlock(block, animated: true)
        }
    }

    @objc private func onFindTimeButton() {
        let block = EventDatesPanel()
        block.options = EventSearchOptions(
            timezone: timezoneOption,
            duration: durationOption
        )
        block.token = token
        block.onEvent = onEventDatesEvent
        navigation?.pushBlock(block, animated: true)
    }
}

private class FindTimeLabel: UILabel {

    var actionHandler: ((FindTimeAction) -> Void)?

    private(set) var parts: [FindTimePart] = []

    private var manager: NSLayoutManager!
    private var container: NSTextContainer!
    private var storage: NSTextStorage!

    private var activeTigger: FindTimeActionTrigger?

    func setup(withParts parts: [FindTimePart]) {
        self.parts = parts
        attributedText = NSMutableAttributedString.make(withParts: parts, activeAction: nil)

        manager = NSLayoutManager()
        container = NSTextContainer()
        storage = NSTextStorage(attributedString: attributedText!)

        manager.addTextContainer(container)
        storage.addLayoutManager(manager)

        container.lineFragmentPadding = 0
        container.lineBreakMode = .byWordWrapping
        container.maximumNumberOfLines = 0

        activeTigger = nil
    }

    private func findTrigger(from touches: Set<UITouch>) -> FindTimeActionTrigger? {
        guard let touch = touches.first else { return nil }

        container.size = bounds.size
        let indexOfChar = manager.characterIndex(
            for: touch.location(in: self),
            in: container,
            fractionOfDistanceBetweenInsertionPoints: nil
        )
        for trigger in parts.compactMap({ $0.trigger }) {
            if trigger.range.contains(indexOfChar) {
                return trigger
            }
        }
        return nil
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        if let trigger = findTrigger(from: touches) {
            activeTigger = trigger
            attributedText = NSMutableAttributedString.make(withParts: parts, activeAction: trigger.action)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.attributedText = NSMutableAttributedString.make(withParts: self.parts, activeAction: nil)
        }, completion: nil)

        if let trigger = activeTigger, trigger == findTrigger(from: touches) {
            activeTigger = nil
            actionHandler?(trigger.action)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.attributedText = NSMutableAttributedString.make(withParts: self.parts, activeAction: nil)
        }, completion: nil)
        activeTigger = nil
    }
}

private extension NSMutableAttributedString {
    static func make(withParts parts: [FindTimePart], activeAction action: FindTimeAction?) -> NSMutableAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 28

        let actionFont = UIFont.brandedFont(ofSize: 20, weight: .semibold)
        let defaultAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.neutral1,
            .font: UIFont.brandedFont(ofSize: 20, weight: .regular),
            .paragraphStyle: paragraph
        ]
        let actionColor = UIColor.primary
        let highlightedActionColor = UIColor.primary.withAlphaComponent(0.35)

        let makeActionAttrs: (FindTimeAction) -> [NSAttributedString.Key: Any] = { targetAction in
            return [
                .foregroundColor: targetAction == action ? highlightedActionColor : actionColor,
                .font: actionFont,
                .paragraphStyle: paragraph
            ]
        }
        let makeArrowDown: (FindTimeAction) -> NSAttributedString = { targetAction in
            let attachment = NSTextAttachment()
            let image = UIImage(named: "arrow-down")!.withTintColor(targetAction == action ? highlightedActionColor : actionColor)
            attachment.image = image
            let imSz = image.size
            attachment.bounds = CGRect(x: 0, y: (actionFont.capHeight - imSz.height) / 2, width: imSz.width, height: imSz.height)
            return NSAttributedString(attachment: attachment)
        }

        let makeDefault: (String) -> NSAttributedString = {
            return NSAttributedString(string: $0, attributes: defaultAttrs)
        }
        let makeAction: (String, FindTimeAction) -> NSAttributedString = { (base, action) in
            let result = NSMutableAttributedString(string: base, attributes: makeActionAttrs(action))
            result.append(makeArrowDown(action))
            return result
        }

        let result = NSMutableAttributedString()
        for part in parts {
            if let trigger = part.trigger {
                result.append(makeAction(part.text, trigger.action))
            } else {
                result.append(makeDefault(part.text))
            }
        }
        return result
    }
}
