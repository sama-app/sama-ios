//
//  Sama.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/24/21.
//

import Foundation

class Sama {
    private init() {}

    static let baseUri = "https://app.yoursama.com/api"

    static func makeApi(with auth: AuthContainer) -> Api {
        return Api(
            baseUri: baseUri,
            defaultHeaders: [
                "Content-Type": "application/json"
            ],
            auth: auth
        )
    }
}
