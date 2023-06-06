import ReplayKit
import WebexBroadcastExtensionKit

class SampleHandler: RPBroadcastSampleHandler {
    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        let path = Bundle.main.path(forResource: "Info", ofType: "plist")
        let keys = NSDictionary(contentsOfFile: path ?? "")
        guard let groupId = keys?["GroupIdentifier"] as? String, !groupId.isEmpty else { fatalError("WebexBroadcastExtensionKit: Expected your Broadcast Extension's Info.plist to contain a valid group identifier. Please add a key `GroupIdentifier` with the value as your App's Group Identifier to your App's Broadcast Extension.plist. This is required for ScreenSharing") }
        WebexBroadcastExtension.sharedInstance.start(applicationGroupIdentifier: groupId) { error in
            if let webexError = error {
                switch webexError {
                case .illegalStatus(let reason):
                    self.finishBroadcastWithError(NSError(domain: "ScreenShare", code: -1, userInfo: [NSLocalizedFailureReasonErrorKey: reason]))
                default:
                    break
                }
            } else {
                WebexBroadcastExtension.sharedInstance.onError = {
                    error in
                    print("=====Client onError :\(error)====")
                }
                
                if UserDefaults(suiteName: groupId)?.bool(forKey: "optimizeForVideo") == true {
                    WebexBroadcastExtension.sharedInstance.optimizeForVideo()
                }
                
                WebexBroadcastExtension.sharedInstance.onStateChange = {
                    state in
                    print("=====Client onStateChange :\(state.rawValue)====")
                    if state == .Stopped {
                        self.finishBroadcastWithError(NSError(domain: "ScreenShare", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: "Screen share is stopped."]))
                    } else if state == .Suspended {
                        self.finishBroadcastWithError(NSError(domain: "ScreenShare", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: "Someone else is sharing in the meeting."]))
                    }
                }
            }
        }
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        WebexBroadcastExtension.sharedInstance.finish()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Handle video sample buffer
            WebexBroadcastExtension.sharedInstance.handleVideoSampleBuffer(sampleBuffer: sampleBuffer)
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            WebexBroadcastExtension.sharedInstance.handleAudioSampleBuffer(sampleBuffer: sampleBuffer)
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            break
        }
    }
}
