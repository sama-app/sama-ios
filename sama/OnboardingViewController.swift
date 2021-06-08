//
//  OnboardingViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit
import AuthenticationServices

class OnboardingViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        let connectBtn = UIButton(type: .system)
        connectBtn.setTitle("Connect", for: .normal)
        connectBtn.translatesAutoresizingMaskIntoConstraints = false
        connectBtn.setTitleColor(.primary, for: .normal)
        connectBtn.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        connectBtn.addTarget(self, action: #selector(onConnectCalendar), for: .touchUpInside)
        view.addSubview(connectBtn)
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: connectBtn.bottomAnchor, constant: 102),
            connectBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 40)
        ])
    }

    private func startSession(with token: AuthToken) {
        let viewController = CalendarViewController()
        viewController.session = CalendarSession(token: token, currentDayIndex: 5000)
        UIApplication.shared.windows[0].rootViewController = viewController
    }

    @objc private func onConnectCalendar() {
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

            self.startSession(with: token)
        }
        session.presentationContextProvider = self
        session.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}
