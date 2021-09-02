//
//  CalendarViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit

class CalendarViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    var session: CalendarSession!

    private var topBar: UIView!
    private var calendar: UICollectionView!
    private var timeline: TimelineView!
    private var timelineScrollView: UIScrollView!
    private var slotPickerContainer: UIView!

    private var navCenter = CalendarNavigationCenter()
    private var navCenterBottomConstraint: NSLayoutConstraint!

    private var cellSize: CGSize = .zero
    private var vOffset: CGFloat = 0
    private var isFirstLoad: Bool = true
    private var isCalendarReady = false

    private var scrollLock: ScrollLock?

    private var eventsCoordinator: EventsCoordinator!
    private var suggestionsViewCoordinator: SuggestionsViewCoordinator!

    private lazy var monthTitle: UILabel = {
        let title = UILabel(frame: .zero)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textColor = .neutral1
        title.font = .brandedFont(ofSize: 24, weight: .regular)
        return title
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        self.setupViews()
        eventsCoordinator = EventsCoordinator(
            api: session.api,
            currentDayIndex: session.currentDayIndex,
            context: session,
            cellSize: cellSize,
            calendar: calendar,
            container: slotPickerContainer
        )
        suggestionsViewCoordinator = SuggestionsViewCoordinator(
            api: session.api,
            currentDayIndex: session.currentDayIndex,
            context: session,
            cellSize: cellSize,
            calendar: calendar,
            container: slotPickerContainer
        )
        suggestionsViewCoordinator.onReset = { [weak self] in
            guard let self = self else { return }

            self.view.endEditing(true)
            self.navCenter.popToRoot()
            self.setupCalendarScreenTopBar()

            self.invalidateDataAndReloadDisplayedBlocks(timeout: 1.5)
        }

        session.reloadHandler = { [weak self] in self?.calendar.reloadData() }
        session.loadInitial()

        AppLifecycleService.shared.onWillEnterForeground = { [weak self] in
            self?.invalidateDataAndReloadDisplayedBlocks(timeout: 0)
        }

        navCenter.onActivePanelHeightChange = { [weak self] in
            self?.calendar.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: $0, right: 0)
        }
        let panel = FindTimePanel()
        panel.coordinator = eventsCoordinator
        panel.api = session.api
        panel.targetTimezoneChangeHandler = { [weak self] in
            guard let self = self else { return }
            self.timeline.timezonesDiff = self.eventsCoordinator.timezonesDiffWithSelection($0)
        }
        panel.timezoneChangeIntentHandler = { [weak self] in
            let controller = TimezonePickerViewController()
            controller.selectionId = $0
            controller.optionPickHandler = { [weak panel] in
                Sama.bi.track(event: "timezonepicked", parameters: ["value": $0.hoursFromGMT])
                panel?.changeTimezone(to: $0)
            }
            self?.present(controller, animated: true, completion: nil)
        }
        navCenter.pushBlock(panel, animated: false)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDeviceDayChange),
            name: .NSCalendarDayChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardChange), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardChange), name: UIResponder.keyboardWillHideNotification, object: nil)

        MeetingInviteDeepLinkService.shared.observer = { [weak self] service in
            guard let self = self, let code = service.getAndClear() else { return }

            // TODO: make better reset of current state
            self.suggestionsViewCoordinator.reset()
            self.eventsCoordinator.resetEventViews()
            self.presentedViewController?.dismiss(animated: true, completion: nil)

            self.suggestionsViewCoordinator.present(code: code) {
                if let httpErr = ($0 as? ApiError)?.httpError, httpErr.details?.reason == "already_confirmed" {
                    let alert = UIAlertController(title: nil, message: "Time for this meeting has already been confirmed.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: nil, message: "Unexpected error occurred", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }

            let picker = SuggestionsPickerView(parentWidth: self.view.frame.width)
            picker.coordinator = self.suggestionsViewCoordinator
            self.navCenter.pushUnstyledBlock(picker, animated: true)

            self.setupMeetingInviteTopBar()
        }
    }

    private func invalidateDataAndReloadDisplayedBlocks(timeout: TimeInterval) {
        let blockIdx = self.calendar.indexPathsForVisibleItems.first.flatMap { indexPath -> Int in
            let daysOffset = -self.session.currentDayIndex + indexPath.item
            let blockIdx = Int(round(Double(daysOffset) / Double(self.session.blockSize)))
            return blockIdx
        } ?? 0

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            let range = ((blockIdx - 1) ... (blockIdx + 1))
            self.session.invalidateAndLoadBlocks(range)
        }
    }

    @objc private func onKeyboardChange(_ notification: Notification) {
        let val = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let sf = self.view.safeAreaInsets.bottom
        let inset = self.view.window!.frame.size.height - val!.origin.y - sf
        navCenterBottomConstraint.constant = max(inset, 0)

        UIView.animate(withDuration: 0.3, animations: {
            self.navCenter.setNeedsLayout()
            self.navCenter.layoutIfNeeded()
        }, completion: nil)
    }

    @objc private func onDeviceDayChange() {
        DispatchQueue.main.async {
            self.calendar.reloadData()
        }
    }

    @objc private func onMeetingInviteClose() {
        suggestionsViewCoordinator.reset()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Sama.bi.track(event: "home")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirstLoad {
            let hr = CGFloat(ceil(Date().timeIntervalSince(Calendar.current.startOfDay(for: Date())) / 3600))
            let y = vOffset + cellSize.height * (hr + 1) - calendar.bounds.height / 2
            calendar.contentOffset = CGPoint(
                x: cellSize.width * CGFloat(session.currentDayIndex),
                y: y
            )
            DispatchQueue.main.async {
                self.scrollViewDidScroll(self.calendar)
            }
        }
        isFirstLoad = false
    }

    private func setupViews() {
        let timelineWidth: CGFloat = 56
        cellSize = CGSize(
            width: (view.frame.width - timelineWidth) / CGFloat(Sama.env.ui.columns.count),
            height: 65
        )

        let contentVPadding = Sama.env.ui.calenarHeaderHeight
        let contentHeight = cellSize.height * 24 + contentVPadding * 2
        let timelineSize = CGSize(width: timelineWidth, height: contentHeight)
        vOffset = contentVPadding

        setupTopBar()

        timelineScrollView = UIScrollView(frame: .zero)
        timelineScrollView.translatesAutoresizingMaskIntoConstraints = false
        timelineScrollView.isUserInteractionEnabled = false
        view.addSubview(timelineScrollView)
        NSLayoutConstraint.activate([
            timelineScrollView.widthAnchor.constraint(equalToConstant: timelineWidth),
            timelineScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timelineScrollView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            view.bottomAnchor.constraint(equalTo: timelineScrollView.bottomAnchor)
        ])

        timeline = TimelineView(frame: CGRect(origin: .zero, size: timelineSize))
        timeline.cellSize = cellSize
        timeline.vOffset = contentVPadding
        timelineScrollView.contentSize = timelineSize
        timelineScrollView.addSubview(timeline)

        self.drawCalendar(topBar: topBar, cellSize: cellSize, vOffset: contentVPadding)

        slotPickerContainer = ChildrenInteractiveView()
        slotPickerContainer.layer.masksToBounds = true
        slotPickerContainer.backgroundColor = .clear
        slotPickerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slotPickerContainer)
        NSLayoutConstraint.activate([
            slotPickerContainer.leadingAnchor.constraint(equalTo: timelineScrollView.trailingAnchor),
            slotPickerContainer.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: Sama.env.ui.calenarHeaderHeight),
            view.trailingAnchor.constraint(equalTo: slotPickerContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: slotPickerContainer.bottomAnchor)
        ])

        navCenter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navCenter)

        navCenterBottomConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: navCenter.bottomAnchor)
        NSLayoutConstraint.activate([
            navCenter.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            navCenter.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: navCenter.trailingAnchor),
            navCenterBottomConstraint
        ])
    }

    private var navBarItems: [UIView] = []

    func setupTopBar() {
        topBar = UIView(frame: .zero)
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = .base
        view.addSubview(topBar)
        topBar.pinLeadingAndTrailing(top: 0, and: [topBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44)])

        setupCalendarScreenTopBar()
    }

    private func setupCalendarScreenTopBar() {
        navBarItems.forEach { $0.removeFromSuperview() }

        let iconView = UIImageView(image: UIImage(named: "main-illustration")!)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            iconView.centerYAnchor.constraint(equalTo: topBar.safeAreaLayoutGuide.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 8)
        ])

        topBar.addSubview(monthTitle)
        NSLayoutConstraint.activate([
            monthTitle.centerYAnchor.constraint(equalTo: topBar.safeAreaLayoutGuide.centerYAnchor),
            monthTitle.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8)
        ])

        let profileBtn = UIButton(type: .system)
        profileBtn.translatesAutoresizingMaskIntoConstraints = false
        profileBtn.tintColor = .secondary
        profileBtn.setImage(UIImage(named: "profile")!, for: .normal)
        profileBtn.addTarget(self, action: #selector(onProfileButton), for: .touchUpInside)
        topBar.addSubview(profileBtn)
        NSLayoutConstraint.activate([
            profileBtn.widthAnchor.constraint(equalToConstant: 44),
            profileBtn.heightAnchor.constraint(equalToConstant: 44),
            profileBtn.centerYAnchor.constraint(equalTo: topBar.safeAreaLayoutGuide.centerYAnchor),
            topBar.trailingAnchor.constraint(equalTo: profileBtn.trailingAnchor, constant: 6)
        ])

        navBarItems = [iconView, monthTitle, profileBtn]
    }

    private func setupMeetingInviteTopBar() {
        navBarItems.forEach { $0.removeFromSuperview() }

        let title = UILabel(frame: .zero)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textColor = .neutral1
        title.font = .brandedFont(ofSize: 20, weight: .regular)
        title.text = "Meeting Invite"
        topBar.addSubview(title)
        NSLayoutConstraint.activate([
            title.centerXAnchor.constraint(equalTo: topBar.safeAreaLayoutGuide.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: topBar.safeAreaLayoutGuide.centerYAnchor)
        ])

        let closeBtn = UIButton(type: .system)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.tintColor = .primary
        closeBtn.setTitle("Close", for: .normal)
        closeBtn.titleLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
        closeBtn.addTarget(self, action: #selector(onMeetingInviteClose), for: .touchUpInside)
        topBar.addSubview(closeBtn)
        NSLayoutConstraint.activate([
            closeBtn.heightAnchor.constraint(equalToConstant: 44),
            closeBtn.centerYAnchor.constraint(equalTo: topBar.safeAreaLayoutGuide.centerYAnchor),
            closeBtn.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16)
        ])

        navBarItems = [title, closeBtn]
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let i = round(scrollView.contentOffset.x / cellSize.width)
        let dir = targetContentOffset.pointee.x - scrollView.contentOffset.x
        let j = dir < 0 ? floor(targetContentOffset.pointee.x / cellSize.width) : ceil(targetContentOffset.pointee.x / cellSize.width)
        if abs(targetContentOffset.pointee.x - scrollView.contentOffset.x) < 2 {
            targetContentOffset.pointee = CGPoint(x: i * cellSize.width, y: targetContentOffset.pointee.y)
        } else {
            let z = max(min((j - i), 1), -1)
            let isChangedY = abs(velocity.y) > 0.1
            targetContentOffset.pointee = CGPoint(x: (i + z) * cellSize.width, y: isChangedY ? targetContentOffset.pointee.y : scrollView.contentOffset.y)
        }

        scrollLock = nil
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollLock = ScrollLock(origin: scrollView.contentOffset)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let contentOffset = scrollLock?.lockIfUnlockedAndAdjust(offset: scrollView.contentOffset) {
            scrollView.contentOffset = contentOffset
        }

        timelineScrollView.contentOffset.y = scrollView.contentOffset.y
        timeline.headerInset = scrollView.contentOffset.y
        for cell in calendar.visibleCells {
            (cell as! CalendarDayCell).headerInset = scrollView.contentOffset.y
        }
        eventsCoordinator.repositionEventViews()
        suggestionsViewCoordinator.repositionEventViews()

        changeDisplayedMonth()
    }

    private func changeDisplayedMonth() {
        let indexPathsAndOffsets = calendar.indexPathsForVisibleItems.reduce([] as [(IndexPath, CGFloat)]) { result, indexPath in
            if let cell = calendar.cellForItem(at: indexPath) {
                return result + [(indexPath, cell.frame.midX - calendar.contentOffset.x)]
            } else {
                return result
            }
        }
        let leftMostColumn = indexPathsAndOffsets
            .filter { (_, offset) in offset > 0 }
            .sorted(by: { $0.1 < $1.1 })
            .first?.0

        if let indexPath = leftMostColumn {
            let daysOffset = -session.currentDayIndex + indexPath.item
            let date = Calendar.current.date(byAdding: .day, value: daysOffset, to: session.refDate)!

            let monthNumber = Calendar.current.component(.month, from: date)
            let monthIndex = monthNumber - 1
            monthTitle.text = Calendar.current.monthSymbols[monthIndex]
        }
    }

    private func drawCalendar(topBar: UIView, cellSize: CGSize, vOffset: CGFloat) {
        let layout = CalendarLayout(size: CGSize(width: cellSize.width, height: cellSize.height * 24 + 2 * vOffset))
        calendar = UICollectionView(frame: .zero, collectionViewLayout: layout)
        calendar.isDirectionalLockEnabled = true
        calendar.dataSource = self
        calendar.delegate = self
        calendar.backgroundColor = .base
        calendar.decelerationRate = .fast
        calendar.showsHorizontalScrollIndicator = false
        calendar.showsVerticalScrollIndicator = false
        calendar.register(CalendarDayCell.self, forCellWithReuseIdentifier: "dayCell")
        calendar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendar)
        NSLayoutConstraint.activate([
            calendar.leadingAnchor.constraint(equalTo: timelineScrollView.trailingAnchor),
            calendar.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: calendar.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: calendar.bottomAnchor)
        ])

        calendar.layoutIfNeeded()
        isCalendarReady = true
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10000
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as! CalendarDayCell).headerInset = collectionView.contentOffset.y
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dayCell", for: indexPath) as! CalendarDayCell
        cell.cellSize = cellSize
        cell.vOffset = vOffset
        cell.blockedTimes = session.blocksForDayIndex[indexPath.item] ?? []
        let daysOffset = -session.currentDayIndex + indexPath.item
        let date = Calendar.current.date(byAdding: .day, value: daysOffset, to: session.refDate)!
        cell.isCurrentDay = Calendar.current.isDate(date, inSameDayAs: Date())
        cell.date = date
        cell.setNeedsDisplay()

        if isCalendarReady {
            session.loadIfAvailableBlock(at: Int(round(Double(daysOffset) / Double(session.blockSize))))
        }
        return cell
    }

    @objc private func onProfileButton() {
        present(ProfileViewController(), animated: true, completion: nil)
    }
}

private class ChildrenInteractiveView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let target = super.hitTest(point, with: event)
        return target != self ? target : nil
    }
}
