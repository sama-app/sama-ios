//
//  AuthToken.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/6/21.
//

import Foundation

struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String
}
