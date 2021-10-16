//
//  CalendarTopBar.swift
//  sama
//
//  Created by Viktoras Laukevičius on 10/16/21.
//

import UIKit

class CalendarTopBar: UIView {

    var handleCalendarViewSwitch: (() -> Void)?
    var handleProfileIntent: (() -> Void)?
    var handleMeetingInviteClose: (() -> Void)?
    var calendarViewImage = UIImage(named: "calendar-view-five-day")! {
        didSet {
            viewSwitchBtn.setImage(calendarViewImage, for: .normal)
        }
    }

    private lazy var monthTitle: UILabel = {
        let title = UILabel(frame: .zero)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textColor = .neutral1
        title.font = .brandedFont(ofSize: 24, weight: .regular)
        return title
    }()
    private lazy var viewSwitchBtn: UIButton = {
        return UIButton.navigationBarButton(
            image: calendarViewImage,
            target: self,
            action: #selector(onViewSwitch)
        )
    }()

    private var navBarItems: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .base
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func changeDisplayedDate(_ date: Date) {
        let monthNumber = Calendar.current.component(.month, from: date)
        let monthIndex = monthNumber - 1
        monthTitle.text = Calendar.current.monthSymbols[monthIndex]
    }

    func setupCalendarScreenTopBar() {
        navBarItems.forEach { $0.removeFromSuperview() }

        let iconView = UIImageView(image: UIImage(named: "main-illustration")!)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            iconView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        ])

        addSubview(monthTitle)
        NSLayoutConstraint.activate([
            monthTitle.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            monthTitle.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8)
        ])

        let profileBtn = UIButton.navigationBarButton(
            image: UIImage(named: "profile")!,
            target: self,
            action: #selector(onProfileButton)
        )
        addSubview(profileBtn)
        viewSwitchBtn.setImage(calendarViewImage, for: .normal)
        addSubview(viewSwitchBtn)
        NSLayoutConstraint.activate([
            viewSwitchBtn.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            profileBtn.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            trailingAnchor.constraint(equalTo: profileBtn.trailingAnchor, constant: 6),
            profileBtn.leadingAnchor.constraint(equalTo: viewSwitchBtn.trailingAnchor)
        ])

        navBarItems = [iconView, monthTitle, viewSwitchBtn, profileBtn]
    }

    func setupMeetingInviteTopBar() {
        navBarItems.forEach { $0.removeFromSuperview() }

        let title = UILabel(frame: .zero)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textColor = .neutral1
        title.font = .brandedFont(ofSize: 20, weight: .regular)
        title.text = "Meeting Invite"
        addSubview(title)
        NSLayoutConstraint.activate([
            title.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor)
        ])

        let closeBtn = UIButton(type: .system)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.tintColor = .primary
        closeBtn.setTitle("Close", for: .normal)
        closeBtn.titleLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
        closeBtn.addTarget(self, action: #selector(onMeetingInviteClose), for: .touchUpInside)
        addSubview(closeBtn)
        NSLayoutConstraint.activate([
            closeBtn.heightAnchor.constraint(equalToConstant: 44),
            closeBtn.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            closeBtn.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        ])

        navBarItems = [title, closeBtn]
    }

    @objc private func onViewSwitch() {
        handleCalendarViewSwitch?()
    }

    @objc private func onProfileButton() {
        handleProfileIntent?()
    }

    @objc private func onMeetingInviteClose() {
        handleMeetingInviteClose?()
    }
}
