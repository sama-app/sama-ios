//
//  Banalytics.swift
//  sama
//
//  Created by Viktoras Laukevičius on 7/6/21.
//

import Foundation
#if !targetEnvironment(macCatalyst)
import FirebaseAnalytics
#endif

struct Banalytics {
    func setUserId(_ userId: String?) {
        #if DEBUG
        print("[Sama BI] UserId: \(userId)")
        #endif

        #if !targetEnvironment(macCatalyst)
        Analytics.setUserID(userId)
        #endif
    }
    func track(event: String, parameters: [String: Any] = [:]) {
        #if DEBUG
        print("[Sama BI] \(event)")
        #endif

        #if !targetEnvironment(macCatalyst)
        Analytics.logEvent(event, parameters: parameters)
        #endif
    }
}
