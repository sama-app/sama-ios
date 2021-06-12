//
//  ProfileViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit

enum ProfileItem {
    case feedback
    case support
    case privacy
    case terms
    case delete
    case logout

    var text: String {
        switch self {
        case .feedback: return "Give us Feedback"
        case .support: return "Support"
        case .privacy: return "Privacy"
        case .terms: return "Terms"
        case .delete: return "Delete Account"
        case .logout: return "Logout"
        }
    }
}

class ProfileViewController: UITableViewController {

    private let illustration = UIImageView(image: UIImage(named: "main-illustration")!)
    private let sections: [[ProfileItem]] = [
        [.feedback, .support],
        [.privacy, .terms, .delete, .logout]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 200))

        illustration.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(illustration)
        NSLayoutConstraint.activate([
            illustration.topAnchor.constraint(equalTo: header.topAnchor, constant: 40),
            illustration.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 24)
        ])

        tableView.tableHeaderView = header
        tableView.tableFooterView = UIView()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 16 : 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = sections[indexPath.section][indexPath.row].text
        cell.textLabel?.textColor = .primary
        let fontSize: CGFloat = indexPath.section == 0 ? 28 : 24
        cell.textLabel?.font = .brandedFont(ofSize: fontSize, weight: .semibold)
        cell.layoutMargins = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40)
        cell.backgroundColor = .clear
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section][indexPath.row]
        switch item {
        case .logout:
            UserDefaults.standard.removeObject(forKey: "SAMA_AUTH_TOKEN")
            dismiss(animated: true, completion: {
                UIApplication.shared.windows[0].rootViewController = OnboardingViewController()
            })
        default:
            break
        }
    }
}
