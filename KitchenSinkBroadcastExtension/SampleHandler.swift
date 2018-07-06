//
//  SampleHandler.swift
//  KitchenSinkBroadcastExtension
//
//  Created by panzh on 19/03/2018.
//  Copyright © 2018 Cisco Systems, Inc. All rights reserved.
//

import ReplayKit
import WebexBroadcastExtensionKit
import UserNotifications
class SampleHandler: RPBroadcastSampleHandler {

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        
        WebexBroadcastExtension.sharedInstance.start(applicationGroupIdentifier: "group.com.cisco.sparkSDK.demo") {
            error in
            if let webexError = error {
                switch webexError {
                case .illegalStatus(let reason):
                    self.finishBroadcastWithError(NSError.init(domain: "ScreenShare", code: -1, userInfo: [NSLocalizedFailureReasonErrorKey:reason]))
                default:
                    break
                }
            } else {
                WebexBroadcastExtension.sharedInstance.onError = {
                    error in
                    print("=====Client onError :\(error)====")
                }
                
                WebexBroadcastExtension.sharedInstance.onStateChange = {
                    state in
                    print("=====Client onStateChange :\(state.rawValue)====")
                    if state == .Stopped {
                        self.finishBroadcastWithError(NSError.init(domain: "ScreenShare", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"stop screen boradcasting."]))
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
                break
            case RPSampleBufferType.audioApp:
                // Handle audio sample buffer for app audio
                break
            case RPSampleBufferType.audioMic:
                // Handle audio sample buffer for mic audio
                break
        }
    }
    
}
