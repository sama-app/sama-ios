//
//  OnboardingViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit
import AuthenticationServices
import FirebaseCrashlytics
import SafariServices

struct GoogleAuthRequest: ApiRequest {
    typealias T = EmptyBody
    typealias U = AuthDirections
    let uri = "/auth/google-authorize"
    let logKey = "/auth/google-authorize"
    let method = HttpMethod.post
}

struct MarketingPreferencesUpdateData: Encodable {
    let newsletterSubscriptionEnabled: Bool
}

struct MarketingPreferencesUpdateRequest: ApiRequest {
    typealias U = EmptyBody
    let uri = "/user/me/update-marketing-preferences"
    let logKey = "/user/me/update-marketing-preferences"
    let method: HttpMethod = .post
    let body: MarketingPreferencesUpdateData
}

class OnboardingViewController: UIViewController, ASWebAuthenticationPresentationContextProviding, UITextViewDelegate {

    private let illustration = UIImageView(image: UIImage(named: "main-illustration")!)

    private var currentBlock: UIView?
    private var currentBlockLeadingConstraint: NSLayoutConstraint?
    private var emailNotificationConsentBtns: [UIButton] = []

    private let api = Sama.makeUnauthApi()

    private var capturedToken: AuthToken?

    private var didClickConnectCal = false
    private var didClickNotUsingGCal = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        illustration.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(illustration)
        NSLayoutConstraint.activate([
            illustration.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 34),
            illustration.constraintLeadingToParent(inset: -16)
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

    @objc private func presentSingleCalendarBlock() {
        let block = UIView()
        block.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(block)

        let titleLabel = UILabel.onboardingTitle("Before I can help you, I need you to grant me access to your Google Calendar.")
        titleLabel.addAndPinTitle(to: block)

        let infoLabel = UILabel.build()
        infoLabel.font = .systemFont(ofSize: 15, weight: .regular)
        infoLabel.textColor = .secondary
        infoLabel.text = "Currently I can only work with one Google account."
        infoLabel.makeMultiline()
        block.addSubview(infoLabel)
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16)
        ] + infoLabel.constraintHorizontally())

        let termsLabel = UITextView.build()
        termsLabel.textContainer.lineFragmentPadding = 0
        termsLabel.linkTextAttributes = [.foregroundColor: UIColor.primary]
        termsLabel.attributedText = termsAndPrivacyText()
        termsLabel.isSelectable = true
        termsLabel.isEditable = false
        termsLabel.isScrollEnabled = false
        termsLabel.backgroundColor = .clear
        termsLabel.delegate = self
        block.addSubview(termsLabel)
        NSLayoutConstraint.activate([
            termsLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 8)
        ] + termsLabel.constraintHorizontally())

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
            permissionsImageView.constraintLeadingToParent(inset: -12)
        ])

        let actionBtn = SignInGoogleButton(frame: .zero)
        actionBtn.addTarget(self, action: #selector(onConnectCalendar), for: .touchUpInside)
        block.addSubview(actionBtn)

        let notUsingGCalBtn = UIButton.onboardingNextButton("I don’t use Google Calendar.")
        notUsingGCalBtn.titleLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
        notUsingGCalBtn.addTarget(self, action: #selector(onNotUsingGCalCase), for: .touchUpInside)
        notUsingGCalBtn.addAndPinActionButton(to: block)

        NSLayoutConstraint.activate([
            actionBtn.constraintLeadingToParent(inset: 0),
            notUsingGCalBtn.topAnchor.constraint(equalTo: actionBtn.bottomAnchor, constant: 16)
        ])

        slideInBlock(block)
    }

    @objc private func presentEmailNotificationConsent() {
        let block = UIView.build()

        view.addSubview(block)

        let titleLabel = UILabel.onboardingTitle("I can let you know about latest releases and tips by email.")
        titleLabel.addAndPinTitle(to: block)

        let acceptBtn = UIButton.onboardingNextButton("Yes, let me know!")
        acceptBtn.addTarget(self, action: #selector(acceptEmailNotification), for: .touchUpInside)
        block.addSubview(acceptBtn)

        let denyBtn = UIButton.onboardingNextButton("No thanks.")
        denyBtn.addTarget(self, action: #selector(denyEmailNotification), for: .touchUpInside)
        denyBtn.addAndPinActionButton(to: block)

        emailNotificationConsentBtns = [acceptBtn, denyBtn]

        NSLayoutConstraint.activate([
            acceptBtn.constraintLeadingToParent(inset: 0),
            denyBtn.topAnchor.constraint(equalTo: acceptBtn.bottomAnchor, constant: 32)
        ])

        slideInBlock(block)
    }

    @objc private func acceptEmailNotification() {
        startCalendarSession(isEmailNotificationsEnabled: true)
    }

    @objc private func denyEmailNotification() {
        startCalendarSession(isEmailNotificationsEnabled: false)
    }

    private func startCalendarSession(isEmailNotificationsEnabled: Bool) {
        guard let token = capturedToken else { return }

        let auth = AuthContainer.makeAndStore(with: token)
        let session = makeCalendarSession(with: auth)

        let req = MarketingPreferencesUpdateRequest(
            body: MarketingPreferencesUpdateData(newsletterSubscriptionEnabled: isEmailNotificationsEnabled)
        )

        emailNotificationConsentBtns.forEach { $0.isEnabled = false }
        session.api.request(for: req) {
            switch $0 {
            case .success:
                let viewController = CalendarViewController()
                viewController.session = session
                UIApplication.shared.rootWindow?.rootViewController = viewController
            case let .failure(err):
                self.emailNotificationConsentBtns.forEach { $0.isEnabled = true }
                self.presentError(err)
            }
        }
    }

    private func slideInBlock(_ block: UIView) {
        let leading = block.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: view.bounds.width)
        NSLayoutConstraint.activate([
            block.topAnchor.constraint(equalTo: illustration.bottomAnchor, constant: 56),
            block.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            leading,
            block.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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

    @objc private func onNotUsingGCalCase() {
        didClickNotUsingGCal = true

        if !didClickConnectCal {
            Sama.bi.track(event: "notusinggcal")
        } else {
            Sama.bi.track(event: "notusinggcal-after-connectcal")
        }

        let alert = UIAlertController(
            title: "Sorry, other email services will be coming soon!",
            message: "Follow us to get product updates.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Follow on Twitter", style: .default, handler: { _ in
            UIApplication.shared.open(URL(string: "https://twitter.com/meetsama_")!, options: [:], completionHandler: nil)
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @objc private func onConnectCalendar() {
        didClickConnectCal = true

        if !didClickNotUsingGCal {
            Sama.bi.track(event: "connectcal")
        } else {
            Sama.bi.track(event: "connectcal-after-notusinggcal")
        }

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

                DispatchQueue.main.async {
                    self.capturedToken = token
                    self.presentEmailNotificationConsent()
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

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch URL.absoluteString {
        case "terms":
            openBrowser(with: Sama.env.termsUrl)
        case "privacy":
            openBrowser(with: Sama.env.privacyUrl)
        default:
            break
        }
        return false
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

    private func openBrowser(with url: String) {
        let controller = SFSafariViewController(url: URL(string: url)!)
        present(controller, animated: true, completion: nil)
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
        ] + constraintHorizontally())
    }

    func addAndPinActionButton(to parent: UIView) {
        parent.addSubview(self)
        NSLayoutConstraint.activate([
            parent.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 102),
            constraintLeadingToParent(inset: 0)
        ])
    }

    func constraintLeadingToParent(inset: CGFloat) -> NSLayoutConstraint {
        return Ui.isWideScreen() ?
        leadingAnchor.constraint(equalTo: superview!.centerXAnchor, constant: -147.5 + inset) :
        leadingAnchor.constraint(equalTo: superview!.leadingAnchor, constant: 40 + inset)
    }

    func constraintHorizontally() -> [NSLayoutConstraint] {
        if Ui.isWideScreen() {
            return [
                leadingAnchor.constraint(equalTo: superview!.centerXAnchor, constant: -147.5),
                widthAnchor.constraint(equalToConstant: 295)
            ]
        } else {
            return [
                leadingAnchor.constraint(equalTo: superview!.leadingAnchor, constant: 40),
                superview!.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 40)
            ]
        }
    }
}

private func termsAndPrivacyText() -> NSAttributedString {
    let text = NSMutableAttributedString()

    let defaultAttrs: (String?) -> [NSAttributedString.Key: Any] = { link in
        var attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .regular),
            .foregroundColor: UIColor.secondary
        ]
        attrs[.link] = link
        return attrs
    }

    text.append(NSAttributedString(string: "By continuing you agree to our ", attributes: defaultAttrs(nil)))
    text.append(NSAttributedString(string: "Terms of Use", attributes: defaultAttrs("terms")))
    text.append(NSAttributedString(string: " and ", attributes: defaultAttrs(nil)))
    text.append(NSAttributedString(string: "Privacy Policy", attributes: defaultAttrs("privacy")))
    text.append(NSAttributedString(string: ".", attributes: defaultAttrs(nil)))

    return text
}
