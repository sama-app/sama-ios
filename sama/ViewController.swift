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

        view.backgroundColor = UIColor(red: 248/255.0, green: 224/255.0, blue: 197/255.0, alpha: 1)
        overrideUserInterfaceStyle = .light

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.setupViews()
        }
    }

    private func setupViews() {
        timelineScrollView = UIScrollView(frame: .zero)
        timelineScrollView.translatesAutoresizingMaskIntoConstraints = false
        timelineScrollView.isUserInteractionEnabled = false
        view.addSubview(timelineScrollView)
        NSLayoutConstraint.activate([
            timelineScrollView.widthAnchor.constraint(equalToConstant: 80),
            timelineScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timelineScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: timelineScrollView.bottomAnchor)
        ])

        let scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: timelineScrollView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])

        let timeline = TimelineView(frame: CGRect(x: 0, y: 0, width: 80, height: 65 * 24 + 20 * 2))
        timelineScrollView.contentSize = CGSize(width: 80, height: 65 * 24 + 20 * 2)
        timelineScrollView.addSubview(timeline)

        let contentSize = CGSize(width: 1620, height: 65 * 24 + 20 * 2)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height))
        scrollView.addSubview(view)
        scrollView.contentSize = contentSize
        scrollView.delegate = self
        scrollView.isDirectionalLockEnabled = true
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.drawCalendar(in: view)
//        }
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

    private func drawCalendar(in view: UIView) {
        let calendar = CalendarView(frame: .zero)
        calendar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendar)
        NSLayoutConstraint.activate([
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendar.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: calendar.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: calendar.bottomAnchor)
        ])
    }

    private func viewCalendar() {
        for i in (0 ..< Int(view.frame.width / 10)) {
            for j in (0 ..< Int(view.frame.height / 10)) {
                let v = UIView(frame: CGRect(x: i * 10, y: j * 10, width: 10, height: 10))
                v.backgroundColor = UIColor(red: CGFloat.random(in: (0 ..< 256)) / 255.0, green: CGFloat.random(in: (0 ..< 256)) / 255.0, blue: CGFloat.random(in: (0 ..< 256)) / 255.0, alpha: 1.0)
                view.addSubview(v)
            }
        }
    }

    private func autolayoutCalendar() {
        for i in (0 ..< Int(view.frame.width / 10)) {
            for j in (0 ..< Int(view.frame.height / 10)) {
                let v = UIView(frame: .zero)
                v.translatesAutoresizingMaskIntoConstraints = false
                v.backgroundColor = UIColor(red: CGFloat.random(in: (0 ..< 256)) / 255.0, green: CGFloat.random(in: (0 ..< 256)) / 255.0, blue: CGFloat.random(in: (0 ..< 256)) / 255.0, alpha: 1.0)
                view.addSubview(v)
                NSLayoutConstraint.activate([
                    v.widthAnchor.constraint(equalToConstant: 10),
                    v.heightAnchor.constraint(equalToConstant: 10),
                    v.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: CGFloat(i * 10)),
                    v.topAnchor.constraint(equalTo: view.topAnchor, constant: CGFloat(j * 10)),
                ])
            }
        }
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
