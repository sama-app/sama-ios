//
//  OnboardingViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit
import AuthenticationServices

class OnboardingViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {

    private let illustration = UIImageView(image: UIImage(named: "main-illustration")!)

    private var currentBlock: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        illustration.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(illustration)
        NSLayoutConstraint.activate([
            illustration.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            illustration.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24)
        ])
        presentWelcomeBlock()
    }

    private func presentWelcomeBlock() {
        let block = UIView()
        block.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(block)

        let text = UILabel()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.text = "Hi.\nI’m Sama.\nI will help you find the best time for a meeting."
        text.textColor = .neutral3
        text.font = .systemFont(ofSize: 28)
        text.numberOfLines = 0
        text.lineBreakMode = .byWordWrapping
        block.addSubview(text)
        NSLayoutConstraint.activate([
            text.topAnchor.constraint(equalTo: block.topAnchor),
            text.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: 40),
            block.trailingAnchor.constraint(equalTo: text.trailingAnchor, constant: 40)
        ])

        let actionBtn = UIButton(type: .system)
        actionBtn.setTitle("Continue", for: .normal)
        actionBtn.translatesAutoresizingMaskIntoConstraints = false
        actionBtn.setTitleColor(.primary, for: .normal)
        actionBtn.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        actionBtn.addTarget(self, action: #selector(onNextBlock), for: .touchUpInside)
        block.addSubview(actionBtn)
        NSLayoutConstraint.activate([
            block.bottomAnchor.constraint(equalTo: actionBtn.bottomAnchor, constant: 102),
            actionBtn.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: 40)
        ])

        NSLayoutConstraint.activate([
            block.topAnchor.constraint(equalTo: illustration.bottomAnchor, constant: 56),
            block.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: block.trailingAnchor),
            block.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        currentBlock = block
    }

    private func startSession(with token: AuthToken) {
        let viewController = CalendarViewController()
        viewController.session = CalendarSession(token: token, currentDayIndex: 5000)
        UIApplication.shared.windows[0].rootViewController = viewController
    }

    @objc private func onNextBlock() {
        currentBlock?.removeFromSuperview()

        let block = UIView()
        block.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(block)

        let text = UILabel()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.text = "Before I can help you, I need you to grant me access to your Google Calendar."
        text.textColor = .neutral3
        text.font = .systemFont(ofSize: 28)
        text.numberOfLines = 0
        text.lineBreakMode = .byWordWrapping
        block.addSubview(text)
        NSLayoutConstraint.activate([
            text.topAnchor.constraint(equalTo: block.topAnchor),
            text.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: 40),
            block.trailingAnchor.constraint(equalTo: text.trailingAnchor, constant: 40)
        ])

        let actionBtn = UIButton(type: .system)
        actionBtn.setTitle("Connect", for: .normal)
        actionBtn.translatesAutoresizingMaskIntoConstraints = false
        actionBtn.setTitleColor(.primary, for: .normal)
        actionBtn.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        actionBtn.addTarget(self, action: #selector(onConnectCalendar), for: .touchUpInside)
        block.addSubview(actionBtn)
        NSLayoutConstraint.activate([
            block.bottomAnchor.constraint(equalTo: actionBtn.bottomAnchor, constant: 102),
            actionBtn.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: 40)
        ])

        NSLayoutConstraint.activate([
            block.topAnchor.constraint(equalTo: illustration.bottomAnchor, constant: 56),
            block.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: block.trailingAnchor),
            block.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
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
