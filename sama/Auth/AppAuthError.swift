//
//  AppAuthError.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/1/21.
//

import Foundation

struct AppAuthError: Error {
    enum Code: Int {
        case unrecognizedPath = 1000
        case unrecognizedScheme = 1001
        case invalidSuccessParams = 1010
        case invalidErrorParams = 1020
        case insufficientPermissions = 1021
        case unrecognizedErrorReason = 1025
    }

    let code: Code
    var _domain: String { "com.meetsama.app.auth" }
    var _code: Int { code.rawValue }
    init(_ code: Code) {
        self.code = code
    }
}
