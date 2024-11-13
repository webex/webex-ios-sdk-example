import WebexSDK
import Foundation

@available(iOS 16.0, *)
protocol PhoneProtocol: AnyObject
{
    var videoStreamMode: VideoStreamModeKS { get set }
    var enableBackgroundConnection: Bool { get set }
    var audioMaxRxBandwidth: UInt32 { get set }
    var sharingMaxRxBandwidth: UInt32 { get set }
    var videoMaxRxBandwidth: UInt32 { get set }
    var videoMaxTxBandwidth: UInt32 { get set }
    var defaultFacingMode: FacingModeKS { get set }
    var isSpeechEnhancementEnabled: Bool {get}

    func setPushTokens(bundleId: String, deviceId: String, deviceToken: String, voipToken: String, appId: String?)
    func dial(joinAddress: String, isPhoneNumber: Bool, isMoveMeeting: Bool, isModerator: Bool, pin: String?, captchaId: String, captchaVerifyCode: String, selfVideoView: MediaRenderViewKS, remoteVideoViewRepresentable: RemoteVideoViewRepresentable, screenShareView: MediaRenderViewKS, completionHandler: @escaping (Swift.Result<CallProtocol, Error>) -> Void)
    
    func isWebexOrCucmCalling() -> Bool
    func startPreview(videoView: MediaRenderView)
    func updateVirtualBackgrounds(completionHandler: @escaping (_ result: [Phone.VirtualBackground]) -> Void)
    func addVirtualBackground(image: LocalFile, completionHandler: @escaping (_ result: Result<Phone.VirtualBackground>) -> Void)
    func applyVirtualBackground(background: Phone.VirtualBackground, isPreview: Bool, completionHandler: @escaping (_ result: Result<Bool>) -> Void)
    func deleteItem(item: Phone.VirtualBackground, completionHandler: @escaping (_ result: Result<Bool>) -> Void)
    func stopPreview()
    func refreshMeetingCaptcha(completionHandler: @escaping (Result<Phone.Captcha>) -> Void)
    func updateSystemPreferredCamera(camera: Camera, completionHandler: @escaping (Result<Void>) -> Void)
    func getListOfCameras() -> [Camera]
    func useLegacyReceiverNoiseRemoval(useLegacy: Bool)
    func enableSpeechEnhancement(shouldEnable: Bool, completionHandler: @escaping (Result<Void>) -> Void)
}

@available(iOS 16.0, *)
class WebexPhone: PhoneProtocol {
    
    public var defaultFacingMode: FacingModeKS {
        get {
            if  webex.phone.defaultFacingMode == .user
            {
                return .user
            } else {
                return .environment
            }
        }
        set {
            if newValue == .user
            {
                webex.phone.defaultFacingMode = .user
            }
            else
            {
                webex.phone.defaultFacingMode = .environment
            }
        }
    }
    
     var videoStreamMode: VideoStreamModeKS {
        get {
            if  webex.phone.videoStreamMode == .auxiliary
            {
                return .auxiliary
            } else {
                return .composited
            }
        }
        set {
            if newValue == .auxiliary
            {
                webex.phone.videoStreamMode = .auxiliary
            }
            else
            {
                webex.phone.videoStreamMode = .composited
            }
        }
    }
    
    public var audioMaxRxBandwidth: UInt32 {
        get {
            return  webex.phone.audioMaxRxBandwidth
        }
        set {
            webex.phone.audioMaxRxBandwidth =  newValue
        }
    }
    
    public var sharingMaxRxBandwidth: UInt32 {
        get {
            return  webex.phone.sharingMaxRxBandwidth
        }
        set {
            webex.phone.sharingMaxRxBandwidth =  newValue
        }
    }
    
    public var videoMaxRxBandwidth: UInt32 {
        get {
            return  webex.phone.videoMaxRxBandwidth
        }
        set {
            webex.phone.videoMaxRxBandwidth =  newValue
        }
    }
    
    public var videoMaxTxBandwidth: UInt32 {
        get {
            return  webex.phone.videoMaxTxBandwidth
        }
        set {
            webex.phone.videoMaxTxBandwidth =  newValue
        }
    }
    
    var enableBackgroundConnection: Bool {
        get {
            return  webex.phone.enableBackgroundConnection
        }
        set {
            webex.phone.enableBackgroundConnection =  newValue
        }
    }

    var isSpeechEnhancementEnabled: Bool {
        return webex.phone.isReceiverSpeechEnhancementEnabled
    }

    // Sets the push tokens for WxC calling push notifications
    func setPushTokens(bundleId: String, deviceId: String, deviceToken: String, voipToken: String, appId: String? = nil) {
        webex.phone.setPushTokens(bundleId: bundleId, deviceId: deviceId, deviceToken: deviceToken, voipToken: voipToken, appId: nil)
    }
    
    fileprivate func handleDialResult(_ result: Result<Call>, completionHandler: @escaping (Swift.Result<CallProtocol, Error>) -> Void) {
        switch result {
        case .success(let call):
            completionHandler(.success(CallKS(call: call)))
        case .failure(let error):
            completionHandler(.failure(error))
        @unknown default:
            print("default case of dialPhoneNumber")
        }
    }
    
    func dial(joinAddress: String, isPhoneNumber: Bool = false, isMoveMeeting: Bool = false, isModerator: Bool = false, pin: String? = "", captchaId: String = "", captchaVerifyCode: String = "", selfVideoView: MediaRenderViewKS, remoteVideoViewRepresentable: RemoteVideoViewRepresentable, screenShareView: MediaRenderViewKS, completionHandler: @escaping (Swift.Result<CallProtocol, Error>) -> Void) {
        let mediaOption = getMediaOption(isModerator: isModerator, isMoveMeeting: isMoveMeeting, pin: pin, captchaId: captchaId, captchaVerifyCode: captchaVerifyCode, selfVideoView: selfVideoView, remoteVideoViewRepresentable: remoteVideoViewRepresentable, screenShareView: screenShareView)
        if isPhoneNumber
        {
            webex.phone.videoStreamMode = .auxiliary
            webex.phone.dialPhoneNumber(joinAddress, option: mediaOption) { result in
                self.handleDialResult(result, completionHandler: completionHandler)
            }
        }
        else{
            webex.phone.videoStreamMode = .auxiliary
            webex.phone.dial(joinAddress, option: mediaOption){ result in
                self.handleDialResult(result, completionHandler: completionHandler)
           }
        }
    }
    
    func getMediaOption(isModerator: Bool = false, isMoveMeeting: Bool, pin: String? = "", captchaId: String = "", captchaVerifyCode: String = "", selfVideoView:  MediaRenderViewKS?, remoteVideoViewRepresentable: RemoteVideoViewRepresentable?, screenShareView: MediaRenderViewKS?) -> MediaOption {
        let companionMode = isMoveMeeting ? CompanionMode.MoveMeeting : CompanionMode.None
        var mediaOption = MediaOption.audioOnly(companionMode: companionMode)
        let hasVideo = UserDefaults.standard.bool(forKey: "hasVideo")
        if hasVideo {
            mediaOption = MediaOption.audioVideoScreenShare(video: (local: selfVideoView?.renderView, remote: remoteVideoViewRepresentable?.remoteVideoView.mediaRenderView), screenShare: screenShareView?.renderView, companionMode: companionMode)
        }
        mediaOption.moderator = isModerator
        mediaOption.pin = pin
        mediaOption.captchaId = captchaId
        mediaOption.captchaVerifyCode = captchaVerifyCode
        return mediaOption
    }
    
    func isWebexOrCucmCalling() -> Bool
    {
        return webex.phone.getCallingType() == .WebexCalling || webex.phone.getCallingType() == .WebexForBroadworks
    }
    
    func startPreview(videoView: MediaRenderView) {
        webex.phone.startPreview(view: videoView)
    }
    
    func updateVirtualBackgrounds(completionHandler: @escaping (_ result: [Phone.VirtualBackground]) -> Void) {
        webex.phone.fetchVirtualBackgrounds(completionHandler: { result in
            switch result {
            case .success(let backgrounds):
                print("Inside  fetchVirtualBackgrounds: \(backgrounds[0].type) ,\(backgrounds[1].type)")
                   completionHandler(backgrounds)
            case .failure(let error):
                   print("Error: \(error)")
            @unknown default:
                print("Error")
            }
        })
    }
    
    func addVirtualBackground(image: LocalFile, completionHandler: @escaping (_ result: Result<Phone.VirtualBackground>) -> Void) {
        webex.phone.addVirtualBackground(image: image, completionHandler: completionHandler)
    }
    
    func applyVirtualBackground(background: Phone.VirtualBackground, isPreview: Bool, completionHandler: @escaping (_ result: Result<Bool>) -> Void) {
        webex.phone.applyVirtualBackground(background: background, mode: isPreview ? .preview : .call, completionHandler: completionHandler)
    }

    func deleteItem(item: Phone.VirtualBackground, completionHandler: @escaping (_ result: Result<Bool>) -> Void) {
        webex.phone.removeVirtualBackground(background: item , completionHandler: completionHandler)
    }
    
    func stopPreview() {
        webex.phone.stopPreview()
    }
    
    func refreshMeetingCaptcha(completionHandler: @escaping (Result<Phone.Captcha>) -> Void) {
        webex.phone.refreshMeetingCaptcha(completionHandler: completionHandler)
    }

    func updateSystemPreferredCamera(camera: Camera, completionHandler: @escaping (Result<Void>) -> Void) {
        webex.phone.updateSystemPreferredCamera(camera: camera, completionHandler: completionHandler)
    }

    func getListOfCameras() -> [Camera] {
        return webex.phone.getListOfCameras()
    }

    func useLegacyReceiverNoiseRemoval(useLegacy: Bool) {
        webex.phone.useLegacyReceiverNoiseRemoval(useLegacy: useLegacy)
    }

    func enableSpeechEnhancement(shouldEnable: Bool, completionHandler: @escaping (Result<Void>) -> Void) {
        webex.phone.enableReceiverSpeechEnhancement(shouldEnable: shouldEnable, completionHandler: completionHandler)
    }
}


extension Phone.VirtualBackground: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    public static func == (lhs: Phone.VirtualBackground, rhs: Phone.VirtualBackground) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Phone.VirtualBackgroundType {
    var displayText: String {
        switch self {
        case .none:
            return "None"
        case .blur:
            return "Blur"
        case .custom:
            return "Custom"
        @unknown default:
            return "None"
        }
    }
    
}

public enum VideoStreamModeKS {
    /// composite remote videos as one video stream
    case composited
    /// remote videos are different streams
    case auxiliary
}


public enum DefaultBandwidthKS: UInt32 {
    /// 177Kbps for 160x90 resolution
    case maxBandwidth90p = 177000
    /// 384Kbps for 320x180 resolution
    case maxBandwidth180p = 384000
    /// 768Kbps for 640x360 resolution
    case maxBandwidth360p = 768000
    /// 2.5Mbps for 1280x720 resolution
    case maxBandwidth720p = 2500000
    /// 4Mbps for 1920x1080 resolution
    case maxBandwidth1080p = 4000000
    /// 8Mbps data session
    case maxBandwidthSession = 8000000
    /// 64kbps for voice
    case maxBandwidthAudio = 64000
}

public enum FacingModeKS {
    /// Front camera.
    case user
    /// Back camera.
    case environment
}
