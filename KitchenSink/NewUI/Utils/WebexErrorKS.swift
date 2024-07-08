import WebexSDK
// enum to represent the error types.
public enum WebexErrorKS: Error {
    /// A service request to Cisco Webex cloud has failed.
    case serviceFailed(code: Int = -7000, reason: String)
    /// The `Phone` has not been registered.
    case unregistered
    /// The media requires H.264 codec. Since the user decline the H.264 licesnse.
    case requireH264
    /// The call was interrupted because the user jumped to view the content of the H.264 licesnse.
    /// - since 2.6.0
    case interruptedByViewingH264License
    /// The DTMF is invalid.
    case invalidDTMF
    /// The DTMF is unsupported.
    case unsupportedDTMF
    /// The service request is illegal.
    case illegalOperation(reason: String)
    /// The service is in an illegal status.
    case illegalStatus(reason: String)
    /// The authentication is failed.
    /// - since 1.4.0
    case noAuth
    /// The host pin or meeting password is required while dialling.
    /// - since 2.6.0
    case requireHostPinOrMeetingPassword(reason: String)
    /// The failure reason for the API
    /// - since 3.0.0
    case failed(reason: String)
    /// The host pin or meeting password is invalid.
    /// - since 3.7.0
    case invalidPassword(reason: String)
    /// The captcha is required.
    /// - since 3.7.0
    case captchaRequired(captcha: Phone.Captcha)
    /// The captcha entered is invalid.
    /// - since 3.8.0
    case invalidPasswordOrHostKeyWithCaptcha(captcha: Phone.Captcha)
    /// Companion mode not supported in the API
    /// - since 3.12.0
    case companionModeNotSupported
    
    // write a function to take WebexSDK.WebexError and return WebexError
    static func convertToWebexError(error: WebexSDK.WebexError) -> WebexErrorKS {
        switch error {
        case .serviceFailed(let code, let reason):
            return .serviceFailed(code: code, reason: reason)
        case .unregistered:
            return .unregistered
        case .requireH264:
            return .requireH264
        case .interruptedByViewingH264License:
            return .interruptedByViewingH264License
        case .invalidDTMF:
            return .invalidDTMF
        case .unsupportedDTMF:
            return .unsupportedDTMF
        case .illegalOperation(let reason):
            return .illegalOperation(reason: reason)
        case .illegalStatus(let reason):
            return .illegalStatus(reason: reason)
        case .noAuth:
            return .noAuth
        case .requireHostPinOrMeetingPassword(let reason):
            return .requireHostPinOrMeetingPassword(reason: reason)
        case .failed(let reason):
            return .failed(reason: reason)
        case .invalidPassword(reason: let reason):
            return .invalidPassword(reason: reason)
        case .captchaRequired(let captcha):
            return .captchaRequired(captcha: captcha)
        case .invalidPasswordOrHostKeyWithCaptcha(let captcha):
            return .invalidPasswordOrHostKeyWithCaptcha(captcha: captcha)
        case .companionModeNotSupported:
            return .companionModeNotSupported
        }
    }
}
