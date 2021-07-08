//
//  AcknowledgementsViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 7/8/21.
//

import UIKit

class AcknowledgementsViewController: UIViewController {

    private let contentView = UITextView()
    private let licenses = [
        LicenseEntry(name: "firebase-ios-sdk", fileName: "firebase")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        contentView.backgroundColor = .base
        contentView.isScrollEnabled = true
        contentView.contentInset = UIEdgeInsets(top: 66, left: 16, bottom: 0, right: 16)
        contentView.contentOffset = CGPoint(x: -16, y: -66)

        setupNavigationBar()

        loadContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Sama.bi.track(event: "acknowledgements")
    }

    private func setupNavigationBar() {
        let navigationBar = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        NSLayoutConstraint.activate([
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 50)
        ])

        let closeBtn = UIButton(type: .system)
        navigationBar.contentView.addSubview(closeBtn)
        closeBtn.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.tintColor = .primary
        closeBtn.setImage(UIImage(named: "cross")!, for: .normal)
        NSLayoutConstraint.activate([
            closeBtn.widthAnchor.constraint(equalToConstant: 44),
            closeBtn.heightAnchor.constraint(equalToConstant: 44),
            navigationBar.contentView.trailingAnchor.constraint(equalTo: closeBtn.trailingAnchor, constant: 12),
            closeBtn.centerYAnchor.constraint(equalTo: navigationBar.contentView.centerYAnchor)
        ])
    }

    private func loadContent() {
        DispatchQueue.global(qos: .userInitiated).async {
            let attributedText = NSMutableAttributedString()

            for entry in self.licenses {
                let title = NSAttributedString(
                    string: "\(entry.name)\n",
                    attributes: [
                        .foregroundColor: UIColor.primary,
                        .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
                    ]
                )

                let contentPath = Bundle.main.url(forResource: entry.fileName, withExtension: "")!
                let rawContent = try! String(contentsOf: contentPath, encoding: .utf8)

                let content = NSAttributedString(
                    string: rawContent,
                    attributes: [
                        .foregroundColor: UIColor.primary,
                        .font: UIFont.systemFont(ofSize: 10)
                    ]
                )

                attributedText.append(title)
                attributedText.append(content)
            }

            DispatchQueue.main.async {
                self.contentView.attributedText = attributedText
            }
        }
    }

    @objc private func onClose() {
        dismiss(animated: true, completion: nil)
    }
}

private struct LicenseEntry {
    let name: String
    let fileName: String
}
