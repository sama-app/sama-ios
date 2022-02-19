//
//  AppDelegate.swift
//  sama
//
//  Created by Viktoras Laukevičius on 5/4/21.
//

import UIKit
import Firebase
import FirebaseCrashlytics
#if !targetEnvironment(macCatalyst)
import FirebaseDynamicLinks
#endif
import CoreSpotlight

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
            return true
        }

        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()

        FirebaseApp.configure()
        #if DEBUG
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #endif
        #if DEBUG && !targetEnvironment(macCatalyst)
        Analytics.setAnalyticsCollectionEnabled(false)
        #endif
        Messaging.messaging().delegate = self

        if #available(iOS 14.0, *) {
            let attrs = CSSearchableItemAttributeSet(contentType: .application)
            attrs.title = "Sama"
            attrs.contentDescription = "AI calendar scheduling assistant"
            attrs.keywords = ["calendar", "scheduling", "assistant", "AI"]
            let item = CSSearchableItem(
                uniqueIdentifier: "root-app",
                domainIdentifier: "com.meetsama.sama",
                attributeSet: attrs
            )
            CSSearchableIndex.default().indexSearchableItems([item], completionHandler: nil)
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        #if !targetEnvironment(macCatalyst)
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url)?.url {
            Sama.bi.track(event: "meetinginviteddl")
            MeetingInviteDeepLinkService.shared.handleUniversalLink(dynamicLink)
        }
        #endif
        return false
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: APNs Notification Center PNs

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // present notification if app is in foreground
        completionHandler([.sound, .alert])
    }

    // MARK: APNs PNs handling

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")

        // With swizzling disabled you must set the APNs token here.
        // Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: Firebase messaging

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken ?? "N/A")")

        RemoteNotificationsTokenSync.shared.syncToken()
//        let dataDict:[String: String] = ["token": fcmToken ?? ""]
//        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}

private let gcmMessageIDKey = "gcm.message_id"
