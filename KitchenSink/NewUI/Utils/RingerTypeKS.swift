import WebexSDK
// enum to represent the ringer type
public enum RingerTypeKS {
    case outgoing
    case incoming
    case busyTone
    case reconnect
    case notFound
    case DTMF_0
    case DTMF_1
    case DTMF_2
    case DTMF_3
    case DTMF_4
    case DTMF_5
    case DTMF_6
    case DTMF_7
    case DTMF_8
    case DTMF_9
    case DTMF_A
    case DTMF_B
    case DTMF_C
    case DTMF_D
    case DTMF_STAR
    case DTMF_POUND
    case DTMF_FLASH
    case PICKUP_ALERT
    case PICKUP_BUSY_TONE
    case CALLPARK_EXPIRE
    case callWaiting
    case undefined
    
    mutating func fromRingerType(ringerType: WebexSDK.Call.RingerType) {
        switch ringerType {
        case .outgoing:
            self = .outgoing
        case .incoming:
            self = .incoming
        case .busyTone:
            self = .busyTone
        case .reconnect:
            self = .reconnect
        case .notFound:
            self = .notFound
        case .DTMF_0:
            self = .DTMF_0
        case .DTMF_1:
            self = .DTMF_1
        case .DTMF_2:
            self = .DTMF_2
        case .DTMF_3:
            self = .DTMF_3
        case .DTMF_4:
            self = .DTMF_4
        case .DTMF_5:
            self = .DTMF_5
        case .DTMF_6:
            self = .DTMF_6
        case .DTMF_7:
            self = .DTMF_7
        case .DTMF_8:
            self = .DTMF_8
        case .DTMF_9:
            self = .DTMF_9
        case .DTMF_A:
            self = .DTMF_A
        case .DTMF_B:
            self = .DTMF_B
        case .DTMF_C:
            self = .DTMF_C
        case .DTMF_D:
            self = .DTMF_D
        case .DTMF_STAR:
            self = .DTMF_STAR
        case .DTMF_POUND:
            self = .DTMF_POUND
        case .DTMF_FLASH:
            self = .DTMF_FLASH
        case .PICKUP_ALERT:
            self = .PICKUP_ALERT
        case .PICKUP_BUSY_TONE:
            self = .PICKUP_BUSY_TONE
        case .CALLPARK_EXPIRE:
            self = .CALLPARK_EXPIRE
        case .callWaiting:
            self = .callWaiting
        case .undefined:
            self = .undefined
        @unknown default:
            self = .outgoing
        }
    }

}
