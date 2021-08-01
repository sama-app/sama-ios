//
//  RemoteNotificationsTokenSync.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/13/21.
//

import Foundation
import FirebaseMessaging

struct RegisterDeviceData: Encodable {
    let deviceId: String
    let firebaseRegistrationToken: String
}

class RemoteNotificationsTokenSync {

    static let shared = RemoteNotificationsTokenSync()

    var observer: ((RegisterDeviceData) -> Void)?

    private var deviceRegisterJob: DispatchWorkItem?

    private var deviceUUID: String {
        if let uuid = UserDefaults.standard.string(forKey: "SAMA_DEVICE_UUID") {
            return uuid
        } else {
            let uuid = UUID().uuidString
            UserDefaults.standard.set(uuid, forKey: "SAMA_DEVICE_UUID")
            return uuid
        }
    }

    func syncToken() {
        deviceRegisterJob?.cancel()

        let job = DispatchWorkItem {
            Messaging.messaging().token { token, _ in
                if let token = token {
                    self.observer?(RegisterDeviceData(deviceId: self.deviceUUID, firebaseRegistrationToken: token))
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: job)
        deviceRegisterJob = job
    }
}
