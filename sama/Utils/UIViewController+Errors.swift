//
//  UIViewController+Errors.swift
//  sama
//
//  Created by Viktoras Laukevičius on 11/3/21.
//

import UIKit

extension UIViewController {
    func presentError(_ err: ApiError) {
        switch err {
        case let .http(httpErr):
            if (500 ..< 600).contains(httpErr.code) {
                let alert = UIAlertController(
                    title: "Sama servers cannot be reached",
                    message: "Sama servers are currently not responding. Please try again later",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(
                    title: "Unexpected error occurred",
                    message: "App received unexpected server error",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        case let .network(err):
            if err.isOffline {
                let alert = UIAlertController(
                    title: "Your internet connection appears to be offline",
                    message: "It looks like you are not connected to the internet.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(
                    title: "Unexpected error occurred",
                    message: "App received unexpected network error",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        case .parsing, .unknown:
            let alert = UIAlertController(title: nil, message: "Unexpected error occurred", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
}
