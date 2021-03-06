//
//  ConnectedGoogleAccountScreen.swift
//  sama
//
//  Created by Viktoras Laukevičius on 10/29/21.
//

import UIKit

struct GoogleUnlinkAccountBody: Encodable {
    let googleAccountId: String
}

struct GoogleUnlinkAccountRequest: ApiRequest {
    typealias U = EmptyBody
    let uri = "/integration/google/unlink-account"
    let logKey = "/integration/google/unlink-account"
    let method = HttpMethod.post
    let body: GoogleUnlinkAccountBody
}

struct AccountCalendarSwitchBody: Encodable {
    let accountId: String
    let calendarId: String
}

struct CalendarAddRequest: ApiRequest {
    typealias U = EmptyBody
    let uri = "/calendar/calendars/add"
    let logKey = "/calendar/calendars/add"
    let method = HttpMethod.post
    let body: AccountCalendarSwitchBody
}

struct CalendarRemoveRequest: ApiRequest {
    typealias U = EmptyBody
    let uri = "/calendar/calendars/remove"
    let logKey = "/calendar/calendars/remove"
    let method = HttpMethod.post
    let body: AccountCalendarSwitchBody
}

class ConnectedCalendarView: UIView {

    private let handleSwitch: (Bool, @escaping (Bool) -> Void) -> Void

    init(calendar: CalendarMetadata, handleSwitch: @escaping (Bool, @escaping (Bool) -> Void) -> Void) {
        self.handleSwitch = handleSwitch
        super.init(frame: .zero)

        let bubble = UIView().forAutoLayout()
        bubble.layer.cornerRadius = 8
        bubble.layer.masksToBounds = true
        bubble.backgroundColor = (calendar.colour?.fromHex ?? Int.samaHexBase).fromHexToColour()
        addSubview(bubble)
        NSLayoutConstraint.activate([
            bubble.widthAnchor.constraint(equalToConstant: 16),
            bubble.heightAnchor.constraint(equalToConstant: 16),
            bubble.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            bubble.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        let toggle = UISwitch().forAutoLayout()
        toggle.onTintColor = .primary
        toggle.isOn = calendar.selected
        addSubview(toggle)
        NSLayoutConstraint.activate([
            trailingAnchor.constraint(equalTo: toggle.trailingAnchor),
            toggle.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        toggle.addTarget(self, action: #selector(onToggle(_:)), for: .valueChanged)

        let title = UILabel().forAutoLayout()
        title.textColor = calendar.colour.samafiedHex.fromHexToColour()
        title.font = .brandedFont(ofSize: 24, weight: .semibold)
        title.text = calendar.title
        addSubview(title)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: 12),
            toggle.leadingAnchor.constraint(equalTo: title.trailingAnchor),
            title.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 64)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onToggle(_ toggle: UISwitch) {
        toggle.isUserInteractionEnabled = false
        let oldValue = !toggle.isOn
        handleSwitch(toggle.isOn) { isSuccess in
            if !isSuccess {
                toggle.setOn(oldValue, animated: true)
            }
            toggle.isUserInteractionEnabled = true
        }
    }
}

class ConnectedGoogleAccountScreen: UIViewController {

    var api: Api!
    var account: LinkedAccount!
    var onReload: (() -> Void)?

    private var topBar: UIView!

    private var accountCalendars: [CalendarMetadata] = []
    private var isPerformingAction = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        isModalInPresentation = true

        addNavigationBar()

        let title = UILabel().forAutoLayout()
        title.text = account.email
        title.makeMultiline()
        title.font = .brandedFont(ofSize: 28, weight: .semibold)
        title.textColor = .neutral1
        view.addSubview(title)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            view.trailingAnchor.constraint(equalTo: title.trailingAnchor, constant: 40),
            title.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 16)
        ])

        let googleImg = UIImageView(image: UIImage(named: "google-logo")!).forAutoLayout()
        let googleText = UILabel().forAutoLayout()
        googleText.text = "Google Calendar"
        googleText.font = .brandedFont(ofSize: 20, weight: .regular)
        googleText.textColor = .secondary
        view.addSubview(googleImg)
        view.addSubview(googleText)
        NSLayoutConstraint.activate([
            googleImg.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            googleImg.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            googleText.centerYAnchor.constraint(equalTo: googleImg.centerYAnchor),
            googleText.leadingAnchor.constraint(equalTo: googleImg.trailingAnchor, constant: 16)
        ])

        let disconnectBtn = UIButton(type: .system)
        disconnectBtn.addTarget(self, action: #selector(onDisconnectGoogle), for: .touchUpInside)
        disconnectBtn.translatesAutoresizingMaskIntoConstraints = false
        disconnectBtn.setTitle("Disconnect Calendar", for: .normal)
        disconnectBtn.setTitleColor(.primary, for: .normal)
        disconnectBtn.titleLabel?.font = .brandedFont(ofSize: 24, weight: .regular)
        view.addSubview(disconnectBtn)
        let disconnectBtnTopToGoogleImg = disconnectBtn.topAnchor.constraint(equalTo: googleImg.bottomAnchor, constant: 66)
        disconnectBtnTopToGoogleImg.priority = .defaultLow
        NSLayoutConstraint.activate([
            disconnectBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            disconnectBtnTopToGoogleImg
        ])

        api.request(for: CalendarsRequest()) {
            switch $0 {
            case let .success(result):
                self.accountCalendars = result.calendars
                    .filter { $0.accountId == self.account.id }
                self.displayCalendars(
                    topView: googleImg,
                    bottomView: disconnectBtn
                )
            case .failure:
                break
            }
        }
    }

    private func addNavigationBar() {
        topBar = UIView().forAutoLayout()
        view.addSubview(topBar)
        topBar.pinLeadingAndTrailing(top: 0, and: [topBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44)])

        let backBtn = UIButton(type: .system)
        backBtn.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.setImage(UIImage(named: "arrow-back")!, for: .normal)
        backBtn.setTitle("Back", for: .normal)
        backBtn.titleLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
        backBtn.titleEdgeInsets.left = 8
        backBtn.titleEdgeInsets.right = -8
        backBtn.contentEdgeInsets.right = 8
        backBtn.tintColor = .primary
        backBtn.tintAdjustmentMode = .normal

        view.addSubview(backBtn)

        NSLayoutConstraint.activate([
            backBtn.heightAnchor.constraint(equalToConstant: 44),
            backBtn.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 8),
            backBtn.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])
    }

    private func displayCalendars(topView: UIView, bottomView: UIView) {
        let calendarsStack = UIStackView().forAutoLayout()
        calendarsStack.axis = .vertical

        accountCalendars.enumerated().forEach { idx, calendar in
            calendarsStack.addArrangedSubview(ConnectedCalendarView(calendar: calendar) { [weak self] isSelected, completion in
                self?.switchCalendar(index: idx, isSelected: isSelected, completion: completion)
            })
        }

        self.view.addSubview(calendarsStack)
        NSLayoutConstraint.activate([
            calendarsStack.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 40),
            self.view.trailingAnchor.constraint(equalTo: calendarsStack.trailingAnchor, constant: 40),
            calendarsStack.topAnchor.constraint(equalTo: topView.bottomAnchor, constant: 52),
            bottomView.topAnchor.constraint(equalTo: calendarsStack.bottomAnchor, constant: 52)
        ])
    }

    private func switchCalendar(index: Int, isSelected: Bool, completion: @escaping (Bool) -> Void) {
        Sama.bi.track(event: "toggle-calendar", parameters: ["enable": isSelected])

        let body = AccountCalendarSwitchBody(
            accountId: account.id,
            calendarId: accountCalendars[index].calendarId
        )
        let completion: (Result<EmptyBody, ApiError>) -> Void = { [weak self] result in
            switch result {
            case .success:
                completion(true)
                self?.onReload?()
            case let .failure(err):
                completion(false)
                self?.presentError(err)
            }
        }
        if isSelected {
            api.request(for: CalendarAddRequest(body: body), completion: completion)
        } else {
            api.request(for: CalendarRemoveRequest(body: body), completion: completion)
        }
    }

    @objc private func onBack() {
        guard !isPerformingAction else { return }
        navigationController?.popViewController(animated: true)
    }

    @objc private func onDisconnectGoogle() {
        guard !isPerformingAction else { return }
        isPerformingAction = true

        Sama.bi.track(event: "disconnect-account")

        api.request(for: GoogleUnlinkAccountRequest(body: GoogleUnlinkAccountBody(googleAccountId: account.id))) { [weak self] in
            switch $0 {
            case .success:
                self?.onReload?()
                self?.navigationController?.popViewController(animated: true)
            case let .failure(err):
                print(err)
            }

            self?.isPerformingAction = false
        }
    }
}
