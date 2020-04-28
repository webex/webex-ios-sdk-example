// Copyright 2016-2017 Cisco Systems Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import WebexSDK


/// VideoAudioSetting store the user configuration in demo app

/// globalVideoSetting is for saving video/audio settings
/// - note: this configuration just saved in memory.
let globalVideoSetting : VideoAudioSetting = VideoAudioSetting()

class VideoAudioSetting {

    /// saparkSDK reperesent for the WebexSDK API instance
    var webexSDK: Webex?
    /// Switch of Video/Audio call or Audio call.Default is Video/Audio call
    fileprivate var videoEnabled = true
    /// Ture is sending Video stream to remote,false is not.Default is true
    fileprivate var selfViewShowed = true
    var isSelfViewShow: Bool{
        get {
            return self.selfViewShowed
        }
        set(newValue) {
            self.selfViewShowed = newValue
        }
    }
    /// Switch Front camera or Back camera.Defalut is front.
    var facingMode:Phone.FacingMode {
        get {
           return self.webexSDK?.phone.defaultFacingMode ?? .user
        }
        set(newValue) {
            self.webexSDK?.phone.defaultFacingMode = newValue
        }
    }
    
    /// True as using loud speaker, False as not. The default is using loud speaker.
    var isLoudSpeaker:Bool {
        get {
            return self.webexSDK?.phone.defaultLoudSpeaker ?? true
        }
        set(newValue){
            self.webexSDK?.phone.defaultLoudSpeaker = newValue
        }
    }
    //TODO: @Kyle
    var txBandWidth: UInt32{
        get {
            return self.webexSDK?.phone.videoMaxTxBandwidth ?? Phone.DefaultBandwidth.maxBandwidth360p.rawValue
        }
        set(newValue){
            self.webexSDK?.phone.videoMaxTxBandwidth = newValue
        }
    }
    
    var rxBandWidth: UInt32{
        get {
            return self.webexSDK?.phone.videoMaxRxBandwidth ?? Phone.DefaultBandwidth.maxBandwidth360p.rawValue
        }
        set(newValue){
            self.webexSDK?.phone.videoMaxRxBandwidth = newValue
        }
    }
    
    /// True as making a Video call,Flase as making Voice only call.The default is Video call.
    func setVideoEnabled(_ enable: Bool) {
        videoEnabled = enable
    }
    
    func isVideoEnabled() -> Bool {
        return videoEnabled
    }
}
