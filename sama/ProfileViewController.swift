//
//  ProfileViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit
import SafariServices

enum AppSettingsItem {
    case meetingPrefs
    case feedback
    case support
    case privacy
    case terms
    case acknowledgements
    case logout

    var text: String {
        switch self {
        case .meetingPrefs: return "Meeting Preferences"
        case .feedback: return "Give us feedback"
        case .support: return "Support"
        case .privacy: return "Privacy"
        case .terms: return "Terms"
        case .acknowledgements: return "Acknowledgements"
        case .logout: return "Logout"
        }
    }
}

enum AccountItem {
    case connection(Int)
    case addNew
}

enum ProfileItem {
    case account(AccountItem)
    case appSettings(AppSettingsItem)
}

struct ProfileSection {
    let title: String?
    let items: [ProfileItem]
}

struct LinkedAccount: Decodable {
    let id: String
    let email: String
}

struct ProfileAccount {
    let linked: LinkedAccount
    let calendarsCount: Int
}

struct IntegrationsResult: Decodable {
    let linkedAccounts: [LinkedAccount]
}

struct IntegrationsRequest: ApiRequest {
    typealias T = EmptyBody
    typealias U = IntegrationsResult
    let uri = "/integration/google"
    let logKey = "/integration/google"
    let method: HttpMethod = .get
}

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let illustration = UIImageView(image: UIImage(named: "main-illustration")!)
    private var accounts: [ProfileAccount] = []
    private var sections: [ProfileSection] = []

    private let tableView = UITableView()

    private let api: Api
    private let onAccountChange: () -> Void
    private var emailCoordinator: EmailComposeCoordinator!

    init(api: Api, onAccountChange: @escaping () -> Void) {
        self.api = api
        self.onAccountChange = onAccountChange
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        emailCoordinator = EmailComposeCoordinator(presenter: self)

        setupTableView()
        setupNavigationBar()

        freshReload()
    }

    private func freshReload() {
        let constSections = [
            ProfileSection(title: "Settings", items: [.appSettings(.meetingPrefs)]),
            ProfileSection(title: nil, items: [.appSettings(.feedback), .appSettings(.support)]),
            ProfileSection(title: nil, items: [.appSettings(.privacy), .appSettings(.terms), .appSettings(.acknowledgements)]),
            ProfileSection(title: nil, items: [.appSettings(.logout)])
        ]
        sections = constSections

        let group = DispatchGroup()

        var calendars: [CalendarMetadata] = []
        var accounts: [LinkedAccount] = []
        var error: ApiError? = nil

        group.enter()
        api.request(for: CalendarsRequest()) {
            switch $0 {
            case let .success(result):
                calendars = result.calendars
            case let .failure(err):
                error = err
            }
            group.leave()
        }

        group.enter()
        api.request(for: IntegrationsRequest()) {
            switch $0 {
            case let .success(result):
                accounts = result.linkedAccounts
            case let .failure(err):
                error = err
            }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            if error != nil {

            } else {
                let entries = accounts.map { acc in
                    ProfileAccount(
                        linked: acc,
                        calendarsCount: calendars.filter { $0.accountId == acc.id && $0.selected }.count
                    )
                }
                self?.accounts = entries
                let section = ProfileSection(
                    title: "Connected Accounts",
                    items: entries.enumerated().map { index, _ in
                        .account(.connection(index))
                    } + [.account(.addNew)]
                )
                self?.sections = [section] + constSections
                self?.tableView.reloadData()
            }
        }

        tableView.reloadData()
    }

    private func notifyAboutAccountsChangeAndReload() {
        onAccountChange()
        freshReload()
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
        tableView.backgroundColor = .base
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "add-new-cell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "item-cell")

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
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection index: Int) -> UIView? {
        guard let sectionTitle = sections[index].title?.uppercased() else {
            return UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 16))
        }

        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 64))
        let label = UILabel().forAutoLayout()
        label.textColor = .secondary
        label.font = .brandedFont(ofSize: 14, weight: .semibold)
        label.attributedText = NSAttributedString(string: sectionTitle, attributes: [.kern: 1.5])
        header.addSubview(label)
        NSLayoutConstraint.activate([
            header.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 40)
        ])
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection index: Int) -> CGFloat {
        guard sections[index].title?.uppercased() != nil else {
            return 16
        }
        return 64
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section].items[indexPath.row] {
        case let .appSettings(item):
            return configureAppSettingsCell(tableView.dequeueReusableCell(withIdentifier: "item-cell", for: indexPath), item: item)
        case let .account(item):
            switch item {
            case let .connection(index):
                var cell = tableView.dequeueReusableCell(withIdentifier: "account-cell")
                if cell == nil {
                    cell = UITableViewCell(style: .subtitle, reuseIdentifier: "account-cell")
                }
                return configureAccountItemCell(cell!, index: index)
            case .addNew:
                return configureAccountAddNewCell(tableView.dequeueReusableCell(withIdentifier: "add-new-cell", for: indexPath))
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch sections[indexPath.section].items[indexPath.row] {
        case let .appSettings(item):
            handleSelection(of: item)
        case let .account(item):
            switch item {
            case let .connection(index):
                let screen = ConnectedGoogleAccountScreen()
                screen.api = api
                screen.account = accounts[index].linked
                screen.onReload = { [weak self] in self?.notifyAboutAccountsChangeAndReload() }
                navigationController?.pushViewController(screen, animated: true)
            case .addNew:
                let screen = AccountConnectionScreen()
                screen.api = api
                screen.onReload = { [weak self] in self?.notifyAboutAccountsChangeAndReload() }
                navigationController?.pushViewController(screen, animated: true)
            }
        }
    }

    private func configureAppSettingsCell(_ cell: UITableViewCell, item: AppSettingsItem) -> UITableViewCell {
        cell.textLabel?.text = item.text
        cell.textLabel?.textColor = .secondary
        cell.textLabel?.font = .brandedFont(
            ofSize: 24,
            weight: item == .meetingPrefs ? .semibold : .regular
        )
        cell.layoutMargins = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }

    private func configureAccountItemCell(_ cell: UITableViewCell, index: Int) -> UITableViewCell {
        let entry = accounts[index]
        cell.textLabel?.text = entry.linked.email
        cell.textLabel?.textColor = .secondary
        cell.textLabel?.font = .brandedFont(ofSize: 24, weight: .semibold)
        if entry.calendarsCount == 1 {
            cell.detailTextLabel?.text = "\(entry.calendarsCount) calendar selected"
        } else {
            cell.detailTextLabel?.text = "\(entry.calendarsCount) calendars selected"
        }
        cell.detailTextLabel?.textColor = .secondary
        cell.detailTextLabel?.font = .systemFont(ofSize: 15)
        cell.layoutMargins = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }

    private func configureAccountAddNewCell(_ cell: UITableViewCell) -> UITableViewCell {
        cell.textLabel?.text = "Connect New Account"
        cell.textLabel?.textColor = .primary
        cell.imageView?.image = UIImage(named: "plus")
        cell.imageView?.tintColor = .primary
        cell.textLabel?.font = .brandedFont(ofSize: 24, weight: .semibold)
        cell.layoutMargins = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.contentView.alpha = 0.35
    }

    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.contentView.alpha = 1
    }

    private func handleSelection(of item: AppSettingsItem) {
        switch item {
        case .meetingPrefs:
            let screen = MeetingPreferencesScreen()
            screen.api = api
            navigationController?.pushViewController(screen, animated: true)
        case .feedback:
            Sama.bi.track(event: "feedback")
            openBrowser(with: "https://sama.nolt.io")
        case .support:
            Sama.bi.track(event: "help")
            emailCoordinator.compose(with: EmailProperties(toEmail: "help@meetsama.com", subject: "Sama app issue"))
        case .logout:
            Sama.bi.track(event: "logout")
            Sama.bi.setUserId(nil)
            AuthContainer.clear()
            UIApplication.shared.rootWindow?.rootViewController = OnboardingViewController()
        case .privacy:
            Sama.bi.track(event: "privacy")
            openBrowser(with: Sama.env.privacyUrl)
        case .terms:
            Sama.bi.track(event: "terms")
            openBrowser(with: Sama.env.termsUrl)
        case .acknowledgements:
            Sama.bi.track(event: "acknowledgements")
            let controller = AcknowledgementsViewController()
            present(controller, animated: true, completion: nil)
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
