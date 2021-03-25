import Foundation
import WebexSDK

protocol ShareSessionProtocol: AnyObject {
    var onShareEnded: ((ScreenShareError?) -> Void)? { get set }
    
    func start() throws
    func onFrame(_ data: Data)
}

class ShareSession: ShareSessionProtocol {
    private struct Constants {
        static let resendLastFrame: TimeInterval = 3
    }
    
    private enum State {
        case idle
        case starting
        case started(String)
        case ended
        
        var isEnded: Bool {
            guard case .ended = self else { return false }
            return true
        }
    }
    
    var onShareEnded: ((ScreenShareError?) -> Void)?
    
    private let shareSessionLifecycle: InCallShareSessionLifecycle
    private let sourceId = UUID().uuidString
    
    // Screen width.
    public var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }

    // Screen height.
    public var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    public var screenScale = UIScreen.main.scale
    
    private var externalInputWidth: Int { return Int(screenWidth * screenScale) }
    private var externalInputHeight: Int { return  Int(screenHeight * screenScale) }
    
    private var state = State.idle {
        didSet {
            print("old: \(oldValue), new: \(state)")
            guard case .ended = state else { return }
        }
    }
    
    private var lastFrame: Data?
    private var frameTimer: Timer?
    
    init(shareSessionLifecycle: InCallShareSessionLifecycle) {
        self.shareSessionLifecycle = shareSessionLifecycle
    }
    
    func start() throws {
        do {
            state = .starting
            self.shareSessionLifecycle.setShareSessionObject(shareSession: self)
            webex.phone.setupExternalInput(callId: activeCallId ?? "", height: externalInputHeight, width: externalInputWidth)
            try shareSessionLifecycle.start()
        } catch {
            state = .ended
            throw error
        }
    }
    
    func onFrame(_ data: Data) {
        guard !state.isEnded else { return print("ignoring frame while in state .ended") }
        let frameMessage = (data as NSData).bytes.bindMemory(to: FrameMessage.self, capacity: 1)
        guard frameMessage.pointee.error == .none else {
            print("extension reported error \(frameMessage.pointee.error). ending wireless share.")
            shareSessionLifecycle.stop()
            shareEnded(frameMessage.pointee.error)
            return
        }
        
        if case .started(let callId) = state {
        let message = frameMessage.pointee
        guard message.length > MemoryLayout<FrameMessage>.size else { return print("missing video data. ignoring frame.") }
        
            webex.phone.sendFrameToExternalInputter(callId: callId, timeStamp: Int(message.timestamp), height: Int(message.height), width: Int(message.width), data: UnsafeMutableRawPointer(mutating: frameMessage) + MemoryLayout<FrameMessage>.size, length: Int(message.length))
        print("sent frame")
        scheduleTimer(data)
        }
    }

    func shareStarted(_ callId: String) {
        if case .starting = state {
        print("share started. setting up external input with width \(externalInputWidth) and height \(externalInputHeight).")
        state = .started(callId)
        }
    }
    
    func shareEnded(_ error: ScreenShareError) {
        print("share ended with error \(error) while in state \(state).")
        state = .ended
        cancelTimer()
        onShareEnded?(error)
    }
    
    private func scheduleTimer(_ frame: Data) {
        print("scheduling timer")
        lastFrame = Data(bytes: (frame as NSData).bytes, count: frame.count)
        frameTimer?.invalidate()
        frameTimer = Timer(timeInterval: Constants.resendLastFrame, target: self, selector: #selector(resendLastFrame), userInfo: nil, repeats: false)
    }
    
    private func cancelTimer() {
        frameTimer?.invalidate()
        frameTimer = nil
    }
    
    // room systems expect a frame every 5 seconds. if it doesn't get a frame within 5 seconds, then it stops
    // presenting.  10 seconds and it ends the wireless share.  the broadcast extension won't send a frame if the
    // screen has not changed.  thus if we don't see a frame for a few seconds we will resend the last frame we sent
    // to keep the wireless share alive.
    @objc private func resendLastFrame() {
        guard let frame = lastFrame else { return }
        print("resending last received frame as no new frame has been received within the last \(Constants.resendLastFrame) seconds.")
        onFrame(frame)
    }
}

extension ScreenShareError {
    var description: String {
        switch self {
        case .none: return "none"
        case .fatal: return "fatal"
        case .noActiveCall: return "noActiveCall"
        case .noAuxiliaryDevice: return "noAuxiliaryDevice"
        case .openSocketFail: return "openSocketFail"
        case .auxiliaryDeviceBusy: return "auxiliaryDeviceBusy"
        case .shareReleased: return "shareReleased"
        case .disabled: return "disabled"
        @unknown default:
            print("unknown enum")
            return "unknown"
        }
    }
}
