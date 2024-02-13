import WebexSDK
import Foundation

class WebexPhone {

    // Sets the push tokens for WxC calling push notifications
    func setPushTokens(bundleId: String, deviceId: String, deviceToken: String, voipToken: String, appId: String? = nil) {
        webex.phone.setPushTokens(bundleId: bundleId, deviceId: deviceId, deviceToken: deviceToken, voipToken: voipToken, appId: nil)
    }
}
