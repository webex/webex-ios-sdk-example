import WebexSDK

// enum to represent the UCLoginServerConnectionStatus
public enum UCLoginServerConnectionStatusKS {
    /// Connection is in idle state
    case Idle
    /// In connecting state
    case Connecting
    /// In connected state
    case Connected
    /// In disconnected state
    case Disconnected
    /// Connection failed
    case Failed
    init(status: UCLoginServerConnectionStatus) {
        switch status {
        case .Idle:
            self = .Idle
        case .Connecting:
            self = .Connecting
        case .Disconnected:
            self = .Disconnected
        case .Failed:
            self = .Failed
        case .Connected:
            self = .Connected
        @unknown default:
            self = .Idle
        }
    }
}