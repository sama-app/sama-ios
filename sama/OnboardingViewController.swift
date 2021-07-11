//
//  OnboardingViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit
import AuthenticationServices
import FirebaseCrashlytics

struct GoogleAuthRequest: ApiRequest {
    typealias T = EmptyBody
    typealias U = AuthDirections
    let uri = "/auth/google-authorize"
    let logKey = "/auth/google-authorize"
    let method = HttpMethod.post
}

class OnboardingViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {

    private let illustration = UIImageView(image: UIImage(named: "main-illustration")!)

    private var currentBlock: UIView?
    private var currentBlockLeadingConstraint: NSLayoutConstraint?

    private let api = Sama.makeUnauthApi()

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Sama.bi.track(event: "onboarding")
    }

    private func presentWelcomeBlock() {
        let block = UIView()
        block.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(block)

        let text = UILabel()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.text = "Hi.\nI’m Sama.\nI will help you find the best time for a meeting."
        text.textColor = .neutral3
        text.font = .brandedFont(ofSize: 28, weight: .regular)
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
        actionBtn.titleLabel?.font = .brandedFont(ofSize: 28, weight: .semibold)
        actionBtn.addTarget(self, action: #selector(onNextBlock), for: .touchUpInside)
        block.addSubview(actionBtn)
        NSLayoutConstraint.activate([
            block.bottomAnchor.constraint(equalTo: actionBtn.bottomAnchor, constant: 102),
            actionBtn.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: 40)
        ])

        let leading = block.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: view.bounds.width)
        NSLayoutConstraint.activate([
            block.topAnchor.constraint(equalTo: illustration.bottomAnchor, constant: 56),
            block.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            leading,
            block.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        view.setNeedsLayout()
        view.layoutIfNeeded()

        currentBlock = block
        currentBlockLeadingConstraint = leading
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        currentBlockLeadingConstraint?.constant = 0
        UIView.animate(withDuration: 0.3, animations: {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        })
    }

    private func startSession(with auth: AuthContainer) {
        let api = Sama.makeApi(with: auth)

        let viewController = CalendarViewController()
        viewController.session = CalendarSession(api: api, currentDayIndex: 5000)
        UIApplication.shared.windows[0].rootViewController = viewController
    }

    @objc private func onNextBlock() {
        Sama.bi.track(event: "next")

        let block = UIView()
        block.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(block)

        let text = UILabel()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.text = "Before I can help you, I need you to grant me access to your Google Calendar."
        text.textColor = .neutral3
        text.font = .brandedFont(ofSize: 28, weight: .regular)
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
        actionBtn.titleLabel?.font = .brandedFont(ofSize: 28, weight: .semibold)
        actionBtn.addTarget(self, action: #selector(onConnectCalendar), for: .touchUpInside)
        block.addSubview(actionBtn)
        NSLayoutConstraint.activate([
            block.bottomAnchor.constraint(equalTo: actionBtn.bottomAnchor, constant: 102),
            actionBtn.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: 40)
        ])

        let leading = block.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: view.bounds.width)
        NSLayoutConstraint.activate([
            block.topAnchor.constraint(equalTo: illustration.bottomAnchor, constant: 56),
            block.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            leading,
            block.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        view.setNeedsLayout()
        view.layoutIfNeeded()

        leading.constant = 0

        let prevBlock = currentBlock
        currentBlockLeadingConstraint?.constant = -view.bounds.width
        UIView.animate(withDuration: 0.3, animations: {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }, completion: { _ in prevBlock?.removeFromSuperview() })

        currentBlock = block
    }

    @objc private func onConnectCalendar() {
        Sama.bi.track(event: "connectcal")

        api.request(for: GoogleAuthRequest()) {
            switch $0 {
            case let .success(directions):
                self.authenticate(with: directions.authorizationUrl)
            case .failure:
                self.presentError()
            }
        }
    }

    private func authenticate(with url: String) {
        let session = ASWebAuthenticationSession(url: URL(string: url)!, callbackURLScheme: Sama.env.productId) { (callbackUrl, err) in
            guard
                let url = callbackUrl,
                url.scheme == Sama.env.productId,
                url.host == "auth",
                url.path == "/success",
                let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                let accessToken = queryItems.first(where: { $0.name == "accessToken" })?.value,
                let refreshToken = queryItems.first(where: { $0.name == "refreshToken" })?.value
            else {
                let errOut = err ?? NSError(domain: "com.meetsama.app.auth", code: 1000, userInfo: [:])
                Crashlytics.crashlytics().record(error: errOut)
                if let authErr = errOut as? ASWebAuthenticationSessionError, authErr.code == .canceledLogin {
                    // cancelled
                } else {
                    self.presentError()
                }
                return
            }

            let token = AuthToken(accessToken: accessToken, refreshToken: refreshToken)
            let auth = AuthContainer.makeAndStore(with: token)
            RemoteNotificationsTokenSync.shared.syncToken()

            self.startSession(with: auth)
        }
        session.presentationContextProvider = self
        session.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }

    private func presentError() {
        let alert = UIAlertController(title: nil, message: "Unexpected error occurred", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
