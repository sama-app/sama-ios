//
//  CalendarViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit

class CalendarViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    var session: CalendarSession!

    private var calendar: UICollectionView!
    private var timeline: TimelineView!
    private var timelineScrollView: UIScrollView!
    private var slotPickerContainer: UIView!

    private var navCenter = CalendarNavigationCenter()

    private var cellSize: CGSize = .zero
    private var vOffset: CGFloat = 0
    private var isFirstLoad: Bool = true
    private var isCalendarReady = false

    private var scrollLock = ScrollLock(origin: .zero)

    private var eventProperties: [EventProperties] = []
    private var eventViews: [UIView] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        self.setupViews()
        session.reloadHandler = { [weak self] in self?.calendar.reloadData() }
        session.loadInitial()

        navCenter.onActivePanelHeightChange = {
            self.calendar.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: $0, right: 0)
        }
        let panel = FindTimePanel()
        panel.token = session.token
        panel.targetTimezoneChangeHandler = { [weak self] in
            self?.timeline.targetTimezoneHoursDiff = ($0 - 3)
        }
        panel.onEventDatesEvent = {
            switch $0 {
            case .reset:
                self.resetEventViews()
            case let .show(props):
                self.setupEventViews(props)
            }
        }
        navCenter.pushBlock(panel, animated: false)
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
        }
        isFirstLoad = false
    }

    private func setupViews() {
        let timelineWidth: CGFloat = 56
        cellSize = CGSize(width: (view.frame.width - timelineWidth) / 4, height: 65)

        let contentVPadding: CGFloat = 48
        let contentHeight = cellSize.height * 24 + contentVPadding * 2
        let timelineSize = CGSize(width: timelineWidth, height: contentHeight)
        let calendarSize = CGSize(width: cellSize.width * 7, height: contentHeight)
        vOffset = contentVPadding

        let topBar = setupTopBar()

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

//        let scrollView = UIScrollView(frame: .zero)
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(scrollView)
//        NSLayoutConstraint.activate([
//            scrollView.leadingAnchor.constraint(equalTo: timelineScrollView.trailingAnchor),
//            scrollView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
//            view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//            view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
//        ])

        timeline = TimelineView(frame: CGRect(origin: .zero, size: timelineSize))
        timeline.cellSize = cellSize
        timeline.vOffset = contentVPadding
        timelineScrollView.contentSize = timelineSize
        timelineScrollView.addSubview(timeline)

//        let view = UIView(frame: CGRect(origin: .zero, size: calendarSize))
//        scrollView.addSubview(view)
//        scrollView.contentSize = calendarSize
//        scrollView.delegate = self
//        scrollView.isDirectionalLockEnabled = true

        self.drawCalendar(topBar: topBar, cellSize: cellSize, vOffset: contentVPadding)

        slotPickerContainer = ChildrenInteractiveView()
        slotPickerContainer.layer.masksToBounds = true
        slotPickerContainer.backgroundColor = .clear
        slotPickerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slotPickerContainer)
        NSLayoutConstraint.activate([
            slotPickerContainer.leadingAnchor.constraint(equalTo: timelineScrollView.trailingAnchor),
            slotPickerContainer.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 48),
            view.trailingAnchor.constraint(equalTo: slotPickerContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: slotPickerContainer.bottomAnchor)
        ])

        navCenter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navCenter)
        NSLayoutConstraint.activate([
            navCenter.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            navCenter.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: navCenter.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: navCenter.bottomAnchor)
        ])
    }

    func setupTopBar() -> UIView {
        let topBar = UIView(frame: .zero)
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = .base
        view.addSubview(topBar)
        topBar.pinLeadingAndTrailing(top: 0, and: [topBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44)])

        let separator = UIView(frame: .zero)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .calendarGrid
        topBar.addSubview(separator)
        separator.pinLeadingAndTrailing(bottom: 0, and: [separator.heightAnchor.constraint(equalToConstant: 1)])

        let title = UILabel(frame: .zero)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textColor = .neutral1
        title.font = .brandedFont(ofSize: 24, weight: .regular)
        title.text = "Sama"
        topBar.addSubview(title)
        NSLayoutConstraint.activate([
            title.centerYAnchor.constraint(equalTo: topBar.safeAreaLayoutGuide.centerYAnchor),
            title.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16)
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

        return topBar
    }

    private func setupEventViews(_ props: [EventProperties]) {
        eventViews = props.map { _ in
            let eventView = EventView()
            eventView.isUserInteractionEnabled = true
            slotPickerContainer.addSubview(eventView)
            return eventView
        }
        eventProperties = props

        repositionEventViews()
    }

    private func repositionEventViews() {
        let count = eventProperties.count
        for i in (0 ..< count) {
            let eventProps = eventProperties[i]
            let eventView = eventViews[i]

            let start = eventProps.start
            let duration = eventProps.duration
            eventView.frame = CGRect(
                x: CGFloat(session.currentDayIndex + eventProps.daysOffset) * cellSize.width - calendar.contentOffset.x,
                y: CGFloat(truncating: start as NSNumber) * cellSize.height + 1 - calendar.contentOffset.y,
                width: cellSize.width,
                height: CGFloat(truncating: duration as NSNumber) * cellSize.height
            )
        }
    }

    private func resetEventViews() {
        for v in eventViews {
            v.removeFromSuperview()
        }
        eventViews = []
        eventProperties = []
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
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollLock = ScrollLock(origin: scrollView.contentOffset)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.contentOffset = scrollLock.lockIfUnlockedAndAdjust(offset: scrollView.contentOffset)

        timelineScrollView.contentOffset.y = scrollView.contentOffset.y
        timeline.headerInset = scrollView.contentOffset.y
        for cell in calendar.visibleCells {
            (cell as! CalendarDayCell).headerInset = scrollView.contentOffset.y
        }
        repositionEventViews()
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

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dayCell", for: indexPath) as! CalendarDayCell
        cell.headerInset = collectionView.contentOffset.y
        cell.cellSize = cellSize
        cell.vOffset = vOffset
        cell.blockedTimes = session.blocksForDayIndex[indexPath.item] ?? []
        cell.isCurrentDay = (indexPath.item == session.currentDayIndex)
        let daysOffset = -session.currentDayIndex + indexPath.item
        cell.date = Calendar.current.date(byAdding: .day, value: daysOffset, to: Date())
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
