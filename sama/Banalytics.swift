//
//  Banalytics.swift
//  sama
//
//  Created by Viktoras Laukevičius on 7/6/21.
//

import Foundation
import FirebaseAnalytics

struct Banalytics {
    func track(event: String, parameters: [String: Any] = [:]) {
        #if DEBUG
        print("[Sama BI] \(event)")
        #endif

        Analytics.logEvent(event, parameters: parameters)
    }
}
