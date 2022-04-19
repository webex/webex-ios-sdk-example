// Copyright 2016-2020 Cisco Systems Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
import PushKit
import UIKit
import UserNotifications
import WebexSDK
// swiftlint:disable implicitly_unwrapped_optional
var webex: Webex!
var token: String?
var voipToken: String?
var incomingCallData: [Meeting] = []  // have to keep this in centralised place to update it realtime

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow()
        navigateToLoginViewController()
        window?.makeKeyAndVisible()

        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) { granted, error in
            if granted {
              print("Approval granted to send notifications")
            } else {
                print(error ?? "")
            }
          }
        application.registerForRemoteNotifications()
        self.voipRegistration()
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        token = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("Device token: \(token ?? "nil")")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("App failed to register for Remote Notifications: \(error.localizedDescription)")
    }
    
    func navigateToLoginViewController() {
        window?.rootViewController = LoginViewController()
    }
    
    // Register for VoIP notifications
    func voipRegistration() {
        // Create a push registry object
        let mainQueue = DispatchQueue.main
        let voipRegistry = PKPushRegistry(queue: mainQueue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let handler = window?.rootViewController as? PushNotificationHandler else {
            print("RootViewController must confirm to a PushNotificationHandler")
            completionHandler()
            return
        }
        
        let content = response.notification.request.content
        if content.userInfo["data"] is String,
           let payload = content.userInfo as? [String: Any],
           let pushId = PushPayloadParseUtils.parseCUCMCallPayload(payload) {
            // Handle CUCM Notification payload
            handler.handleCUCMCallNotification(pushId)
        } else if let webhookContent = content.userInfo["webhookData"] as? String,
              let webhookData = webhookContent.data(using: .utf8),
              let dataDict = try? JSONSerialization.jsonObject(with: webhookData, options: []) as? [String: Any],
              let resource = dataDict["resource"] as? String {
            // Handle notification payload from Webhook
            switch resource {
            case "messages":
                guard let payloadInfo = PushPayloadParseUtils.parseMessagePayload(dataDict) else {
                    print("Push notification info parse error")
                    completionHandler()
                    return
                }
                handler.handleMessageNotification(payloadInfo.messageId, spaceId: payloadInfo.spaceId)
                
            case "callMemberships":
                guard let payloadId = PushPayloadParseUtils.parseWebexCallPayload(dataDict) else {
                    print("Push notification info parse error")
                    completionHandler()
                    return
                }
                handler.handleWebexCallNotification(payloadId)
                
            default:
                print("Unknown Notification resource type")
            }
        } else {
            // Payload parsing failed
            print("Push notification info parse error")
        }
        
        completionHandler()
    }
}

extension AppDelegate: PKPushRegistryDelegate {
    // Handle updated push credentials
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        voipToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        print("pushRegistry -> deviceToken: \(voipToken ?? "nil")")
    }
        
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("pushRegistry:didInvalidatePushTokenForType:\(type)")
    }
}
