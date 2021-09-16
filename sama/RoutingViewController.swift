//
//  RoutingViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit

class RoutingViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .base
        overrideUserInterfaceStyle = .light

        if let auth = AuthContainer.makeFromStorage() {
            startSession(with: auth)
        } else {
            presentOnboarding()
        }
    }

    private func startSession(with auth: AuthContainer) {
        let viewController = CalendarViewController()
        viewController.session = makeCalendarSession(with: auth)
        UIApplication.shared.rootWindow?.rootViewController = viewController
    }

    private func presentOnboarding() {
        UIApplication.shared.rootWindow?.rootViewController = OnboardingViewController()
    }
}
