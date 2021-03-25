import WebexSDK

enum ShareSessionError: Error {
    case activeShare, noAuxiliaryDevice, auxiliaryDeviceBusy
    
    var value: ScreenShareError {
        switch self {
        case .noAuxiliaryDevice: return .noAuxiliaryDevice
        case .auxiliaryDeviceBusy: return .auxiliaryDeviceBusy
        case .activeShare: return .shareReleased
        }
    }
}

class InCallShareSessionLifecycle {
    var call: Call?
    private enum State {
        case idle, starting, started(Bool), stopped
    }
    private let callId: String
    
    private var state: State = .idle {
        didSet {
            print("old: \(oldValue), new: \(state)")
            guard case .stopped = state else { return }
        }
    }
    
    private var shareSession: ShareSession?

    init(callId: String) {
        self.callId = callId
    }
    
    func start() throws {
        state = .starting
        call?.startSharing(completionHandler: { error in
            if error == nil {
                print("Started Sharing")
            } else {
                print(error ?? "Error starting screen share")
            }
        })
    }
    
    func stop() {
        state = .stopped
        call?.stopSharing(completionHandler: { error in
            if error == nil {
                print("Stopped Sharing")
            } else {
                print(error ?? "Error stopping screen share")
            }
        })
    }

    private func shareEnded(_ error: ScreenShareError) {
        state = .stopped
    }
    
    func setShareSessionObject(shareSession: ShareSession) {
        self.shareSession = shareSession
    }
    
    func onSharingStateChanged(call: Call) {
        self.call = call
        if call.sendingScreenShare {
            state = .started(true)
            shareSession?.shareStarted(callId)
        } else {
            shareEnded(.none)
            shareSession?.shareEnded(.none)
        }
    }
}
