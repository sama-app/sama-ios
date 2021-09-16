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
        let block = UIView.build()
        view.addSubview(block)

        let titleLabel = UILabel.onboardingTitle("Hi.\nI’m Sama.\nI will help you find the best time for a meeting.")
        titleLabel.addAndPinTitle(to: block)

        let actionBtn = UIButton.onboardingNextButton("Continue")
        actionBtn.addTarget(self, action: #selector(presentSingleCalendarBlock), for: .touchUpInside)
        actionBtn.addAndPinActionButton(to: block)

        slideInBlock(block)
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
        let viewController = CalendarViewController()
        viewController.session = makeCalendarSession(with: auth)
        UIApplication.shared.rootWindow?.rootViewController = viewController
    }

    @objc private func presentSingleCalendarBlock() {
        let block = UIView()
        block.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(block)

        let titleLabel = UILabel.onboardingTitle("Before I can help you, I need you to grant me access to your Google Calendar.")
        titleLabel.addAndPinTitle(to: block)

        let infoLabel = UILabel.build()
        infoLabel.font = .brandedFont(ofSize: 20, weight: .regular)
        infoLabel.textColor = .secondary
        infoLabel.text = "Currently I can only work with one Google account."
        infoLabel.makeMultiline()
        block.addSubview(infoLabel)
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: 40),
            block.trailingAnchor.constraint(equalTo: infoLabel.trailingAnchor, constant: 40)
        ])

        let actionBtn = UIButton.onboardingNextButton("Continue")
        actionBtn.addTarget(self, action: #selector(presentSignInBlock), for: .touchUpInside)
        actionBtn.addAndPinActionButton(to: block)

        slideInBlock(block)
    }

    @objc private func presentSignInBlock() {
        let block = UIView.build()

        view.addSubview(block)

        let titleLabel = UILabel.onboardingTitle("Make sure you check these additional checkboxes.")
        titleLabel.addAndPinTitle(to: block)

        let permissionsImageView = UIImageView.build()
        permissionsImageView.image = UIImage(named: "google-permissions")
        block.addSubview(permissionsImageView)
        NSLayoutConstraint.activate([
            permissionsImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            permissionsImageView.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: 28)
        ])

        let actionBtn = SignInGoogleButton(frame: .zero)
        actionBtn.addTarget(self, action: #selector(onConnectCalendar), for: .touchUpInside)
        actionBtn.addAndPinActionButton(to: block)

        slideInBlock(block)
    }

    private func slideInBlock(_ block: UIView) {
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
        currentBlockLeadingConstraint = leading
    }

    @objc private func onConnectCalendar() {
        Sama.bi.track(event: "connectcal")

        api.request(for: GoogleAuthRequest()) {
            switch $0 {
            case let .success(directions):
                self.authenticate(with: directions.authorizationUrl)
            case let .failure(err):
                self.presentError(err)
            }
        }
    }

    private func authenticate(with url: String) {
        let session = ASWebAuthenticationSession(url: URL(string: url)!, callbackURLScheme: Sama.env.productId) { (callbackUrl, err) in
            do {
                let token = try AuthResultHandler().handle(callbackUrl: callbackUrl, error: err)
                let auth = AuthContainer.makeAndStore(with: token)

                DispatchQueue.main.async {
                    self.startSession(with: auth)
                }
            } catch let err {
                Crashlytics.crashlytics().record(error: err)
                if let authErr = err as? ASWebAuthenticationSessionError, authErr.code == .canceledLogin {
                    // cancelled
                } else {
                    DispatchQueue.main.async {
                        self.presentError(err)
                    }
                }
            }
        }
        session.presentationContextProvider = self
        session.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }

    private func presentError(_ error: Error) {
        if let authErr = error as? AppAuthError, authErr.code == .insufficientPermissions {
            let alert = UIAlertController(title: "Insufficient permissions", message: "Sama app required calendar read and write permissions", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: nil, message: "Unexpected error occurred", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
}

private extension UILabel {
    class func onboardingTitle(_ title: String) -> UILabel {
        let label = UILabel.build()
        label.text = title
        label.textColor = .neutral1
        label.font = .brandedFont(ofSize: 28, weight: .regular)
        label.makeMultiline()
        return label
    }
}

private extension UIButton {
    class func onboardingNextButton(_ title: String) -> UIButton {
        let actionBtn = UIButton(type: .system)
        actionBtn.forAutoLayout()
        actionBtn.setTitle(title, for: .normal)
        actionBtn.setTitleColor(.primary, for: .normal)
        actionBtn.titleLabel?.font = .brandedFont(ofSize: 28, weight: .semibold)
        return actionBtn
    }
}

private extension UIView {
    func addAndPinTitle(to parent: UIView) {
        parent.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parent.topAnchor),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 40),
            parent.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 40)
        ])
    }

    func addAndPinActionButton(to parent: UIView) {
        parent.addSubview(self)
        NSLayoutConstraint.activate([
            parent.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 102),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 40)
        ])
    }
}
