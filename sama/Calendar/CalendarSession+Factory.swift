//
//  CalendarSession+Factory.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/4/21.
//

import UIKit

func makeCalendarSession(with auth: AuthContainer) -> CalendarSession {
    let api = Sama.makeApi(with: auth)
    var isHandledForbidden = false
    api.forbiddenHandler = {
        if !isHandledForbidden {
            isHandledForbidden = true
            UIApplication.shared.windows[0].rootViewController = OnboardingViewController()
        }
    }
    let session = CalendarSession(api: api, currentDayIndex: 5000)
    session.setupNotificationsTokenObserver()
    return session
}
