//
//  CalendarViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit

class CalendarViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    enum ColumnsView {
        case single
        case five
        case seven
    }

    struct ColumnsSetting {
        let view: ColumnsView
        let count: Int
        let centerOffset: Int
    }

    var session: CalendarSession!

    private var topBar: CalendarTopBar!
    private var calendar: UICollectionView!
    private var timeline: TimelineView!
    private var timelineScrollView: UIScrollView!
    private var slotPickerContainer: UIView!
    private var slotPickerTopConstraint: NSLayoutConstraint!

    private var navCenter = CalendarNavigationCenter()
    private var navCenterBottomConstraint: NSLayoutConstraint!

    private var cellSize: CGSize = .zero
    private var isFirstLoad: Bool = true
    private var isCalendarReady = false

    private var lastCalendarAutoUpdate = CalendarDateUtils.shared.dateNow

    private var scrollLock: ScrollLock?

    private var eventsCoordinator: EventsCoordinator!
    private var suggestionsViewCoordinator: SuggestionsViewCoordinator!

    private var columnsDisplay: ColumnsSetting!

    private let timelineWidth: CGFloat = 56

    private var defaultColumnsDisplay: ColumnsSetting {
        if Ui.isWideScreen() {
            return ColumnsSetting(view: .seven, count: 7, centerOffset: -3)
        } else {
            return ColumnsSetting(view: .five, count: 5, centerOffset: -2)
        }
    }
    private var calculatedCellSize: CGSize {
        CGSize(
            width: (view.frame.width - timelineWidth) / CGFloat(columnsDisplay.count),
            height: 65
        )
    }
    private var calculatedTopInset: CGFloat {
        if columnsDisplay.view == .single {
            return Sama.env.ui.calenarNoHeaderHeight
        } else {
            return Sama.env.ui.calenarHeaderHeight
        }
    }
    private var calculatedTimelineSize: CGSize {
        let contentHeight = cellSize.height * 24 + calculatedTopInset * 2
        return CGSize(width: timelineWidth, height: contentHeight)
    }
    private var calendarViewImage: UIImage {
        switch columnsDisplay.view {
        case .single:
            return UIImage(named: "calendar-view-day")!
        case .five, .seven:
            return UIImage(named: "calendar-view-five-day")!
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        columnsDisplay = defaultColumnsDisplay

        setupTopBar()
        setupViews()

        eventsCoordinator = EventsCoordinator(
            api: session.api,
            currentDayIndex: session.currentDayIndex,
            context: session,
            calendar: calendar,
            container: slotPickerContainer
        )
        eventsCoordinator.columnsCenterOffset = columnsDisplay.centerOffset
        eventsCoordinator.topInset = calculatedTopInset
        eventsCoordinator.cellSize = cellSize
        eventsCoordinator.presentError = { [weak self] in self?.presentError($0) }
        eventsCoordinator.presentProposal = { [weak self] message in
            let sheet = UIActivityViewController(activityItems: [message], applicationActivities: nil)
            self?.present(sheet, animated: true)
        }
        suggestionsViewCoordinator = SuggestionsViewCoordinator(
            api: session.api,
            currentDayIndex: session.currentDayIndex,
            context: session,
            calendar: calendar,
            container: slotPickerContainer
        )
        suggestionsViewCoordinator.columnsCenterOffset = columnsDisplay.centerOffset
        suggestionsViewCoordinator.topInset = calculatedTopInset
        suggestionsViewCoordinator.cellSize = cellSize
        suggestionsViewCoordinator.onReset = { [weak self] in
            guard let self = self else { return }

            self.view.endEditing(true)
            self.navCenter.popToRoot()
            self.topBar.setupCalendarScreenTopBar()

            self.invalidateDataAndReloadDisplayedBlocks(timeout: 1.5)
        }
        suggestionsViewCoordinator.presentError = { [weak self] in self?.presentError($0) }

        session.reloadHandler = { [weak self] in self?.calendar.reloadData() }
        session.userIdUpdateHandler = { Sama.bi.setUserId($0) }
        session.presentError = { [weak self] in self?.presentError($0) }
        session.loadInitial()

        AppLifecycleService.shared.onWillEnterForeground = { [weak self] in
            guard let self = self else { return }
            if CalendarDateUtils.shared.dateNow.timeIntervalSince(self.lastCalendarAutoUpdate) > 30 {
                self.lastCalendarAutoUpdate = CalendarDateUtils.shared.dateNow
                self.invalidateDataAndReloadDisplayedBlocks(timeout: 0)
            }
        }

        navCenter.onActivePanelHeightChange = { [weak self] in
            self?.timelineScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: $0, right: 0)
            self?.calendar.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: $0, right: 0)
        }
        let panel = FindTimePanel()
        panel.coordinator = eventsCoordinator
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
                if let httpErr = $0.httpError, httpErr.code == 404 {
                    let alert = UIAlertController(title: nil, message: "This meeting does not exist or has expired.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else if let httpErr = $0.httpError, httpErr.details?.reason == "already_confirmed" {
                    let alert = UIAlertController(title: nil, message: "Time for this meeting has already been confirmed.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.presentError($0)
                }
            }

            let picker = SuggestionsPickerView(parentWidth: self.navCenter.frame.width)
            picker.coordinator = self.suggestionsViewCoordinator
            self.navCenter.pushUnstyledBlock(picker, animated: true)

            self.topBar.setupMeetingInviteTopBar()
        }
    }

    private func presentError(_ err: ApiError) {
        switch err {
        case let .http(httpErr):
            if (500 ..< 600).contains(httpErr.code) {
                let alert = UIAlertController(
                    title: "Sama servers cannot be reached",
                    message: "Sama servers are currently not responding. Please try again later",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(
                    title: "Unexpected error occurred",
                    message: "App received unexpected server error",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        case let .network(err):
            if err.isOffline {
                let alert = UIAlertController(
                    title: "Your internet connection appears to be offline",
                    message: "It looks like you are not connected to the internet.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(
                    title: "Unexpected error occurred",
                    message: "App received unexpected network error",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        case .parsing, .unknown:
            let alert = UIAlertController(title: nil, message: "Unexpected error occurred", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Sama.bi.track(event: "home")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirstLoad {
            let startOfDay = Calendar.current.startOfDay(for: CalendarDateUtils.shared.dateNow)
            let absHours = CalendarDateUtils.shared.dateNow.timeIntervalSince(startOfDay) / 3600
            let hr = CGFloat(ceil(absHours))
            let y = calculatedTopInset + cellSize.height * (hr + 1) - calendar.bounds.height / 2
            calendar.contentOffset = CGPoint(
                x: cellSize.width * CGFloat(session.firstFocusDayIndex(centerOffset: columnsDisplay.centerOffset)),
                y: y
            )
            DispatchQueue.main.async {
                self.scrollViewDidScroll(self.calendar)
            }
        }
        isFirstLoad = false
    }

    private func setupTopBar() {
        topBar = CalendarTopBar(frame: .zero)
        view.addSubview(topBar)
        topBar.pinLeadingAndTrailing(top: 0, and: [topBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44)])

        topBar.calendarViewImage = calendarViewImage
        topBar.isSingleDayStyle = columnsDisplay.view == .single

        topBar.setupCalendarScreenTopBar()

        topBar.handleProfileIntent = { [weak self] in self?.present(ProfileViewController(), animated: true, completion: nil) }
        topBar.handleMeetingInviteClose = { [weak self] in self?.suggestionsViewCoordinator.reset() }
        topBar.handleCalendarViewSwitch = { [weak self] in self?.switchCalendarView() }
    }

    private func setupViews() {
        cellSize = calculatedCellSize

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

        timeline = TimelineView(frame: CGRect(origin: .zero, size: calculatedTimelineSize))
        timeline.cellSize = cellSize
        timeline.showInfoInHeader(true, headerHeight: calculatedTopInset)
        timelineScrollView.contentSize = calculatedTimelineSize
        timelineScrollView.addSubview(timeline)

        self.drawCalendar(topBar: topBar, cellSize: cellSize)

        slotPickerContainer = ChildrenInteractiveView()
        slotPickerContainer.layer.masksToBounds = true
        slotPickerContainer.backgroundColor = .clear
        slotPickerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slotPickerContainer)
        slotPickerTopConstraint = slotPickerContainer.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: calculatedTopInset)
        NSLayoutConstraint.activate([
            slotPickerContainer.leadingAnchor.constraint(equalTo: timelineScrollView.trailingAnchor),
            slotPickerTopConstraint,
            view.trailingAnchor.constraint(equalTo: slotPickerContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: slotPickerContainer.bottomAnchor)
        ])

        navCenter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navCenter)

        navCenterBottomConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: navCenter.bottomAnchor)

        let horizontalConstraints: [NSLayoutConstraint]
        if Ui.isWideScreen() {
            horizontalConstraints = [
                navCenter.widthAnchor.constraint(equalToConstant: 360),
                navCenter.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ]
        } else {
            horizontalConstraints = [
                navCenter.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: navCenter.trailingAnchor)
            ]
        }

        NSLayoutConstraint.activate(horizontalConstraints + [
            navCenter.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            navCenterBottomConstraint
        ])
        navCenter.layoutIfNeeded()
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

    private func getVisibleColumnIndices() -> [Int] {
        let indexPathsAndOffsets = calendar.indexPathsForVisibleItems.reduce([] as [(IndexPath, CGFloat)]) { result, indexPath in
            if let cell = calendar.cellForItem(at: indexPath) {
                return result + [(indexPath, cell.frame.midX - calendar.contentOffset.x)]
            } else {
                return result
            }
        }
        return indexPathsAndOffsets
            .filter { (_, offset) in offset > 0 }
            .sorted(by: { $0.1 < $1.1 })
            .map { $0.0.item }
    }

    private func changeDisplayedMonth() {
        let leftMostColumnIdx = getVisibleColumnIndices().first

        if let index = leftMostColumnIdx {
            let daysOffset = -session.currentDayIndex + index
            let date = Calendar.current.date(byAdding: .day, value: daysOffset, to: session.refDate)!
            topBar.displayedDate = date
        }
    }

    private func makeCalendarLayout() -> CalendarLayout {
        return CalendarLayout(size: CGSize(width: cellSize.width, height: cellSize.height * 24 + 2 * calculatedTopInset))
    }

    private func drawCalendar(topBar: UIView, cellSize: CGSize) {
        calendar = UICollectionView(frame: .zero, collectionViewLayout: makeCalendarLayout())
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
        cell.blockedTimes = session.blocksForDayIndex[indexPath.item] ?? []
        let daysOffset = -session.currentDayIndex + indexPath.item
        let date = Calendar.current.date(byAdding: .day, value: daysOffset, to: session.refDate)!
        cell.isCurrentDay = Calendar.current.isDate(date, inSameDayAs: CalendarDateUtils.shared.dateNow)
        cell.date = date
        cell.setNeedsDisplay()
        cell.showDateInHeader(columnsDisplay.view != .single, headerHeight: calculatedTopInset)

        if isCalendarReady {
            session.loadIfAvailableBlock(at: Int(round(Double(daysOffset) / Double(session.blockSize))))
        }
        return cell
    }

    private func switchCalendarView() {
        if columnsDisplay.view == .single {
            columnsDisplay = defaultColumnsDisplay
        } else {
            columnsDisplay = ColumnsSetting(view: .single, count: 1, centerOffset: 0)
        }

        topBar.calendarViewImage = calendarViewImage
        topBar.isSingleDayStyle = columnsDisplay.view == .single

        cellSize = calculatedCellSize
        slotPickerTopConstraint.constant = calculatedTopInset

        eventsCoordinator.columnsCenterOffset = columnsDisplay.centerOffset
        eventsCoordinator.topInset = calculatedTopInset
        eventsCoordinator.cellSize = cellSize

        suggestionsViewCoordinator.columnsCenterOffset = columnsDisplay.centerOffset
        suggestionsViewCoordinator.topInset = calculatedTopInset
        suggestionsViewCoordinator.cellSize = cellSize

        timeline.frame.size = calculatedTimelineSize
        timelineScrollView.contentSize = calculatedTimelineSize
        timeline.showInfoInHeader(columnsDisplay.view != .single, headerHeight: calculatedTopInset)

        let y = calendar.contentOffset.y
        let xIdx = session.focusDay(isSingleDay: columnsDisplay.view == .single, visibleColumnIndices: getVisibleColumnIndices())
        calendar.setCollectionViewLayout(makeCalendarLayout(), animated: false)
        calendar.reloadData()
        calendar.contentOffset = CGPoint(
            x: cellSize.width * CGFloat(xIdx),
            y: y
        )
        DispatchQueue.main.async {
            self.scrollViewDidScroll(self.calendar)
        }
    }
}

private class ChildrenInteractiveView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let target = super.hitTest(point, with: event)
        return target != self ? target : nil
    }
}
