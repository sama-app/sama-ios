//
//  AuthContainer.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/24/21.
//

import Foundation

class AuthContainer {

    static func makeFromStorage() -> AuthContainer? {
        guard
            let tokenData = UserDefaults.standard.data(forKey: storageKey),
            let token = try? JSONDecoder().decode(AuthToken.self, from: tokenData)
        else {
            return nil
        }
        return AuthContainer(token: token)
    }

    static func makeAndStore(with token: AuthToken) -> AuthContainer {
        store(token: token)
        return AuthContainer(token: token)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private static func store(token: AuthToken) {
        UserDefaults.standard.set(try? JSONEncoder().encode(token), forKey: storageKey)
    }

    private static let storageKey = "SAMA_AUTH_TOKEN"

    private(set) var token: AuthToken

    private init(token: AuthToken) {
        self.token = token
    }

    func update(token: AuthToken) {
        AuthContainer.store(token: token)
        self.token = token
    }
}
