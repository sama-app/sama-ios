//
//  AuthResultHandler.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/1/21.
//

import Foundation

struct AuthResultHandler {
    func handle(callbackUrl: URL?, error: Error?) throws -> AuthToken {
        if let err = error {
            throw err
        }

        guard
            let url = callbackUrl,
            url.scheme == Sama.env.productId,
            url.host == "auth"
        else {
            throw AppAuthError(.unrecognizedScheme)
        }

        switch url.path {
        case "/success":
            guard
                let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                let accessToken = queryItems.first(where: { $0.name == "accessToken" })?.value,
                let refreshToken = queryItems.first(where: { $0.name == "refreshToken" })?.value
            else {
                throw AppAuthError(.invalidSuccessParams)
            }

            return AuthToken(accessToken: accessToken, refreshToken: refreshToken)
        case "/error":
            guard
                let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                let reason = queryItems.first(where: { $0.name == "reason" })?.value
            else {
                throw AppAuthError(.invalidErrorParams)
            }
            switch reason {
            case "google_insufficient_permissions":
                throw AppAuthError(.insufficientPermissions)
            default:
                throw AppAuthError(.unrecognizedErrorReason)
            }
        default:
            throw AppAuthError(.unrecognizedPath)
        }
    }
}
