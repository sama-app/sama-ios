//
//  EmailComposeCoordinator.swift
//  sama
//
//  Created by Viktoras Laukevičius on 7/6/21.
//

import UIKit
import MessageUI

struct EmailProperties {
    let toEmail: String
    let subject: String
}

struct EmailClient {
    let title: String
    let url: String

    static func gmail(props: EmailProperties) -> EmailClient {
        return EmailClient(
            title: "Gmail",
            url: "googlegmail://co?to=\(props.toEmail)&subject=\(props.subject)"
        )
    }

    static func outlook(props: EmailProperties) -> EmailClient {
        return EmailClient(
            title: "Outlook",
            url: "ms-outlook://compose?to=\(props.toEmail)&subject=\(props.subject)"
        )
    }
}

class EmailComposeCoordinator: NSObject, MFMailComposeViewControllerDelegate {

    private weak var presenter: UIViewController?

    init(presenter: UIViewController) {
        self.presenter = presenter
    }

    func compose(with props: EmailProperties) {
        let clients: [EmailClient] = [
            .gmail(props: props),
            .outlook(props: props)
        ]

        let defaultAction = defaultMailAction(with: props)
        let thirdPartyActions = clients.map { self.openAction(forClient: $0) }
        let actions: [UIAlertAction] = ([defaultAction] + thirdPartyActions).compactMap { $0 }

        if actions.count > 0 {
            let alert = UIAlertController(title: nil, message: "Choose email", preferredStyle: .actionSheet)
            actions.forEach { alert.addAction($0) }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            presenter?.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "No available emails clients found", message: "Please email to \(props.toEmail)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
            presenter?.present(alert, animated: true, completion: nil)
        }
    }

    private func defaultMailAction(with props: EmailProperties) -> UIAlertAction? {
        guard MFMailComposeViewController.canSendMail() else { return nil }

        return UIAlertAction(title: "Mail", style: .default) { [weak self] _ in
            let mailComposerVC = MFMailComposeViewController()
            mailComposerVC.mailComposeDelegate = self
            mailComposerVC.setToRecipients([props.toEmail])
            mailComposerVC.setSubject(props.subject)
            self?.presenter?.present(mailComposerVC, animated: true, completion: nil)
        }
    }

    private func openAction(forClient client: EmailClient) -> UIAlertAction? {
        let safeUrl = client.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: safeUrl), UIApplication.shared.canOpenURL(url) else {
             return nil
        }
        let action = UIAlertAction(title: client.title, style: .default) { _ in
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        return action
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
