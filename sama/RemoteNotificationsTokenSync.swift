//
//  RemoteNotificationsTokenSync.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/13/21.
//

import Foundation
import FirebaseMessaging

struct RegisterDeviceReqBody: Encodable {
    let deviceId: String
    let firebaseRegistrationToken: String
}

class RemoteNotificationsTokenSync {

    static let shared = RemoteNotificationsTokenSync()

    private var deviceUUID: String? {
        if let uuid = UserDefaults.standard.string(forKey: "SAMA_DEVICE_UUID") {
            return uuid
        } else {
            let uuid = UUID().uuidString
            UserDefaults.standard.set(uuid, forKey: "SAMA_DEVICE_UUID")
            return uuid
        }
    }

    func syncToken() {
        guard
            let uuid = deviceUUID,
            let data = UserDefaults.standard.data(forKey: "SAMA_AUTH_TOKEN"),
            let authToken = try? JSONDecoder().decode(AuthToken.self, from: data)
        else { return }
        Messaging.messaging().token { token, error in
            guard
                let token = token,
                let body = try? JSONEncoder().encode(RegisterDeviceReqBody(deviceId: uuid, firebaseRegistrationToken: token))
            else { return }

            var req = URLRequest(url: URL(string: "https://app.yoursama.com/api/auth/user/register-device")!)
            req.httpMethod = "post"
            req.httpBody = body
            req.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            URLSession.shared.dataTask(with: req) { (data, resp, err) in
                print("HTTP status code: \((resp as? HTTPURLResponse)?.statusCode ?? -1)")
            }.resume()
        }
    }
}
