import Foundation

class Constants {

    public static let fedRampKey = "isFedRAMP"
    public static let loginTypeKey = "loginType"
    public static let emailKey = "userEmail"
    public static let selfId = "selfId"
    public static let crashAutoUploadEnabledKey = "crashAutoUploadEnabled"

    public enum loginTypeValue: String {
        case email = "auth"
        case jwt = "jwt"
        case token = "token"
    }

}
