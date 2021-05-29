//
//  ViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/4/21.
//

import UIKit
import AuthenticationServices

class ViewController: UIViewController, ASWebAuthenticationPresentationContextProviding, UIScrollViewDelegate {

//    @IBOutlet private var connectButton: UIButton!
//    @IBOutlet private var disconnectButton: UIButton!
//    @IBOutlet private var fetchCalendarButton: UIButton!

    private var isLoggedIn = false {
        didSet {
//            connectButton.isHidden = isLoggedIn
//            disconnectButton.isHidden = !isLoggedIn
//            fetchCalendarButton.isHidden = !isLoggedIn
        }
    }

    private var timelineScrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        isLoggedIn = UserDefaults.standard.data(forKey: "SAMA_AUTH_TOKEN") != nil

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        self.setupViews()
    }

    private func setupViews() {
        let timelineWidth: CGFloat = 56
        let cellSize = CGSize(width: 100, height: 65)

        let contentVPadding: CGFloat = 20
        let contentHeight = cellSize.height * 24 + contentVPadding * 2
        let timelineSize = CGSize(width: timelineWidth, height: contentHeight)
        let calendarSize = CGSize(width: cellSize.width * 7 + timelineWidth, height: contentHeight)

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

        let scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: timelineScrollView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])

        let timeline = TimelineView(frame: CGRect(origin: .zero, size: timelineSize))
        timeline.cellSize = cellSize
        timeline.vOffset = contentVPadding
        timelineScrollView.contentSize = timelineSize
        timelineScrollView.addSubview(timeline)

        let view = UIView(frame: CGRect(origin: .zero, size: calendarSize))
        scrollView.addSubview(view)
        scrollView.contentSize = calendarSize
        scrollView.delegate = self
        scrollView.isDirectionalLockEnabled = true

        self.drawCalendar(in: view, cellSize: cellSize, vOffset: contentVPadding)
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
        title.font = .systemFont(ofSize: 24)
        title.text = "Sama"
        topBar.addSubview(title)
        NSLayoutConstraint.activate([
            title.centerYAnchor.constraint(equalTo: topBar.safeAreaLayoutGuide.centerYAnchor),
            title.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16)
        ])

        return topBar
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if (abs(velocity.x) > 0.01) {
            let i = Int((scrollView.contentOffset.x - 80) / 220)
            if (abs(velocity.x) > 0.4) {
                let newI: Int
                if (velocity.x > 0) {
                    newI = i + 1
                } else {
                    newI = i
                }
                targetContentOffset.pointee = CGPoint(x: (newI > 0 ? -45 : 0) + 220 * CGFloat(newI), y: scrollView.contentOffset.y)
            } else {
                let i = Int((scrollView.contentOffset.x - 80) / 220)
                targetContentOffset.pointee = CGPoint(x: 220 * CGFloat(i), y: scrollView.contentOffset.y)
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        timelineScrollView.contentOffset.y = scrollView.contentOffset.y
    }

    private func drawCalendar(in view: UIView, cellSize: CGSize, vOffset: CGFloat) {
        let calendar = CalendarView(frame: .zero)
        calendar.cellSize = cellSize
        calendar.vOffset = vOffset
        calendar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendar)
        NSLayoutConstraint.activate([
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendar.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: calendar.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: calendar.bottomAnchor)
        ])
    }

    @IBAction func onConnectCalendar(_ sender: Any) {
        var req = URLRequest(url: URL(string: "https://app.yoursama.com/api/auth/google-authorize")!)
        req.httpMethod = "post"
        URLSession.shared.dataTask(with: req) { (data, resp, err) in
            if let data = data, let directions = try? JSONDecoder().decode(AuthDirections.self, from: data) {
                DispatchQueue.main.async {
                    print(directions)
                    self.authenticate(with: directions.authorizationUrl)
                }
            }
        }.resume()
    }

    @IBAction func onDisconnectCalendar(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "SAMA_AUTH_TOKEN")
        isLoggedIn = false
    }

    @IBAction func onFetchCalendar(_ sender: Any) {
        guard
            let tokenData = UserDefaults.standard.data(forKey: "SAMA_AUTH_TOKEN"),
            let token = try? JSONDecoder().decode(AuthToken.self, from: tokenData)
        else { return }
        var req = URLRequest(url: URL(string: "https://app.yoursama.com/api/calendar")!)
        req.httpMethod = "get"
        req.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: req) { (data, resp, err) in
            print("")
        }.resume()
    }

    private func authenticate(with url: String) {
        let session = ASWebAuthenticationSession(url: URL(string: url)!, callbackURLScheme: "yoursama") { (callbackUrl, err) in
            guard
                let url = callbackUrl,
                url.scheme == "yoursama",
                url.host == "auth",
                url.path == "/success",
                let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                let accessToken = queryItems.first(where: { $0.name == "accessToken" })?.value,
                let refreshToken = queryItems.first(where: { $0.name == "refreshToken" })?.value
            else { return }

            let token = AuthToken(accessToken: accessToken, refreshToken: refreshToken)
            UserDefaults.standard.set(try? JSONEncoder().encode(token), forKey: "SAMA_AUTH_TOKEN")
            RemoteNotificationsTokenSync.shared.syncToken()
            self.isLoggedIn = true
        }
        session.presentationContextProvider = self
        session.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}
