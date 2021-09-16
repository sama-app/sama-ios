//
//  UIApplication+Helpers.swift
//  sama
//
//  Created by Viktoras Laukevičius on 9/8/21.
//

import UIKit

extension UIApplication {
    var rootWindow: UIWindow? {
        windows.filter { $0.isMember(of: UIWindow.self) }.last
    }
}
