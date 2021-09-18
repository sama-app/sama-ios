//
//  UiUtils.swift
//  sama
//
//  Created by Viktoras Laukevičius on 9/18/21.
//

import UIKit

enum Ui {
    static func isWideScreen() -> Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom != .phone
        #endif
    }
}
