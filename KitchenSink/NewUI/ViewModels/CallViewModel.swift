import SwiftUI
import AVFoundation
import WebexSDK

@available(iOS 16.0, *)
class CallViewModel: ObservableObject
{
    @Published var participantId: String = ""
    @Published var callingLabel: String = ""
    @Published var callTitle: String = ""
    @Published var associatedCallTitle: String = ""
    @Published var secondCallTitle: String = ""
    @Published var durationLabel: String = ""
    @Published var showDurationLabel: Bool = false
    @Published var duration = 0
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var showAlert = false
    @Published var isLocalAudioMuted = true
    @Published var isLocalVideoMuted = true
    @Published var isOnHold = false
    @Published var isAudioOnly = false
    @Published var dismissCallingScreenView = false
    @Published var showMoreOptions = false
    @Published var showMultiStreamCategoryCAlert = false
    @Published var showMultiStreamOptionsAlert = false
    @Published var showMultiStreamCategoryView = false
    @Published var updateMediaStream = false
    @Published var updateRemoteViewMultiStream = false
    @Published var updateRemoteViewInfoMultiStream = false
    @Published var mediaStream: MediaStream?
    @Published var infoMediaStream: MediaStream?
    private var player: AVAudioPlayer = AVAudioPlayer()
    var playingRingerType: RingerTypeKS = .undefined

    @Published var showSlideInMessage = false
    @Published var messageText = ""
    @Published var breakout: Call.Breakout?
    @Published var sessions: [Call.BreakoutSession] = []
    @Published var breakoutJoined = false
    
    @Published var receivingVideo = false
    @Published var receivingAudio = false
    @Published var receivingScreenShare = false
    @Published var isSendingVideo = false
    @Published var isSendingAudio = false
    @Published var shouldUpdateView = false
    @Published var isFrontCamera = true
    @Published var isCUCMOrWxcCall = false
    @Published var showDialScreenFromAddCall = false
    @Published var showDialScreenFromDirectTransfer = false
    @Published var addedCall = false
    @Published var secondIncomingCall = false
    @Published var shouldShowScreenConfig = false
    @Published var showScreenShareControl = false
    @Published var isReceivingScreenShared = false
    @Published var dismissMoreOptionsView = false
    @Published var showVirtualBGViewInCall = false
    @Published var showImagePicker = false
    
    @Published var auxViews: [MediaRenderViewRepresentable] = []
    @Published var auxDict: [MediaRenderViewRepresentable: AuxStream] = [:]
    @Published var auxDictNew: [MediaRenderViewRepresentable: MediaStream] = [:]
    @Published var multiStreamQualities: MediaStreamQualityKS = .LD
    
    @Published var callParticipants: [CallMembershipKS] = []
    @Published var inMeeting: [CallMembershipKS] = []
    @Published var notInMeeting: [CallMembershipKS] = []
    @Published var inLobby: [CallMembershipKS] = []

    //Captcha
    @Published var captcha: Phone.Captcha?
    @Published var captchaViewTitle: String = ""
    @Published var captchaViewMessage: String = ""
    @Published var captchaCode: String = ""
    @Published var meetingPinOrPassword: String = ""
    @Published var hostKey: String = ""
    @Published var showCaptchaView: Bool = false
    @Published var showMeetingPasswordView: Bool = false
    @Published var captchaRefresh: Bool = false
    @Published var audioURL: URL?
    @Published var audioPlayer : AVPlayer!
    @Published var captchaImage: UIImage?
    @Published var isModerator: Bool = false
    
    @Published var showBadNetworkIcon: Bool = false
    @Published var badNetworkIconColor: Color = .green
    @Published var showNoiseRemovalButtonIcon: Bool = false
    @Published var showNoiseRemovalAlert: Bool = false
    @Published var noiseRemovalButtonImage: Image = Image("noise-none-filled")
    
    //Transcription & Captions
    @Published var transcriptionItems: [Transcription] = []
    @Published var closedCaptionsTextDisplay: String = ""
    @Published var isClosedCaptionAllowed: Bool = false
    @Published var showCaptionTextView: Bool = false
    @Published var showCaptionsList: Bool = false
    
    @Published var showClosedCaptionsView: Bool = false
    @Published var closedCaptionsToggle: Bool = false
    @Published var showTranscriptions: Bool = false
    @Published var canControlWXA: Bool = false
    @Published var isWXAEnabled: Bool = false
    
    @Published var showSpokenLanguagesList: Bool = false
    @Published var showTranslationsLanguagesList: Bool = false
    @Published var spokenLanguageButton = ""
    @Published var translationLanguageButton = ""
    @Published var canChangeSpokenLanguage: Bool = false
    @Published var isClosedCaptionEnabled: Bool = false
    @Published var languageItems: [LanguageItem] = []
    
    @Published var isSpokenItemSelected: Bool = false
    @Published var isTranslationItemSelected: Bool = false
    @Published var selectedLanguage:LanguageItem?
    @Published var selectedTranslationItem: LanguageItem?
    @Published var selectedSpokenItem: LanguageItem?
    @Published var captionItems: [CaptionItem] = []
    @Published var info: ClosedCaptionsInfo?
    
    //Video
    @Published var renderMode: Call.VideoRenderMode = .fit
    @Published var torchMode: Call.TorchMode = .off
    @Published var flashMode: Call.FlashMode = .off
    @Published var zoomFactor: Float = 1.0
    @Published var cameraTargetBias: Call.CameraExposureTargetBias?
    @Published var cameraISO: Call.CameraExposureISO?
    @Published var cameraDuration: Call.CameraExposureDuration?
    @Published var customAlertTitle = ""
    @Published var customAlertTextfield1 = ""
    @Published var customAlertTextfield2 = ""
    @Published var showCustomAlert = false
    @Published var showSelfPhoto = false
    @Published var selfPhoto: UIImage?
    @Published var externalCamera: Camera?
    @Published var isExternalCameraConnected = false
    @Published var isExternalCameraEnabled = false

    @Published var showCameraFocus = false
    @Published var showCustomExposure = false
    @Published var showAutoExposure = false
    @Published var showZoomFactor = false
    @Published var showDTMFControl = false
    @Published var placeholderText1 = ""
    @Published var placeholderText2 = ""
    @Published var speechEnhancement = false
    let renderModes: [Call.VideoRenderMode] = [.fit, .cropFill, .stretchFill]
    let flashModes: [Call.FlashMode] = [.on, .off, .auto]
    let torchModes: [Call.TorchMode] = [.on, .off, .auto]
    
    var shareConfig = ShareConfigKS(shareType: .Default, enableAudio: false)
    var timer = Timer()
    var joinAddress: String?
    var isPhoneNumber: Bool = false
    var isMoveMeeting: Bool = false
    let webexPhone: PhoneProtocol = WebexPhone()

    var currentCall: CallProtocol? //Current call object dialed or incoming call
    var secondCall: CallProtocol? //second Incoming call object
    var currentCallAssociatedCall: CallProtocol? //Associated call object of current call
    var secondCallAssociatedCall: CallProtocol? //Associated call object of second call
    let cameraDeviceManager: CameraDeviceManager? = CameraDeviceManager()

    init(joinAddress: String = "", isPhoneNumber: Bool = false, call: CallProtocol? = nil, isMoveMeeting: Bool = false) {
        self.joinAddress = joinAddress
        self.isPhoneNumber = isPhoneNumber
        self.currentCall = call
        self.isMoveMeeting = isMoveMeeting
        setupExternalCameraConnectionNotifications()
    }
    
    // Answer the incoming call.
    func answerCall(selfVideoView: MediaRenderViewKS? = nil, remoteVideoViewRepresentable: RemoteVideoViewRepresentable? = nil, screenShareView: MediaRenderViewKS? = nil) {
        guard let call = currentCall else {
            showError("Error", "Call is null")
            return
        }
        self.registerForCallStatesCallbacks(call: currentCall)
        call.answer(selfVideoView: selfVideoView, remoteVideoViewRepresentable: remoteVideoViewRepresentable, screenShareView: screenShareView, isMoveMeeting: isMoveMeeting) { [weak self] error in
            if error == nil {
                self?.updateNameLabels(connected: true)
                self?.isCUCMOrWxcCall = call.isCUCMCall || call.isWebexCallingOrWebexForBroadworks
            } else {
                self?.showError("Error", error.debugDescription)
            }
        }
    }
    
    // updates the selected/default settings of phone settings to a call.
    private func updatePhoneSettings() {
        let isComposite = UserDefaults.standard.bool(forKey: "compositeMode")
        let is1080pEnabled = UserDefaults.standard.bool(forKey: "VideoRes1080p")
        let backgroundConnection = UserDefaults.standard.bool(forKey: "backgroundConnection")
        webexPhone.videoStreamMode = isComposite ? .composited : .auxiliary
        webexPhone.enableBackgroundConnection = backgroundConnection
        webexPhone.videoMaxRxBandwidth = is1080pEnabled ? DefaultBandwidthKS.maxBandwidth1080p.rawValue : DefaultBandwidthKS.maxBandwidth720p.rawValue
        webexPhone.videoMaxTxBandwidth = is1080pEnabled ? DefaultBandwidthKS.maxBandwidth1080p.rawValue : DefaultBandwidthKS.maxBandwidth720p.rawValue
        webexPhone.sharingMaxRxBandwidth = DefaultBandwidthKS.maxBandwidthSession.rawValue
        webexPhone.audioMaxRxBandwidth = DefaultBandwidthKS.maxBandwidthAudio.rawValue
    }
    
    // Initiates the connect call.
    func connectCall(selfVideoView:  MediaRenderViewKS, remoteVideoViewRepresentable: RemoteVideoViewRepresentable, screenShareView: MediaRenderViewKS) {
        updatePhoneSettings()
        if currentCall != nil { // Incoming call
            answerCall(selfVideoView: selfVideoView, remoteVideoViewRepresentable: remoteVideoViewRepresentable, screenShareView: screenShareView)
            return
        }
        dialJoinAddress(selfVideoView: selfVideoView, remoteVideoViewRepresentable: remoteVideoViewRepresentable, screenShareView: screenShareView) // Dial joinAddress
    }
    
    // Dial JoinAddress
    func dialJoinAddress(selfVideoView: MediaRenderViewKS, remoteVideoViewRepresentable: RemoteVideoViewRepresentable, screenShareView: MediaRenderViewKS)
    {
        guard let joinAddress = joinAddress else {
            showError("Error", "Calling address is null")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.callingLabel = "Calling..."
            self?.callTitle = joinAddress
        }
        
        webexPhone.dial(joinAddress: joinAddress, isPhoneNumber: self.isPhoneNumber, isMoveMeeting: isMoveMeeting, isModerator: self.isModerator, pin: meetingPinOrPassword, captchaId: self.captcha?.id ?? "", captchaVerifyCode: self.captchaCode, selfVideoView: selfVideoView, remoteVideoViewRepresentable: remoteVideoViewRepresentable, screenShareView: screenShareView, completionHandler: { [weak self] result in
            self?.handleDialResult(result)
        })
    }
    
    // Handles the result of the dial or dialPhoneNumber action.
    func handleDialResult(_ result: Swift.Result<CallProtocol, Error>) {
        switch result {
        case .success(let call):
            self.registerForCallStatesCallbacks(call: call)
            self.webexCallStatesProcess(call: call)
            if call.isWebexCallingOrWebexForBroadworks {
                //TODO: AppDelegate.shared.callKitManager?.startCall(call: call)
            }
            self.currentCall = call
            self.updateNameLabels(connected: false)
            // TODO: handle CallObjectStorage
        case .failure(let error):
            self.showErrorAlert(error: error)
        }
    }
    
    func webexCallStatesProcess(call: CallProtocol) {
        let isMultiStreamEnabled = UserDefaults.standard.bool(forKey: "isMultiStreamEnabled")
        if isMultiStreamEnabled {
            self.registerNewMultiStreamCallBacks(call)
        }
    }
    
    func updateNameLabels(connected: Bool)
    {
        DispatchQueue.main.async { [weak self] in
            self?.callingLabel = connected ? "On Call" : "Calling..."
            self?.callTitle = self?.currentCall?.title ?? ""
            self?.associatedCallTitle = self?.currentCallAssociatedCall?.title ?? self?.secondCallAssociatedCall?.title ?? ""
            self?.secondCallTitle = self?.secondCall?.title ?? ""
        }
    }
    
    // Handles the error and shows the alert.
    func showErrorAlert(error: Error?) {
        guard let err = error as? WebexError else {
            showError("Call Failed", error.debugDescription)
            return
        }
        var title = ""
        var message = ""
        
        DispatchQueue.main.async { [weak self] in
            switch err {
            case .requireHostPinOrMeetingPassword(reason: let reason):
                title = reason
                message = "If you are the host, please enter host key. Otherwise, enter the meeting password."
                self?.captchaViewTitle = reason
                self?.captchaViewMessage = message
                self?.showMeetingPasswordView = true
                return
                
            case .invalidPassword(reason: let reason):
                title = reason
                message = "If you are the host, please enter correct host key. Otherwise, enter the correct meeting password."
                self?.captchaViewTitle = reason
                self?.captchaViewMessage = message
                self?.showMeetingPasswordView = true
                return
            case .captchaRequired(captcha: let captchaObject):
                self?.captcha = captchaObject
                title = "captcha Required"
                message = "Please enter the captcha shown in image or by playing audio"
                self?.captchaViewTitle = title
                self?.captchaViewMessage = message
                self?.showCaptchaView = true
                self?.showMeetingPasswordView = true
                return
                
            case .invalidPasswordOrHostKeyWithCaptcha(captcha: let captchaObject):
                self?.captcha = captchaObject
                title = "Invalid Password With Captcha"
                message = "Please enter the captcha shown in image or by playing audio"
                self?.captchaViewTitle = title
                self?.captchaViewMessage = message
                self?.showCaptchaView = true
                self?.showMeetingPasswordView = true
                return
            case .requireH264:
                title = "Call Failed"
                message = "\(error.debugDescription)"
            case .failed(let reason):
                title = "Call Failed"
                message = "\(reason)"
            default:
                title = "Call Failed"
                message = "\(error.debugDescription)"
            }
            self?.showError(title, message)
        }
    }
    
    func checkAndDismissCallingScreenView(callId: String? = nil) {
        if callId == secondCall?.callId {
            DispatchQueue.main.async { [weak self] in
                self?.secondIncomingCall = false
            }
            self.secondCall = nil
        }
        
        if callId == currentCall?.callId {
            if currentCallAssociatedCall != nil {
                self.currentCall = currentCallAssociatedCall
                self.currentCallAssociatedCall = nil
                self.registerForCallStatesCallbacks(call: self.currentCall)
                self.currentCall?.holdCall(putOnHold: false) // resume the remaining call
                self.updateNameLabels(connected: self.currentCall?.isConnected ?? false)
                DispatchQueue.main.async { [weak self] in
                    self?.addedCall = false
                }
                return
            } else {
                self.currentCall = nil
                DispatchQueue.main.async { [weak self] in
                    self?.secondIncomingCall = false
                }
            }
        }
        
        if callId == currentCallAssociatedCall?.callId || callId == secondCallAssociatedCall?.callId
        {
            self.currentCallAssociatedCall = nil
            self.secondCallAssociatedCall = nil
            DispatchQueue.main.async { [weak self] in
                self?.addedCall = false
            }
        } else if let secondCall = self.secondCall
        {
            self.currentCall = secondCall
            self.currentCallAssociatedCall = secondCallAssociatedCall
            self.secondCall = nil
            self.secondCallAssociatedCall = nil
        }
        
        if self.currentCall != nil {
            self.registerForCallStatesCallbacks(call: self.currentCall)
            self.currentCall?.holdCall(putOnHold: false) // resume the remaining call
            self.updateNameLabels(connected: self.currentCall?.isConnected ?? false)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.dismissCallingScreenView = true
            }
        }
    }
    
    // Registers for call state callbacks.
    func registerForCallStatesCallbacks(call: CallProtocol?) {
        guard let call = call else {return}
        call.onConnected = { [weak self] in
            call.isConnected = true
            self?.player.stop()
            self?.updateStates(call: call)
            if call.onMediaChanged != nil {
                self?.showBadNetworkIcon = true
            }
            self?.setMediaQualityInfoChangedCallback()
            call.updateAudioSession()
        }
        
        call.onInfoChanged = { [weak self] in
            DispatchQueue.main.async {
                if self?.isWXAEnabled != call.isWXAEnabled {
                    self?.isWXAEnabled = call.isWXAEnabled
                    self?.showSlideInMessage(message: "WXA \(self?.isWXAEnabled ?? false ? "enabled" : "disabled")")
                }
                
                if self?.canControlWXA != call.canControlWXA {
                    self?.canControlWXA = call.canControlWXA
                    if let _ = self?.canControlWXA {
                        self?.showSlideInMessage(message: "You can now control WXA")
                    }
                }
            }
            self?.updateStates(call: call)
        }
        // This callback is triggered when the media state of the call changes.
        call.onMediaChanged = { [weak self] mediaEvents in
            if let self = self {
                self.updateStates(call: call)
                switch mediaEvents {
                    /* Local/Remote video rendering view size has changed */
                case .localVideoViewSize, .remoteVideoViewSize, .remoteScreenShareViewSize, .localScreenShareViewSize:
                    break
                    
                    /* This might be triggered when the remote party muted or unmuted the audio. */
                case .remoteSendingAudio(let isSending):
                    print("Remote is sending Audio- \(isSending)")
                    
                    /* This might be triggered when the remote party muted or unmuted the video. */
                case .remoteSendingVideo(let isSending):
                    print("Remote is sending Video- \(isSending)")
                    DispatchQueue.main.async {
                        self.receivingVideo = isSending
                        self.updateMediaView()
                    }
                    /* This might be triggered when the local party muted or unmuted the audio. */
                case .sendingAudio(let isSending):
                    DispatchQueue.main.async {
                        self.isLocalAudioMuted = !isSending
                    }
                    
                    /* This might be triggered when the local party muted or unmuted the video. */
                case .sendingVideo(let isSending):
                    DispatchQueue.main.async {
                        self.isLocalVideoMuted = !isSending
                        self.updateMediaView()
                    }
                case .receivingAudio(let isReceiving):
                    print("Remote is receiving Audio- \(isReceiving)")
                    
                case .receivingVideo(_):
                    break
                    /* Camera FacingMode on local device has switched. */
                case .cameraSwitched:
                    print("cameraSwitched")
                    DispatchQueue.main.async {
                        self.isFrontCamera.toggle()
                    }
                    /* Whether loud speaker on local device is on or not has switched. */
                case .spearkerSwitched:
                    break
                    
                    /* Whether Screen share is blocked by local*/
                case .receivingScreenShare(let isReceiving):
                    // TODO: handle receiving screen share
                    print("receivingScreenShare- \(isReceiving)")
                    DispatchQueue.main.async {
                        self.isReceivingScreenShared = isReceiving
                    }
                    break
                    /* Whether Remote began to send Screen share */
                case .remoteSendingScreenShare(let remoteSending):
                    // TODO: handle remote sending screen share
                    print("remoteSendingScreenShare- \(remoteSending)")
                    DispatchQueue.main.async {
                        self.isReceivingScreenShared = remoteSending
                    }
                    break
                    /* Whether local began to send Screen share */
                case .sendingScreenShare( _):
                    DispatchQueue.main.async {
                        self.isReceivingScreenShared = false
                    }
                    break
                    /* This might be triggered when the remote video's speaker has changed.
                     */
                case .activeSpeakerChangedEvent(let from, let to):
                    print("Active speaker changed from \(String(describing: from)) to \(String(describing: to))")
                    
                default:
                    break
                }
            }
        }
        
        // This callback is called when call failed.
        call.onFailed = { [weak self] reason in
            print("Call Failed! \(reason)")
            self?.player.stop()
            // TODO: Handle Other call
            self?.showError("Call Failed", "\(reason)")
        }
        
        // This callback is called when call is disconnected.
        call.onDisconnected = { [weak self] reason in
            self?.player.stop()
            // We will need to report call ended to CallKit when we are disconnected from a CallKit call
            DispatchQueue.main.async {
                AppDelegate.shared.callKitManager?.reportEndCall(uuid: call.uuid)
            }
            switch reason {
            case .callEnded, .localLeft, .localDecline, .localCancel, .remoteLeft, .remoteDecline, .remoteCancel, .otherConnected, .otherDeclined:
                switch reason {
                case .localLeft:
                    print("local left")
                    // Meetings should not stop if local left and other party is still in meeting
                default:
                    break
                }
                self?.checkAndDismissCallingScreenView(callId: call.callId)
            case .error(let error):
                print(error)
            @unknown default:
                print(reason)
            }
        }

        // This callback is called when the call starts ringing.
        call.onStartRinger = { [weak self] ringerType in
            guard let self = self else { return }
            
            print("[Ringer] Playing tone for RingerType: \(ringerType)")
            
            let path: String?
            
            switch ringerType {
            case .outgoing:
                path = Bundle.main.path(forResource: "call_1_1_ringback", ofType: "wav")
            case .busyTone:
                path = Bundle.main.path(forResource: "BusyTone", ofType: "wav")
            case .incoming:
                path = Bundle.main.path(forResource: "call_1_1_ringtone", ofType: "wav")
            case .reconnect:
                path = Bundle.main.path(forResource: "Reconnect", ofType: "wav")
            case .notFound:
                path = Bundle.main.path(forResource: "FastBusy", ofType: "mp3")
            case .DTMF_0:
                path = Bundle.main.path(forResource: "dtmf-0", ofType: "caf")
            case .DTMF_1:
                path = Bundle.main.path(forResource: "dtmf-1", ofType: "caf")
            case .DTMF_2:
                path = Bundle.main.path(forResource: "dtmf-2", ofType: "caf")
            case .DTMF_3:
                path = Bundle.main.path(forResource: "dtmf-3", ofType: "caf")
            case .DTMF_4:
                path = Bundle.main.path(forResource: "dtmf-4", ofType: "caf")
            case .DTMF_5:
                path = Bundle.main.path(forResource: "dtmf-5", ofType: "caf")
            case .DTMF_6:
                path = Bundle.main.path(forResource: "dtmf-6", ofType: "caf")
            case .DTMF_7:
                path = Bundle.main.path(forResource: "dtmf-7", ofType: "caf")
            case .DTMF_8:
                path = Bundle.main.path(forResource: "dtmf-8", ofType: "caf")
            case .DTMF_9:
                path = Bundle.main.path(forResource: "dtmf-9", ofType: "caf")
            case .DTMF_STAR:
                path = Bundle.main.path(forResource: "dtmf-star", ofType: "caf")
            case .DTMF_POUND:
                path = Bundle.main.path(forResource: "dtmf-pound", ofType: "caf")
            case .callWaiting:
                path = Bundle.main.path(forResource: "CallWaiting", ofType: "wav")
            @unknown default:
                path = nil
                print("[Ringer] Unhandled RingerType: \(ringerType)")
                break
            }
            guard let path = path else {
                print("[Ringer] There was an issue finding the specified ringtone in the bundle")
                return
            }
            
            let url = URL(fileURLWithPath: path)
            do {
                if self.player.isPlaying {
                    self.player.stop()
                }
                self.player = try AVAudioPlayer(contentsOf: url)
                self.player.numberOfLoops = -1
                self.playingRingerType = ringerType
                self.player.play()
            } catch {
                print("[Ringer] There is an issue with ringtone")
            }
        }

        // This callback is called when the call stops ringing.
        call.onStopRinger = { [weak self] ringerType in
            guard let self = self else { return }
            
            print("[Ringer] Stopping tone for RingerType: \(ringerType)")
            
            if self.player.isPlaying && self.playingRingerType == ringerType {
                self.player.stop()
            }
        }
        
        call.oniOSBroadcastingChanged = { event in
            switch event {
            case .extensionConnected:
                call.startSharing(shareConfig: self.shareConfig, completionHandler: { error in
                    if error != nil {
                        print("share screen error:\(String(describing: error))")
                    }
                })
                self.isReceivingScreenShared = true
                print("Extension Connected")
            case .extensionDisconnected:
                call.stopSharing(completionHandler: { error in
                    if error != nil {
                        print("share screen error:\(String(describing: error))")
                    }
                })
                self.isReceivingScreenShared = false
                print("Extension stopped Broadcasting")
            @unknown default:
                break
            }
        }
        
        // Breakout session
        call.onSessionEnabled = { [weak self] in
                print("BreakoutSession: Session Enabled")
                self?.showSlideInMessage(message: "Breakout Session: Enabled")
        }
        
        call.onSessionStarted = { [weak self] breakout in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                strongSelf.breakout = breakout
                if let _duration = breakout.duration {
                    strongSelf.duration = Int(_duration)
                    strongSelf.showDurationLabel = true
                    strongSelf.runTimer()
                }
                print("BreakoutSession: Session Started \(breakout)")
                strongSelf.showSlideInMessage(message: "Breakout Session: Started")
            }
        }
        call.onBreakoutUpdated = { [weak self] breakout in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                strongSelf.breakout = breakout
                if breakout.duration == nil {
                    strongSelf.showDurationLabel = false
                }
                print("BreakoutSession: Breakout Updated \(breakout)")
                strongSelf.showSlideInMessage(message: "Breakout Session: Breakout Updated")
            }
        }
        
        call.onSessionJoined = { [weak self] session in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                strongSelf.breakoutJoined = true
                print("BreakoutSession: Session Joined \(session)")
                strongSelf.showSlideInMessage(message: "Breakout Session: \(session.name) Joined")
                strongSelf.callTitle = session.name
            }
        }
        
        call.onJoinableSessionListUpdated = { [weak self] sessions in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                print("BreakoutSession: Joinable Session List Updated \(sessions)")
                strongSelf.sessions = sessions
            }
        }
        
        call.onHostAskingReturnToMainSession = { [weak self] in
            print("BreakoutSession: Host Asking Return To Main Session")
            self?.showSlideInMessage(message: "Host Asking Return To Main Session")
        }
        
        call.onBroadcastMessageReceivedFromHost = { [weak self] message in
            print("BreakoutSession: Broadcast Message Received From Host \(message)")
            self?.showSlideInMessage(message: "Message Received From Host \n \(message)")
        }
        
        call.onJoinedSessionUpdated = { [weak self] session in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                print("BreakoutSession: Session Updated \(session)")
                strongSelf.showSlideInMessage(message: "Breakout Session: \(session.name) Updated")
                strongSelf.callTitle = session.name
            }
        }
        
        call.onSessionClosing = { [weak self] in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                print("BreakoutSession: Session Closing")
                if let delay = strongSelf.breakout?.delay {
                    strongSelf.showSlideInMessage(message: "Breakout Session: Closing in \(Int(delay)) seconds")
                }
            }
        }
        
        call.onReturnedToMainSession = { [weak self] in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                strongSelf.breakoutJoined = false
                strongSelf.showDurationLabel = false
                print("BreakoutSession: Returned To Main Session")
                strongSelf.showSlideInMessage(message: "Returned To Main Session")
                strongSelf.callTitle = call.title ?? ""
            }
        }
        
        call.onBreakoutErrorHappened = { [weak self] error in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                print("BreakoutSession: Breakout Error Happened")
                strongSelf.showSlideInMessage(message: "Breakout Error: \(error.rawValue)")
            }
        }
        
        call.onReceivingNoiseInfoChanged = { [weak self] info in
            DispatchQueue.main.async {
                guard let strongSelf = self else {return}
                if info.isNoiseDetected && !info.isNoiseRemovalEnabled && !strongSelf.showNoiseRemovalAlert {
                    strongSelf.showNoiseRemovalAlert = true
                    strongSelf.showError("Noise Detected, You want to remove?", "")
                }
                let seconds = 30.0
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { // this timer and boolean  isNoiseDetectedAlertShown are used here to avoid repeated alerts
                    strongSelf.showNoiseRemovalAlert = false
                }
                if strongSelf.showNoiseRemovalAlert {
                    strongSelf.updateNoiseRemovalState()
                }
            }
        }
        
        call.onPhotoCaptured = {  [weak self] data in
            DispatchQueue.main.async {
                guard let strongSelf = self, let imageData = data else {return}
                strongSelf.selfPhoto = UIImage(data: imageData)
                strongSelf.showSelfPhoto = true
            }
        }
    }

    private func updateNoiseRemovalState() {
        DispatchQueue.main.async { [weak self] in
            self?.showNoiseRemovalButtonIcon = true
            if self?.currentCall?.receivingNoiseInfo?.isNoiseDetected == true {
                self?.noiseRemovalButtonImage = Image("noise-detected-filled")
                if self?.currentCall?.receivingNoiseInfo?.isNoiseRemovalEnabled == true {
                    self?.noiseRemovalButtonImage = Image("noise-detected-cancelled-filled")
                }
            }
        }
    }
    
    func setMediaQualityInfoChangedCallback() {
        self.currentCall?.onMediaQualityInfoChanged = { indicator in
            DispatchQueue.main.async {  [weak self] in
                var message = ""
                switch indicator {
                case .Good:
                    message = "good"
                    self?.badNetworkIconColor = .green
                case .PoorUplink:
                    message = "PoorUplink!"
                    self?.badNetworkIconColor = .yellow
                case .PoorDownlink:
                    message = "PoorDownlink!"
                    self?.badNetworkIconColor = .yellow
                case .NetworkLost:
                    message = "networkLost!"
                    self?.badNetworkIconColor = .red
                case .DeviceLimitation:
                    message = "CPUStaticCondition!"
                    self?.badNetworkIconColor = .yellow
                case .HighCpuUsage:
                    message = "CPUDynamicCondition!"
                    self?.badNetworkIconColor = .yellow
                @unknown default:
                    message = "good"
                    self?.badNetworkIconColor = .green
                }
                self?.showBadNetworkIcon = true
                self?.showError("Network Quality Info", message)
            }
        }
        
        self.currentCall?.onTranscriptionArrived = { [weak self] transcription in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                strongSelf.transcriptionItems.append(transcription)
            }
        }
    }
    
    private func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc private func updateTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let durationStr =  self?.timeString(time: TimeInterval(self?.duration ?? 0)) else { return }
            self?.duration -= 1
            self?.durationLabel = "Breakout session duration \(durationStr)"
        }
    }
    
    private func timeString(time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    // Update UI states.
    private func updateStates(call: CallProtocol) {
        // TODO: add other variables as and when required
        DispatchQueue.main.async { [weak self] in
            self?.renderMode = call.renderMode
            self?.torchMode = call.torchMode
            self?.flashMode = call.flashMode
            self?.cameraTargetBias = call.cameraTargetBias
            self?.cameraISO = call.cameraISO
            self?.cameraDuration = call.cameraDuration
            self?.zoomFactor = call.zoomFactor

            self?.isLocalAudioMuted = !call.sendingAudio
            self?.isLocalVideoMuted = !call.sendingVideo
            self?.receivingScreenShare = call.receivingScreenShare
            self?.receivingVideo = call.receivingVideo
            self?.receivingAudio = call.receivingAudio
            self?.isOnHold = call.isOnHold
            self?.isAudioOnly = call.isAudioOnly
            self?.isCUCMOrWxcCall = call.isCUCMCall || call.isWebexCallingOrWebexForBroadworks
            self?.isWXAEnabled = call.isWXAEnabled
            self?.canControlWXA = call.canControlWXA
            self?.isClosedCaptionAllowed = call.isClosedCaptionAllowed
            self?.isClosedCaptionEnabled = call.isClosedCaptionEnabled
            self?.speechEnhancement = call.isSpeechEnhancementEnabled
        }
        self.updateNameLabels(connected: call.isConnected)
    }

    // Handles ToggleVideo Action.
    func handleToggleVideoCallAction() {
        isLocalVideoMuted.toggle()
        self.currentCall?.sendingVideo = !isLocalVideoMuted
    }

    // Handles MuteCall Action.
    func handleMuteCallAction() {
        guard let call = currentCall else {
            showError("Error", "Call not found")
            return
        }
        isLocalAudioMuted.toggle()
        call.sendingAudio = !call.sendingAudio
    }
    
    // Handles more Options.
    func handleMoreClickAction() {
        DispatchQueue.main.async { [weak self] in
            self?.showMoreOptions = true
        }
    }
    
    // Handles HoldCall Action.
    func handleHoldCallAction() {
        currentCall?.holdCall(putOnHold: !self.isOnHold)
       // TODO: Handle callkit hold call
    }
    
    // Handles ReceivingVideo Action.
    func handleReceivingVideoAction(isOn: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.currentCall?.receivingVideo = isOn
        }
    }
    
    // Handles Receiving Audio Action.
    func handleReceivingAudioAction(isOn: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.currentCall?.receivingAudio = isOn
        }
    }
    
    // Handles ReceivingScreenShare Action.
    func handleReceivingScreenShareAction(isOn: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.currentCall?.receivingScreenShare = isOn
        }
    }

    // Handles Speech Enhancement for the call.
    func handleSpeechEnhancement(isOn: Bool) {
        if isOn == self.speechEnhancement {
            return
        }
        self.currentCall?.enableSpeechEnhancement(shouldEnable: isOn, completionHandler: { result in
            switch result
            {
            case .success():
                DispatchQueue.main.async { [weak self] in
                    self?.speechEnhancement.toggle()
                }
            case .failure(let err):
                DispatchQueue.main.async { [weak self] in
                    self?.showError("Speech Enhancement Error ", err.localizedDescription)
                }
            }
        })
    }

    // Handles EndCall Action.
    func handleEndCall()
    {
        guard let call = currentCall else {
            webex.phone.cancel()
            DispatchQueue.main.async { [weak self] in
                self?.dismissCallingScreenView = true
            }
            return
        }
        endCall(call: call)
        // TODO: handle callkit report end call
    }
    
    // Ends the call.
    func endCall(call: CallProtocol) { // parameterised because of future use of handling multiple calls
        call.hangup { [weak self] error in
            if error == nil {
            } else {
                self?.showError("Error", error.debugDescription)
            }
        }
    }
    
    // Shows the alert with the given title and message.
    func showError(_ alertTitle: String, _ alertMessage: String) {
        DispatchQueue.main.async { [weak self] in
            self?.alertTitle = alertTitle
            self?.alertMessage = alertMessage
            self?.showAlert = true
        }
    }
    
    // Handles self camera swap action
    func handleSwapCameraAction() {
        if !isExternalCameraEnabled {
            isFrontCamera.toggle()
            currentCall?.handleSwapCameraAction(isFrontCamera: isFrontCamera)
        } else {
            DispatchQueue.main.async {
                self.showError("Illegal Operation", "Swap camera is disabled while using external camera")
            }
        }
    }
    
    // Update self, remote video media view
    func updateMediaView() {
        DispatchQueue.main.async { [weak self] in
            self?.shouldUpdateView = true
        }
    }
    
    // Handles screen share start action
   func startSharing() {
       currentCall?.startSharing(shareConfig: self.shareConfig, completionHandler: { error in
           print(String(describing:error?.localizedDescription))
       })
   }
    
    // Handles screen share  stop action
    func stopSharing() {
        currentCall?.stopSharing(completionHandler: { error in
            print(String(describing:error?.localizedDescription))
        })
    }
        
    ///  Update screen share config from info plist.
    func updateScreenShareConfig() {
        let path = Bundle.main.path(forResource: "Info", ofType: "plist")
        let keys = NSDictionary(contentsOfFile: path ?? "")
        guard let groupId = keys?["GroupIdentifier"] as? String, !groupId.isEmpty else { fatalError("KitchenSink: Expected your Broadcast Extension's Info.plist to contain a valid group identifier. Please add a key `GroupIdentifier` with the value as your App's Group Identifier to your App's Info.plist. This is required for ScreenSharing") }
                        
        if let defaults = UserDefaults(suiteName: groupId)
        {
            switch self.shareConfig.shareType {
            case .OptimizeVideo:
                defaults.setValue(true, forKey: "optimizeForVideo")
            default:
                defaults.setValue(false, forKey: "optimizeForVideo")
            }
        }
        self.showScreenShareControl = true
    }
    
    //Start screen share
    func startScreenShare() {
        DispatchQueue.main.async { [weak self] in
            self?.shouldShowScreenConfig = true
        }
    }
    
    func showMultiStreamAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showMultiStreamOptionsAlert = true
        }
    }
    
    fileprivate func registerNewMultiStreamCallBacks(_ call: CallProtocol) {
        call.onMediaStreamAvailabilityListener = { [weak self] available, stream in
            if available, let strongSelf = self {
                if stream.streamType == .Stream1 {
                    strongSelf.updateRemoteViewMultiStream = true
                    strongSelf.currentCall?.mediaStream = stream
                    strongSelf.mediaStream = stream
                    stream.setOnMediaStreamInfoChanged { [weak self] type, info in
                        self?.onMediaStreamChanged(type: type, info: info)
                    }
                } else {
                    let view = MediaRenderView()
                    view.setSize(width: 150, height: 150)
                    let renderView = MediaRenderViewRepresentable(renderVideoView: view)
                    strongSelf.auxViews.append(renderView)
                    strongSelf.auxDictNew[renderView] = stream
                    stream.renderView = strongSelf.auxViews[strongSelf.auxViews.count - 1].renderVideoView
                }
                stream.setOnMediaStreamInfoChanged { [weak self] type, info in
                    self?.onMediaStreamChanged(type: type, info: info)
                }
            } else if !available {
                if let indexToRemove = self?.auxViews.firstIndex(where: { $0.renderVideoView == stream.renderView }) {
                    self?.auxViews.remove(at: indexToRemove)
                }
            }
        }
    }
    
    func onMediaStreamChanged(type: MediaStreamChangeEventType, info: MediaStreamChangeEventInfo) {
        if info.stream.streamType == .Stream1 {
            currentCall?.infoMediaStream = info.stream
            self.infoMediaStream = info.stream
            self.updateRemoteViewInfoMultiStream = true
            return
        }
        
        DispatchQueue.main.async {
            if let indexToRemove = self.auxViews.firstIndex(where: { $0.renderVideoView == info.stream.renderView }) {
                if let view = info.stream.renderView {
                    let renderView = MediaRenderViewRepresentable(renderVideoView: view)
                    self.auxViews.remove(at: indexToRemove)
                    self.auxViews.insert(renderView , at: indexToRemove)
                    self.auxDictNew[renderView] = info.stream
                }
            }
        }
        switch type {
        case .Size:
            print("size changes")
        case .Membership:
            print("Membership changes")
        case .Video:
            print("Video changes")
        case .Audio:
            print("Audio changes")
        case .PinState:
            print("PinState changes")
        }
        
    }
    
    func setMediaStreamCategoryA(duplicate: Bool, quality: MediaStreamQuality) {
        currentCall?.setMediaStreamCategoryA(duplicate: duplicate, quality: quality)
    }
    
    func setMediaStreamsCategoryB(numStreams: Int, quality: MediaStreamQuality) {
        currentCall?.setMediaStreamsCategoryB(numStreams: numStreams, quality: quality)
    }
    
    func setMediaStreamCategoryC(participantId: String, quality: MediaStreamQuality) {
        currentCall?.setMediaStreamCategoryC(participantId: participantId, quality: quality)
    }
    
    func removeMediaStreamCategoryA() {
        currentCall?.removeMediaStreamCategoryA()
    }
    
    func removeMediaStreamCategoryB() {
        currentCall?.removeMediaStreamCategoryB()
    }
    
    func removeMediaStreamCategoryC() {
        DispatchQueue.main.async { [weak self] in
            if let participantID = self?.participantId {
                self?.currentCall?.removeMediaStreamCategoryC(participantId: participantID)
            }
        }
    }
    
    func updateCaptcha(captcha: Phone.Captcha?) {
        guard let captcha = captcha else {
            return
        }

        guard let url = URL(string: captcha.imageUrl) else {
            return
        }
        
        self.audioURL = URL(string: captcha.audioUrl)
        downloadImage(from: url) { data in
            DispatchQueue.main.async { [weak self] in
                self?.captchaImage = UIImage(data: data)
            }
        }
    }
    
    func handleCaptchaRefreshAction() {
        self.webexPhone.refreshMeetingCaptcha { [weak self] result in
            switch result {
            case .success(let captcha):
                guard let imageURL = URL.init(string: captcha.imageUrl) else { return }
                self?.downloadImage(from: imageURL) { data in
                    DispatchQueue.main.async {
                        self?.captchaImage = UIImage(data: data)
                    }
                }
            case .failure(let error):
                print("error" + error.localizedDescription)
            }
        }
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(from url: URL, completionHandler: @escaping (Data) -> Void) {
        print("Download Started")
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            completionHandler(data)
        }
    }
    
    func downloadFileFromURL(url:URL, completionHandler: @escaping (URL?) -> Void) {
        var downloadTask:URLSessionDownloadTask
        downloadTask = URLSession.shared.downloadTask(with: url as URL, completionHandler: { (URL, response, error) -> Void in
            completionHandler(URL)
        })
        downloadTask.resume()
    }
    
    func handleCaptchaAudioButtonAction() {
        guard let audioURL = audioURL else {
            return
        }
        do {
            audioPlayer = try AVPlayer(url: audioURL as URL)
            audioPlayer.volume = 1
        } catch {
            print("audio file error")
        }
        audioPlayer?.play()
    }
    
    private func showSlideInMessage(message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.showSlideInMessage = true
            self?.messageText = message
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            withAnimation {
                self?.showSlideInMessage = false
            }
        }
    }
    
    func mediaQualityInfoChanged() {
        DispatchQueue.main.async { [weak self] in
            if self?.currentCall?.onMediaQualityInfoChanged == nil {
                self?.showBadNetworkIcon = true
                self?.setMediaQualityInfoChangedCallback()
            } else {
                self?.showBadNetworkIcon = false
                self?.currentCall?.onMediaQualityInfoChanged = nil
            }

        }
    }
    
    func enableReceivingNoiseRemoval(shouldEnable: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.currentCall?.enableReceivingNoiseRemoval(shouldEnable: shouldEnable, completionHandler: { result in
                self?.updateNoiseRemovalState()
            })
        }
    }
    
    func handleNoiseRemovalAction() {
        guard let call = currentCall, let receivingNoiseInfo = currentCall?.receivingNoiseInfo else {
            return
        }
        
        call.enableReceivingNoiseRemoval(shouldEnable: !receivingNoiseInfo.isNoiseRemovalEnabled) { [weak self] result in
            switch result {
            case .NoError:
                print("enable/disable ReceivingNoiseRemoval success")
            case .NotSupported:
                print("NotSupported")
            case .InternalError:
                print("InternalError")
            }
            self?.updateNoiseRemovalState()
        }
    }
    
    func convertToTranscriptionKS(transcription: Transcription) -> TranscriptionKS {
        return TranscriptionKS(id: UUID(), personName: transcription.personName,
                                   personId: transcription.personId,
                                   content: transcription.content,
                                   timestamp: transcription.timestamp)
    }
    
    func convertToCaptionKS(caption: CaptionItem) -> CaptionItemKS {
        return CaptionItemKS(from: caption)
    }
    
    func showTextCaptionView() {
        guard let call = self.currentCall else { return }
        var previousSpeaker = ""
        call.onClosedCaptionArrived = { [weak self] caption in
            DispatchQueue.main.async {
                if caption.displayName != previousSpeaker {
                    self?.closedCaptionsTextDisplay = self?.closedCaptionsTextDisplay ?? "" + caption.displayName + ": " + caption.content
                    previousSpeaker = caption.displayName
                }
                else {
                    self?.closedCaptionsTextDisplay = caption.displayName + ": " + caption.content
                }
                self?.showCaptionTextView = true
            }
        }
    }
        
    func updateSelectedLanguage() {
        guard let selectedLanguageItem = self.selectedLanguage else { return }
        DispatchQueue.main.async { [weak self] in
            if let value = self?.isSpokenItemSelected, value {
                self?.setSpokenLanguage(languageItem: selectedLanguageItem)
                self?.spokenLanguageButton = selectedLanguageItem.languageTitleInEnglish
            } else if let value = self?.isTranslationItemSelected, value {
                self?.setTranslationLanguage(languageItem: selectedLanguageItem)
                self?.translationLanguageButton = selectedLanguageItem.languageTitleInEnglish
            }
        }
    }
    
    func setSpokenLanguage(languageItem: WebexSDK.LanguageItem) {
        guard let call = self.currentCall else { return }
        call.setCurrentSpokenLanguage(language: languageItem) { error in
            print(error.debugDescription)
        }
    }
    
    func setTranslationLanguage(languageItem: WebexSDK.LanguageItem) {
        guard let call = self.currentCall else { return }
        call.setCurrentTranslationLanguage(language: languageItem) { error in
            print(error.debugDescription)
        }
    }
    
    func updateCaptionControls() {
        guard let call = self.currentCall else { return }
        DispatchQueue.main.async { [weak self] in
            self?.info = call.getClosedCaptionsInfo()
            self?.canChangeSpokenLanguage = self?.info?.canChangeSpokenLanguage ?? false
            self?.spokenLanguageButton = self?.info?.currentSpokenLanguage.languageTitleInEnglish ?? ""
            self?.translationLanguageButton = self?.info?.currentTranslationLanguage.languageTitleInEnglish ?? ""

        }
        call.onClosedCaptionsInfoChanged =  {  [weak self] info in
            DispatchQueue.main.async {
                self?.info = info
                self?.canChangeSpokenLanguage = info.canChangeSpokenLanguage
                self?.spokenLanguageButton = info.currentSpokenLanguage.languageTitleInEnglish
                self?.translationLanguageButton = info.currentTranslationLanguage.languageTitleInEnglish
            }
        }
    }
    
    func showSpokenLanguageList() {
        DispatchQueue.main.async { [weak self] in
            self?.showSpokenLanguagesList = true
        }
    }

    func showTranslationLanguageList() {
        DispatchQueue.main.async { [weak self] in
            self?.showTranslationsLanguagesList = true
        }
    }

    func showCaptionsListView() {
        DispatchQueue.main.async { [weak self] in
            guard let call = self?.currentCall else { return }
            self?.captionItems = call.getClosedCaptions()
            call.onClosedCaptionArrived = { item in
                if item.isFinal {
                    self?.captionItems.append(item)
                }
            }
        }
    }

    func toggleClosedCaptions(isOn: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let call = self?.currentCall else { return }
            call.toggleClosedCaption(enable: isOn) { isOn in
                DispatchQueue.main.async { [weak self] in
                    self?.closedCaptionsToggle = isOn
                    self?.canChangeSpokenLanguage = self?.info?.canChangeSpokenLanguage ?? false
                }
            }
        }
    }
    
    func updateWebexAssistant() {
        DispatchQueue.main.async { [weak self] in
            guard let call = self?.currentCall , let isEnabled = self?.isWXAEnabled else { return }
            let isWXAEnabled = !isEnabled
            call.enableWXA(isEnabled: isWXAEnabled) { success in
                    print("setting WXA to: \(isWXAEnabled) operation returned: \(success)")
                    var message: String
                    if success {
                        message = isWXAEnabled ? "WXA enabled" : "WXA disabled"
                    } else {
                        message = isWXAEnabled ? "Could not enable WXA" : "Could not disable WXA"
                    }
                self?.showSlideInMessage(message: message)
            }
        }
    }

    func updateZoomFactor(factor: Float) {
        self.currentCall?.updateZoomFactor(factor: factor)
    }
    
    func setTorchMode(mode: Call.TorchMode) {
        guard var index = torchModes.firstIndex(of: self.torchMode) else { return }
        if index == torchModes.count - 1 {
            index = 0
        } else {
            index += 1
        }
        self.torchMode = torchModes[index]
        self.currentCall?.setTorchMode(mode: torchModes[index])
    }
    
    func setFlashMode(mode: Call.FlashMode) {
        guard var index = flashModes.firstIndex(of: self.flashMode) else { return }
        if index == flashModes.count - 1 {
            index = 0
        } else {
            index += 1
        }
        self.flashMode = flashModes[index]
        self.currentCall?.setFlashMode(mode: flashModes[index])
    }
    
    func setRenderMode(mode: Call.VideoRenderMode) {
        guard var index = renderModes.firstIndex(of: self.renderMode) else { return }
        if index == renderModes.count - 1 {
            index = 0
        } else {
            index += 1
        }
        self.renderMode = renderModes[index]
        self.currentCall?.setRenderMode(mode: renderModes[index])
    }
    
    func setCameraFocusAtPoint(pointX: Float, pointY: Float) {
       let _ = self.currentCall?.setCameraFocusAtPoint(pointX: pointX, pointY: pointY)
    }
    
    func setCameraCustomExposure(duration: UInt64, iso: Float) {
       let _ = self.currentCall?.setCameraCustomExposure(duration: duration, iso: iso)
    }
    
    func setCameraAutoExposure(targetBias: Float) {
        let _ = self.currentCall?.setCameraAutoExposure(targetBias: targetBias)
    }
    
    func takePhoto() {
        let _ = self.currentCall?.takePhoto()
    }
    
    func sendDTMFAuthCode(code: String) {
        currentCall?.send(dtmfCode: code, completionHandler: { res in
            if let res = res {
                print("Send DTMF error: \(res)")
            }
        })
    }
    
    func isCameraOff()-> Bool {
        var result = false
        guard let videoSending = currentCall?.sendingVideo  else {
            print("call.sending video is null")
            return true
        }
        
        if !videoSending {
            result = true
            showError("Camera is off", "Please enable camera for selecting virtual background")
        }
        return result
    }

    func setupExternalCameraConnectionNotifications() {
        if #available(iOS 17.0, *) {
            cameraDeviceManager?.onExternalCameraDeviceConnected = { camera in
                DispatchQueue.main.async {
                    self.externalCamera = camera
                    self.isExternalCameraConnected = true
                    self.isExternalCameraEnabled = true
                    self.showError("External camera connected", "\(camera.name)")
                }
            }

            cameraDeviceManager?.onExternalCameraDeviceDisconnected = {
                DispatchQueue.main.async {
                    self.isExternalCameraConnected = false
                    self.isExternalCameraEnabled = false
                    self.showError("External camera disconnected", "")
                }
            }
        } else {
            print("External Camera Error: Requires iOS 17.0 and above")
        }
    }

    func connectCamera(isExternal: Bool) {
        if #available(iOS 17.0, *) {
            var camera: Camera?
            guard let externalCamera = self.externalCamera else {
                showError("External camera connection error", "")
                return
            }
            if isExternal {
                camera = externalCamera
            } else {
                let availableCameras = webexPhone.getListOfCameras()
                for availableCamera in availableCameras {
                    if availableCamera.isDefaultCamera {
                        camera = availableCamera
                        break
                    }
                }
            }
            guard let camera = camera else {
                showError("camera connection error", "")
                return
            }
            webexPhone.updateSystemPreferredCamera(camera: camera, completionHandler: {
                result in
                switch result {
                case .success():
                    DispatchQueue.main.async {
                        if isExternal {
                            self.isExternalCameraEnabled = true
                        } else {
                            self.isExternalCameraEnabled = false
                        }
                    }
                    print("External camera connected", "\(externalCamera.name)")
                case .failure(let err):
                    DispatchQueue.main.async {
                        self.showError("External camera connection error", "\(err)")
                    }
                }
            })
        } else {
            print("External Camera Error: Requires iOS 17.0 and above")
        }
    }
}
