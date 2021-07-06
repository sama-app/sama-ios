//
//  Banalytics.swift
//  sama
//
//  Created by Viktoras Laukevičius on 7/6/21.
//

import Foundation
import FirebaseAnalytics

struct Banalytics {
    func track(event: String) {
        #if DEBUG
        print("[Sama BI] \(event)")
        #endif

        Analytics.logEvent(event, parameters: nil)
    }
}
