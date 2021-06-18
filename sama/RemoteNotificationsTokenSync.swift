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
    }
}
