//
//  RoutingViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit
import AuthenticationServices

class RoutingViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        if
            let tokenData = UserDefaults.standard.data(forKey: "SAMA_AUTH_TOKEN"),
            let token = try? JSONDecoder().decode(AuthToken.self, from: tokenData)
        {
            startSession(with: token)
        } else {
            connectCalendar()
        }
    }

    private func startSession(with token: AuthToken) {
        let viewController = CalendarViewController()
        viewController.session = CalendarSession(token: token, currentDayIndex: 5000)
        UIApplication.shared.windows[0].rootViewController = viewController
    }

    private func connectCalendar() {
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

    private func disconnectCalendar() {
        UserDefaults.standard.removeObject(forKey: "SAMA_AUTH_TOKEN")
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
