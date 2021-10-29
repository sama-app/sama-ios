//
//  GoogleConnectionScreen.swift
//  sama
//
//  Created by Viktoras Laukevičius on 10/28/21.
//

import UIKit
import AuthenticationServices

struct GoogleLinkAccountRequest: ApiRequest {
    typealias T = EmptyBody
    typealias U = AuthDirections
    let uri = "/integration/google/link-account"
    let logKey = "/integration/google/link-account"
    let method = HttpMethod.post
}

class GoogleConnectionScreen: UIViewController, ASWebAuthenticationPresentationContextProviding {

    var api: Api!
    var onReload: (() -> Void)?

    private var topBar: UIView!

    private var isPerformingAction = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        isModalInPresentation = false

        addNavigationBar()

        let title = UILabel().forAutoLayout()
        title.text = "Connect Google Calendar"
        title.makeMultiline()
        title.font = .brandedFont(ofSize: 28, weight: .semibold)
        title.textColor = .neutral1
        view.addSubview(title)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            view.trailingAnchor.constraint(equalTo: title.trailingAnchor, constant: 40),
            title.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 16)
        ])

        let permissionsInfo = UILabel().forAutoLayout()
        permissionsInfo.text = "Make sure you check these additional checkboxes."
        permissionsInfo.textColor = .neutral1
        permissionsInfo.font = .brandedFont(ofSize: 28, weight: .regular)
        permissionsInfo.makeMultiline()
        view.addSubview(permissionsInfo)
        NSLayoutConstraint.activate([
            permissionsInfo.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            view.trailingAnchor.constraint(equalTo: permissionsInfo.trailingAnchor, constant: 40),
            permissionsInfo.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 64)
        ])

        let permissionsImageView = UIImageView.build()
        permissionsImageView.image = UIImage(named: "google-permissions")
        view.addSubview(permissionsImageView)
        NSLayoutConstraint.activate([
            permissionsImageView.topAnchor.constraint(equalTo: permissionsInfo.bottomAnchor, constant: 24),
            permissionsImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28)
        ])

        let actionBtn = SignInGoogleButton(frame: .zero)
        actionBtn.addTarget(self, action: #selector(onConnectGoogle), for: .touchUpInside)
        view.addSubview(actionBtn)
        NSLayoutConstraint.activate([
            actionBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            actionBtn.topAnchor.constraint(equalTo: permissionsImageView.bottomAnchor, constant: 45)
        ])
    }

    private func addNavigationBar() {
        topBar = UIView().forAutoLayout()
        view.addSubview(topBar)
        topBar.pinLeadingAndTrailing(top: 0, and: [topBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44)])

        let backBtn = UIButton(type: .system)
        backBtn.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.setImage(UIImage(named: "arrow-back")!, for: .normal)
        backBtn.setTitle("Back", for: .normal)
        backBtn.titleLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
        backBtn.titleEdgeInsets.left = 8
        backBtn.titleEdgeInsets.right = -8
        backBtn.contentEdgeInsets.right = 8
        backBtn.tintColor = .primary
        backBtn.tintAdjustmentMode = .normal

        view.addSubview(backBtn)

        NSLayoutConstraint.activate([
            backBtn.heightAnchor.constraint(equalToConstant: 44),
            backBtn.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 8),
            backBtn.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])
    }

    @objc private func onBack() {
        guard !isPerformingAction else { return }
        navigationController?.popViewController(animated: true)
    }

    @objc private func onConnectGoogle() {
        guard !isPerformingAction else { return }
        isPerformingAction = true

        api.request(for: GoogleLinkAccountRequest()) {
            switch $0 {
            case let .success(directions):
                self.authenticate(with: directions.authorizationUrl)
            case let .failure(err):
                self.isPerformingAction = false
            }
        }
    }

    private func authenticate(with url: String) {
        let session = ASWebAuthenticationSession(url: URL(string: url)!, callbackURLScheme: Sama.env.productId) { (callbackUrl, err) in
            if callbackUrl?.absoluteString.contains("link-account/success") == true {
                self.onReload?()
                let vcs = self.navigationController!.viewControllers
                self.navigationController?.setViewControllers(vcs.dropLast(2), animated: true)
            }
            self.isPerformingAction = false
        }
        session.presentationContextProvider = self
        session.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}
