import SwiftUI
import WebexSDK
// enum to represent the UCSSOFailureReason
public enum UCSSOFailureReasonKS {
    /// SessionExpired
    case sessionExpired
    /// RefreshTokenAboutToExpire
    case refreshTokenAboutToExpire
    
    init(reason: UCSSOFailureReason) {
        switch reason {
        case .sessionExpired:
            self = .sessionExpired
        case .refreshTokenAboutToExpire:
            self = .refreshTokenAboutToExpire
        @unknown default:
            self = .sessionExpired
        }
    }
}