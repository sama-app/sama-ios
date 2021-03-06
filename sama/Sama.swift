//
//  Sama.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/24/21.
//

import UIKit
import CoreGraphics

struct Environment {
    struct UI {
        let calenarHeaderHeight: CGFloat = 48
        let calenarNoHeaderHeight: CGFloat = 12
        let calendarHeaderRightSeparatorTopInset: CGFloat = 8
    }

    let productId = "meetsama"
    let baseUri = SamaKeys.baseUri
    let termsUrl = "https://www.meetsama.com/terms"
    let privacyUrl = "https://www.meetsama.com/privacy"

    let ui = UI()
}

class Sama {

    static let env = Environment()

    /// Business insights
    static let bi = Banalytics()

    static var isShareMainFlow: Bool {
        #if targetEnvironment(macCatalyst)
        return false
        #else
        return true
        #endif
    }

    private init() {}

    static func makeApi(with auth: AuthContainer) -> Api {
        return Api(
            baseUri: env.baseUri,
            defaultHeaders: getDefaultHeaders(),
            auth: auth
        )
    }

    static func makeUnauthApi() -> Api {
        return Api(baseUri: Sama.env.baseUri, defaultHeaders: getDefaultHeaders(), auth: nil)
    }
}

private func getDefaultHeaders() -> [String: String] {
    #if targetEnvironment(macCatalyst)
    let systemName = "SamaMacCatalyst"
    #else
    let systemName = "SamaiOS"
    #endif
    return [
        "Content-Type": "application/json",
        "User-Agent": "\(systemName)/v\(getAppVersion()) (OS \(getOsVersion()))"
    ]
}

private func getAppVersion() -> String {
    return (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
}

private func getOsVersion() -> String {
    return UIDevice.current.systemVersion
}
