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
        viewController.session = CalendarSession(api: Sama.makeApi(with: auth), currentDayIndex: 5000)
        UIApplication.shared.windows[0].rootViewController = viewController
    }

    private func presentOnboarding() {
        UIApplication.shared.windows[0].rootViewController = OnboardingViewController()
    }
}
