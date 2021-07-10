//
//  Sama.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/24/21.
//

import Foundation
import CoreGraphics

struct Environment {
    struct UI {
        let calenarHeaderHeight: CGFloat = 48
    }

    let productId = "meetsama"
//    let baseUri = "https://app.meetsama.com/api"
    let baseUri = "https://app.meetsama.com.smtest.it/api"

    let ui = UI()
}

class Sama {

    static let env = Environment()

    /// Business insights
    static let bi = Banalytics()

    private init() {}

    static func makeApi(with auth: AuthContainer) -> Api {
        return Api(
            baseUri: env.baseUri,
            defaultHeaders: [
                "Content-Type": "application/json"
            ],
            auth: auth
        )
    }

    static func makeUnauthApi() -> Api {
        return Api(baseUri: Sama.env.baseUri, defaultHeaders: [:], auth: nil)
    }
}
