import WebexSDK

public struct CallMembershipKS {

    // The enumeration of the status of the person in the membership.
    public enum State: String {
        // The person is idle w/o any call.
        case idle
        // The person has been notified about the call.
        case notified
        // The person has joined the call.
        case joined
        // The person has left the call.
        case left
        // The person has declined the call.
        case declined
        // The person is waiting in the lobby about the call.
        case waiting
    }
    
    // The enumeration of device types
    public enum DeviceType: String {
        // The user is joined via mobile client
        case mobile
        // The user is joined via desktop client
        case desktop
        // The user is joined via room device
        case room
        // The user's device type is unknown
        case unknown
    }
    
    // True if the person is the initiator of the call.
    public private(set) var isInitiator: Bool
    
    // The identifier of the person.
    public private(set) var personId: String?

    // The status of the person in this `CallMembership`.
    public var state: State
    
    // The SIP address of the person in this `CallMembership`.
    public var sipUrl: String?
    
    // The phone number of the person in this `CallMembership`.
    public var phoneNumber: String?
    
    // True if the `CallMembership` is sending video. Otherwise, false.
    public var sendingVideo: Bool
    
    // True if the `CallMembership` is sending audio. Otherwise, false.
    public var sendingAudio: Bool
    
    // True if the `CallMembership` is sending screen share. Otherwise, false.
    public var sendingScreenShare: Bool
    
    // True if the `CallMembership` is muted by others. Otherwise, false.
    public var isAudioMutedControlled: Bool
    
    // The personId of the merbership who muted/unmuted this `CallMembership`
    public var audioModifiedBy: String?
    
    // True if this `CallMembership` is speaking in this meeting and video is prsenting on remote media render view. Otherwise, false.

    public var isActiveSpeaker: Bool
        
    // True if this `CallMembership` is self user. Otherwise, false.
    public let isSelf: Bool
    
    // The name of the person in this `CallMembership`.
    public let displayName: String?
    
    // The type of the device joined by this `CallMembership`.
    public let deviceType: DeviceType?
    
    // This will have all memberships joined using deviceType `Room`, for other types it will be empty. To control audio of call memberships under deviceType `Room`, use the Room's personId.
    public let pairedMemberships: [CallMembershipKS]
    
    // True if this member is a presenter of the call or meeting. Otherwise false.
    public let isPresenter: Bool
    
    // True if this member is a CoHost of the call or meeting. Otherwise false.
    public let isCohost: Bool
    
    // True if this member is a host of the call or meeting. Otherwise false.
    public let isHost: Bool
    
    init(callMembership: CallMembership) {
        self.isInitiator = callMembership.isInitiator
        self.personId = callMembership.personId
        switch callMembership.state {
        case CallMembership.State.idle:
            self.state = CallMembershipKS.State.idle
        case CallMembership.State.notified:
            self.state = CallMembershipKS.State.notified
        case CallMembership.State.joined:
            self.state = CallMembershipKS.State.joined
        case CallMembership.State.left:
            self.state = CallMembershipKS.State.left
        case CallMembership.State.declined:
            self.state = CallMembershipKS.State.declined
        case CallMembership.State.waiting:
            self.state = CallMembershipKS.State.waiting
        default:
            self.state = CallMembershipKS.State.idle
        }
        self.sipUrl = callMembership.sipUrl
        self.phoneNumber = callMembership.phoneNumber
        self.sendingVideo = callMembership.sendingVideo
        self.sendingAudio = callMembership.sendingAudio
        self.isAudioMutedControlled = callMembership.isAudioMutedControlled
        self.audioModifiedBy = callMembership.audioModifiedBy
        self.sendingScreenShare = callMembership.sendingScreenShare
        self.isActiveSpeaker = callMembership.isActiveSpeaker
        self.displayName = callMembership.displayName
        self.isSelf = callMembership.isSelf
        self.isPresenter = callMembership.isPresenter
        self.isCohost = callMembership.isCohost
        self.isHost = callMembership.isHost
        switch callMembership.deviceType {
        case .mobile:
            self.deviceType = .mobile
        case .desktop:
            self.deviceType = .desktop
        case .room:
            self.deviceType = .room
        case .unknown:
            self.deviceType = .unknown
        @unknown default:
            self.deviceType = .unknown
        }
        self.pairedMemberships = callMembership.pairedMemberships.map {CallMembershipKS(callMembership: $0)}
    }
}
