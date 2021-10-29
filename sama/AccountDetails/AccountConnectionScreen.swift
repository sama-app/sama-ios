//
//  AccountConnectionScreen.swift
//  sama
//
//  Created by Viktoras Laukevičius on 10/28/21.
//

import UIKit

class AccountConnectionScreen: UIViewController {

    var api: Api!
    var onReload: (() -> Void)?

    private var topBar: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        isModalInPresentation = true

        addNavigationBar()

        let title = UILabel().forAutoLayout()
        title.text = "Connect a New Account"
        title.makeMultiline()
        title.font = .brandedFont(ofSize: 28, weight: .semibold)
        title.textColor = .neutral1
        view.addSubview(title)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            view.trailingAnchor.constraint(equalTo: title.trailingAnchor, constant: 40),
            title.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 16)
        ])

        let googleBtn = UIButton(type: .system)
        googleBtn.addTarget(self, action: #selector(onConnectGoogle), for: .touchUpInside)
        googleBtn.translatesAutoresizingMaskIntoConstraints = false
        googleBtn.setImage(UIImage(named: "google-logo")!.withRenderingMode(.alwaysOriginal), for: .normal)
        googleBtn.setTitle("Google Calendar", for: .normal)
        googleBtn.titleLabel?.font = .brandedFont(ofSize: 24, weight: .semibold)
        googleBtn.titleEdgeInsets.left = 16
        googleBtn.titleEdgeInsets.right = -16
        googleBtn.contentEdgeInsets.right = 16
        googleBtn.tintColor = .primary
        googleBtn.tintAdjustmentMode = .normal
        view.addSubview(googleBtn)
        NSLayoutConstraint.activate([
            googleBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            googleBtn.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 62)
        ])

        let disclosure = UILabel().forAutoLayout()
        disclosure.text = "More calendar services will be supported in the future."
        disclosure.makeMultiline()
        disclosure.font = .systemFont(ofSize: 15, weight: .regular)
        disclosure.textColor = .secondary
        view.addSubview(disclosure)
        NSLayoutConstraint.activate([
            disclosure.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            view.trailingAnchor.constraint(equalTo: disclosure.trailingAnchor, constant: 40),
            disclosure.topAnchor.constraint(equalTo: googleBtn.bottomAnchor, constant: 22)
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
        navigationController?.popViewController(animated: true)
    }

    @objc private func onConnectGoogle() {
        let screen = GoogleConnectionScreen()
        screen.api = api
        screen.onReload = onReload
        navigationController?.pushViewController(screen, animated: true)
    }
}
