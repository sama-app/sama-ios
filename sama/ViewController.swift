//
//  ViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/4/21.
//

import UIKit
import AuthenticationServices

class ViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {

    @IBOutlet private var connectButton: UIButton!
    @IBOutlet private var disconnectButton: UIButton!
    @IBOutlet private var fetchCalendarButton: UIButton!

    private var isLoggedIn = false {
        didSet {
            connectButton.isHidden = isLoggedIn
            disconnectButton.isHidden = !isLoggedIn
            fetchCalendarButton.isHidden = !isLoggedIn
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isLoggedIn = UserDefaults.standard.data(forKey: "SAMA_AUTH_TOKEN") != nil
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
