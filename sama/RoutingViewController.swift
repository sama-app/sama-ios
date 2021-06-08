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

        if
            let tokenData = UserDefaults.standard.data(forKey: "SAMA_AUTH_TOKEN"),
            let token = try? JSONDecoder().decode(AuthToken.self, from: tokenData)
        {
            startSession(with: token)
        } else {
            presentOnboarding()
        }
    }

    private func startSession(with token: AuthToken) {
        let viewController = CalendarViewController()
        viewController.session = CalendarSession(token: token, currentDayIndex: 5000)
        UIApplication.shared.windows[0].rootViewController = viewController
    }

    private func disconnectCalendar() {
        UserDefaults.standard.removeObject(forKey: "SAMA_AUTH_TOKEN")
    }

    private func presentOnboarding() {
        UIApplication.shared.windows[0].rootViewController = OnboardingViewController()
    }
}
