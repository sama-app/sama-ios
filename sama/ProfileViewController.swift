//
//  ProfileViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit
import SafariServices

enum ProfileItem {
    case feedback
    case support
    case privacy
    case terms
    case logout

    var text: String {
        switch self {
        case .feedback: return "Give us Feedback"
        case .support: return "Support"
        case .privacy: return "Privacy"
        case .terms: return "Terms"
        case .logout: return "Logout"
        }
    }
}

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let illustration = UIImageView(image: UIImage(named: "main-illustration")!)
    private let sections: [[ProfileItem]] = [
        [.feedback, .support],
        [.privacy, .terms, .logout]
    ]

    private let tableView = UITableView()
    private var emailCoordinator: EmailComposeCoordinator!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        emailCoordinator = EmailComposeCoordinator(presenter: self)

        setupTableView()
        setupNavigationBar()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ])
        tableView.separatorStyle = .none
        tableView.register(HighlightableSimpleCell.self, forCellReuseIdentifier: "cell")

        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 200))

        illustration.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(illustration)
        NSLayoutConstraint.activate([
            illustration.topAnchor.constraint(equalTo: header.topAnchor, constant: 54),
            illustration.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 24)
        ])

        tableView.tableHeaderView = header
        tableView.tableFooterView = UIView()
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 16 : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = sections[indexPath.section][indexPath.row].text
        cell.textLabel?.textColor = .primary
        let fontSize: CGFloat = indexPath.section == 0 ? 28 : 24
        cell.textLabel?.font = .brandedFont(ofSize: fontSize, weight: .semibold)
        cell.layoutMargins = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40)
        cell.backgroundColor = .clear
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = sections[indexPath.section][indexPath.row]
        switch item {
        case .feedback:
            emailCoordinator.compose(with: EmailProperties(toEmail: "hello@meetsama.com", subject: "Re: Sama app feedback"))
        case .support:
            emailCoordinator.compose(with: EmailProperties(toEmail: "help@meetsama.com", subject: "Re: Sama app issue"))
        case .logout:
            AuthContainer.clear()
            dismiss(animated: true, completion: {
                UIApplication.shared.windows[0].rootViewController = OnboardingViewController()
            })
        case .privacy:
            openBrowser(with: "https://meetsama.com/privacy")
        case .terms:
            openBrowser(with: "https://meetsama.com/terms")
        }
    }

    private func openBrowser(with url: String) {
        let controller = SFSafariViewController(url: URL(string: url)!)
        present(controller, animated: true, completion: nil)
    }

    @objc private func onClose() {
        dismiss(animated: true, completion: nil)
    }
}
