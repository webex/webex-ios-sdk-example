import CoreMedia
import CoreVideo
import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {
    private struct Constants {
        static let maximumCurrentWaitingFrames = 5
        static let maximumSamplesPerSecond: Double = 3
    }

    private let connectionClient: LLBSDConnectionClient
    private lazy var bufferQueue = SampleBufferQueue(delegate: self, maxSamplesPerSecond: Constants.maximumSamplesPerSecond)
    private lazy var sampleHelper = SampleHelper()
    private let currentWaitingFrames = Atomic<Int>(0)
    private let isReady = Atomic<Bool>(false)
    
    override init() {
        connectionClient = LLBSDConnectionClient(applicationGroupIdentifier: "group.com.webex.sdk.KitchenSinkv3.0", connectionIdentifier: ScreenShareConnectionIdentifier)
        super.init()

        connectionClient.delegate = self
    }
    
    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        print("Start broadcast extension with setupInfo: \(String(describing: setupInfo))")
        connectionClient.start { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("Failed to open frame socket: \(error)")
                self.notifyAndFinishBroadcastWithError(.openSocketFail)
            } else {
                print("Success to open frame socket")
                self.isReady.mutate { $0 = true }
            }
        }
    }
    
    override func broadcastPaused() {
        print("Paused")
    }
    
    override func broadcastResumed() {
        print("Resumed")
    }
    
    override func broadcastFinished() {
        print("Finished")
        sampleHelper.sendError(.fatal, using: connectionClient)
        connectionClient.invalidate()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard isReady.value else { return }
        switch sampleBufferType {
        case .video:
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return print("unable to get image buffer") }
            let pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
            guard pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange || pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange else { return print("incorrect pixel format") }
            bufferQueue.push(sampleBuffer: sampleBuffer)
        default: break
        }
    }
    
    // MARK: - Private
    private func notifyAndFinishBroadcastWithError(_ error: ScreenShareError) {
        guard error != .none else { return assertionFailure("notifyAndFinishBroadcastWithError should not be called with .none") }
        finishBroadcastWithError(NSError(domain: "ScreenShare", code: Int(error.rawValue), userInfo: [NSLocalizedFailureReasonErrorKey: error.localizedMessage]))
    }
}

extension SampleHandler: LLBSDConnectionDelegate {
    func connection(_ connection: LLBSDConnection?, didReceiveMessage message: __DispatchData?, fromProcess processInfo: pid_t) {
        guard let message = message else { return }
        let error = sampleHelper.error(fromDispatchMessage: message)
        print("Received message from process \(processInfo), error code: \(error)")
        if error != .none {
            notifyAndFinishBroadcastWithError(error)
        }
    }
}

extension SampleHandler: SampleBufferQueueDelegate {
    func sampleBufferQueue(_ sampleBufferQueue: SampleBufferQueue, didPopSampleBuffer sampleBuffer: CMSampleBuffer) {
        guard currentWaitingFrames.value <= Constants.maximumCurrentWaitingFrames else { return print("dropping buffer.") }
        
        currentWaitingFrames.mutate { $0 += 1 }
        send(sampleBuffer) { [weak self] error in
            guard let self = self else { return }
            self.currentWaitingFrames.mutate { $0 -= 1 }
            
            if let error = error {
                print("Failed to send sample buffer: \(error)")
                self.notifyAndFinishBroadcastWithError(.fatal)
            }
        }
    }
}

extension SampleHandler {
    private func send(_ sampleBuffer: CMSampleBuffer, completion: @escaping (Error?) -> Void) {
        sampleHelper.send(sampleBuffer, using: connectionClient, completion: completion)
    }
}

extension ScreenShareError {
    var localizedMessage: String {
        switch self {
        case .none: return ""
        case .fatal: return NSLocalizedString("Screen share is stopped.", comment: "Screen share is stopped.")
        case .noActiveCall: return NSLocalizedString("You must be in a call or meeting to share your screen.", comment: "Screen share failure due to no call.")
        case .noAuxiliaryDevice: return NSLocalizedString("You must be in a meeting on this device or connected with Webex device to share your screen.", comment: "Screen share failure due to no paired device.")
        case .openSocketFail: return NSLocalizedString("You must open Webex to share your screen.", comment: "Screen share failure due to Webex was not launched.")
        case .auxiliaryDeviceBusy: return NSLocalizedString("Webex device is in use.", comment: "Screen share failure due to Webex device is occupied.")
        case .shareReleased: return NSLocalizedString("Someone else is sharing in the meeting.", comment: "Screen share stopped as someone else started sharing in the call or meeting.")
        case .disabled: return NSLocalizedString("Sharing is not enabled.", comment: "Screen share is not enabled.")
        @unknown default:
            print("unknown enum")
            return ""
        }
    }
}

// swiftlint:disable dispatch_usage
public final class Atomic<A> {
    private let queue = DispatchQueue(label: "com.cisco.teams.atomic.access")
    private var _value: A
    
    public init(_ value: A) {
        self._value = value
    }
    
    public var value: A {
        return queue.sync { _value }
    }
    
    public func mutate(_ transform: (inout A) -> Void) {
        queue.sync { transform(&_value) }
    }
}
// swiftlint:enable dispatch_usage
