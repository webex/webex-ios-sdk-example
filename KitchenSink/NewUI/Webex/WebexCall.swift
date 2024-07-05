import Foundation
import WebexSDK

// Wrapper for Call Object
@available(iOS 16.0, *)
public protocol CallProtocol: AnyObject {
    //variables
    var callId: String? {get}
    var uuid: UUID? {get set}
    var title: String? {get}
    var isCUCMCall: Bool {get}
    var isWebexCallingOrWebexForBroadworks: Bool {get}
    var isOnHold: Bool {get}
    var sendingAudio: Bool {get set}
    var sendingVideo: Bool {get set}
    var isAudioOnly: Bool {get}
    var receivingVideo: Bool {get set}
    var receivingAudio: Bool {get set}
    var receivingScreenShare: Bool {get set}
    var isConnected: Bool {get set}
    var canControlWXA: Bool {get set}
    var isWXAEnabled: Bool {get set}
    var isClosedCaptionEnabled: Bool {get}
    var isClosedCaptionAllowed: Bool {get}
    var videoRenderViews: (local: MediaRenderView?, remote: MediaRenderView?) {get set}
    var screenShareView: MediaRenderView? {get set}
    var mediaStream: MediaStream? {get set}
    var infoMediaStream: MediaStream? {get set}
    var breakout: Call.Breakout? {get set}
    var breakoutSession: [Call.BreakoutSession] {get set}
    var memberships: [CallMembershipKS] {get}
    
    var renderMode: Call.VideoRenderMode {get set}
    var torchMode: Call.TorchMode {get set}
    var flashMode: Call.FlashMode {get set}
    var cameraTargetBias: WebexSDK.Call.CameraExposureTargetBias? {get}
    var cameraISO: WebexSDK.Call.CameraExposureISO? {get}
    var cameraDuration: WebexSDK.Call.CameraExposureDuration? {get}
    var zoomFactor: Float {get set}

    var onCallMembershipChanged: ((Call.CallMembershipChangedEvent) -> Void)? { get set }
    func inviteParticipant(participant: String, completionHandler: @escaping (Result<Void>) -> Void)
    func reclaimHost(hostKey: String, completionHandler: @escaping (Result<Void>) -> Void)
    func makeHost(participantId: String, completionHandler: @escaping (Result<Void>) -> Void)
    func setParticipantAudioMuteState(participantId: String, isMuted: Bool)

    //events
    var onConnected: (() -> Void)? {get set}
    var onMediaChanged: ((WebexSDK.Call.MediaChangedEvent) -> Void)? {get set}
    var onInfoChanged: (() -> Void)? {get set}
    var onFailed: ((String) -> Void)? {get set}
    var onDisconnected: ((WebexSDK.Call.DisconnectReason) -> Void)? {get set}
    var onStartRinger: ((RingerTypeKS) -> Void)? {get set}
    var onStopRinger: ((RingerTypeKS) -> Void)? {get set}
    var oniOSBroadcastingChanged: ((WebexSDK.Call.iOSBroadcastingEvent) -> Void)? { get set }
    var onMediaStreamAvailabilityListener: ((Bool, MediaStream) -> Void)? {get set}
    var onClosedCaptionArrived: ((CaptionItem) -> Void)? {get set}
    var onClosedCaptionsInfoChanged: ((ClosedCaptionsInfo) -> Void)? {get set}
    var onTranscriptionArrived: ((Transcription) -> Void)? { get set }
    
    //Breakout session
    var onSessionEnabled: (() -> Void)? { get set }
    var onSessionStarted: ((WebexSDK.Call.Breakout) -> Void)? { get set }
    var onBreakoutUpdated: ((WebexSDK.Call.Breakout) -> Void)? { get set }
    var onSessionJoined: ((WebexSDK.Call.BreakoutSession) -> Void)? { get set }
    var onJoinedSessionUpdated: ((WebexSDK.Call.BreakoutSession) -> Void)? { get set }
    var onJoinableSessionListUpdated: (([WebexSDK.Call.BreakoutSession]) -> Void)? { get set }
    var onHostAskingReturnToMainSession: (() -> Void)? { get set }
    var onBroadcastMessageReceivedFromHost: ((String) -> Void)? { get set }
    var onSessionClosing: (() -> Void)? { get set }
    var onReturnedToMainSession: (() -> Void)? { get set }
    var onBreakoutErrorHappened: ((BreakoutError) -> Void)? { get set }
    
    var onMediaQualityInfoChanged: ((MediaQualityInfo) -> Void)? {get set}
    var onReceivingNoiseInfoChanged: ((ReceivingNoiseInfo) -> Void)? {get set}
    var receivingNoiseInfo: ReceivingNoiseInfo? {get}
    
    var onPhotoCaptured: ((_ imageData: Data?) -> Void)? { get set }
    
    //actions
    func holdCall(putOnHold: Bool)
    func hangup(completionHandler: @escaping (Error?) -> Void)
    func updateAudioSession()
    func switchToVideoCall(completionHandler: @escaping (Result<Void>) -> Void)
    func switchToAudioCall(completionHandler: @escaping (Result<Void>) -> Void)
    func forceSendingVideoLandscape(forceLandscape: Bool, completionHandler: @escaping (Bool) -> Void)
    func handleSwapCameraAction(isFrontCamera: Bool)
    func answer(selfVideoView: MediaRenderViewKS?, remoteVideoViewRepresentable: RemoteVideoViewRepresentable?, screenShareView: MediaRenderViewKS?, isMoveMeeting: Bool, completionHandler: @escaping (Error?) -> Void)
    func reject(completionHandler: @escaping (Error?) -> Void)
    func startSharing(shareConfig: ShareConfigKS?, completionHandler: @escaping (Error?) -> Void)
    func stopSharing(completionHandler: @escaping (Error?) -> Void)
    func startAssociatedCall(dialNumber: String, associationType: CallAssociationTypeKS, isAudioCall: Bool, completionHandler:  @escaping (Swift.Result<CallProtocol, Error>) -> Void)
    func mergeCall(targetCallId: String)
    func transferCall(toCallId: String)
    func directTransferCall(toPhoneNumber: String, completionHandler: @escaping (Error?) -> Void)
    func setMediaStreamCategoryA(duplicate: Bool, quality: MediaStreamQuality)
    func setMediaStreamsCategoryB(numStreams: Int, quality: MediaStreamQuality)
    func setMediaStreamCategoryC(participantId: String, quality: MediaStreamQuality)
    func removeMediaStreamCategoryA()
    func removeMediaStreamCategoryB()
    func removeMediaStreamCategoryC(participantId: String)
    
    func returnToMainSession()
    func joinBreakoutSession(breakoutSession: WebexSDK.Call.BreakoutSession)
    func enableReceivingNoiseRemoval(shouldEnable: Bool, completionHandler: @escaping (ReceivingNoiseRemovalEnableResult) -> Void )
    
    func setCameraFocusAtPoint(pointX: Float, pointY: Float) -> Bool
    func setCameraCustomExposure(duration: UInt64, iso: Float) -> Bool
    func setCameraAutoExposure(targetBias: Float) -> Bool
    func takePhoto() -> Bool
    func setRenderMode(mode: Call.VideoRenderMode)
    func setTorchMode(mode: Call.TorchMode)
    func setFlashMode(mode: Call.FlashMode)
    func updateZoomFactor(factor: Float)
    func setCurrentSpokenLanguage(language: LanguageItem, completionHandler: @escaping (SpokenLanguageSelectionError?) -> Void)
    func setCurrentTranslationLanguage(language: LanguageItem, completionHandler: @escaping (TranslationLanguageSelectionError?) -> Void)
    func getClosedCaptionsInfo() -> WebexSDK.ClosedCaptionsInfo?
    func toggleClosedCaption(enable: Bool, completionHandler: @escaping (Bool) -> Void)
    func getClosedCaptions() -> [CaptionItem]
    func enableWXA(isEnabled: Bool, callback:@escaping ((Bool)->Void)) -> Void
    func send(dtmfCode: String, completionHandler: ((Error?) -> Void)?)
}

@available(iOS 16.0, *)
class CallKS: CallProtocol
{
    var mediaStream: WebexSDK.MediaStream?
    var infoMediaStream: WebexSDK.MediaStream?
    var isConnected: Bool = false
    var callId: String?
    var title: String?
    var isCUCMCall: Bool = false
    var isWebexCallingOrWebexForBroadworks: Bool = false
    var uuid: UUID?
    var isOnHold: Bool {
        return call?.isOnHold ?? false
    }
    var isAudioOnly: Bool {
        get {
            return call?.isAudioOnly ?? false
        }
    }
    
    var sendingAudio: Bool {
        get {
            return call?.sendingAudio ?? false
        }
        set {
            call?.sendingAudio = newValue
        }
        
    }
    var sendingVideo: Bool {
        get {
            return call?.sendingVideo ??  false
        }
        set {
            call?.sendingVideo = newValue
        }
    }
    
    var receivingVideo: Bool {
        get {
            return call?.receivingVideo ?? false
        }
        set {
            call?.receivingVideo = newValue
        }
    }
    
    var receivingAudio: Bool {
        get {
            return call?.receivingAudio ?? false
        }
        set {
            call?.receivingAudio = newValue
        }
    }
    
    var receivingScreenShare: Bool {
        get {
            return call?.receivingScreenShare ?? false
        }
        set {
            call?.receivingScreenShare = newValue
        }
    }
    
    var isClosedCaptionEnabled: Bool {
        get {
            return call?.isClosedCaptionEnabled ?? false
        }
    }
    
    var isClosedCaptionAllowed: Bool {
        get {
            return call?.isClosedCaptionAllowed ?? false
        }

    }
    
    var canControlWXA: Bool {
        get {
            return call?.wxa.canControlWXA  ?? false
        }
        set {
            call?.wxa.canControlWXA  = newValue
        }
    }
    
    var isWXAEnabled: Bool {
        get {
            return call?.wxa.isEnabled  ?? false
        }
        set {
            call?.wxa.isEnabled  = newValue
        }
    }
    
    var memberships: [CallMembershipKS] {
        get {
            return (call?.memberships.map({ callMembership in
                CallMembershipKS(callMembership: callMembership)
            }))!
        }
    }
    
    var renderMode: Call.VideoRenderMode {
        get {
            return call?.remoteVideoRenderMode ?? .fit
        }
        set {
            call?.remoteVideoRenderMode = newValue
        }
    }
    
    var torchMode: Call.TorchMode {
        get {
            return call?.cameraTorchMode ?? .off
        }
        set {
            call?.cameraTorchMode = newValue
        }
    }
    
    var flashMode: Call.FlashMode {
        get {
            return call?.cameraFlashMode ?? .off
        }
        set {
            call?.cameraFlashMode = newValue
        }
    }
    
    var zoomFactor: Float {
        get {
            return call?.zoomFactor ?? 1.0
        }
        set {
            call?.zoomFactor = newValue
        }
    }
    
    var cameraTargetBias: WebexSDK.Call.CameraExposureTargetBias? {
           return call?.exposureTargetBias
    }
    
    var cameraISO: WebexSDK.Call.CameraExposureISO? {
           return call?.exposureISO
    }
    
    var cameraDuration: WebexSDK.Call.CameraExposureDuration? {
        return call?.exposureDuration
    }
    
    private var call: Call?
    
    init(call: WebexSDK.Call) {
        self.call = call
        self.callId = call.callId
        self.title = call.title
        self.isCUCMCall = call.isCUCMCall
        self.isWebexCallingOrWebexForBroadworks = call.isWebexCallingOrWebexForBroadworks
        self.sendingAudio = call.sendingAudio
        self.sendingVideo = call.sendingVideo
        self.receivingVideo = call.receivingVideo
        self.receivingAudio = call.receivingAudio
        self.receivingScreenShare = call.receivingScreenShare
        self.uuid = call.uuid
        self.isWXAEnabled = call.wxa.isEnabled
        self.canControlWXA = call.wxa.canControlWXA
    }
    
    public var breakout: Call.Breakout?
    
    public var breakoutSession: [WebexSDK.Call.BreakoutSession] = []

    public var onConnected: (() -> Void)? {
        didSet {
            call?.onConnected = self.onConnected
        }
    }
    
    public var onMediaChanged: ((WebexSDK.Call.MediaChangedEvent) -> Void)? {
        didSet {
            call?.onMediaChanged = self.onMediaChanged
        }
    }
    
    public var onInfoChanged: (() -> Void)? {
        didSet {
            call?.onInfoChanged = self.onInfoChanged
        }
    }
    
    public var onFailed: ((String) -> Void)? {
        didSet {
            call?.onFailed = self.onFailed
        }
    }

    public var onDisconnected: ((WebexSDK.Call.DisconnectReason) -> Void)? {
        didSet {
            call?.onDisconnected = self.onDisconnected
        }
    }
    
    public var onStartRinger: ((RingerTypeKS) -> Void)? {
        didSet {
            call?.onStartRinger = { [weak self] type in
                if let block = self?.onStartRinger {
                    var ringerType = RingerTypeKS.outgoing
                    ringerType.fromRingerType(ringerType: type)
                    block(ringerType)
                }
            }
        }
    }
    
    public var onStopRinger: ((RingerTypeKS) -> Void)? {
        didSet {
            call?.onStopRinger = { [weak self] type in
                if let block = self?.onStopRinger {
                    var ringerType = RingerTypeKS.outgoing
                    ringerType.fromRingerType(ringerType: type)
                    block(ringerType)
                }
            }
        }
    }
    
    public var videoRenderViews: (local: MediaRenderView?, remote: MediaRenderView?) {
        didSet {
            call?.videoRenderViews = self.videoRenderViews
        }
    }
        
    public var screenShareView: MediaRenderView? {
        didSet {
            call?.screenShareRenderView = self.screenShareView
        }
    }
    
    public var oniOSBroadcastingChanged: ((WebexSDK.Call.iOSBroadcastingEvent) -> Void)? {
        didSet {
            call?.oniOSBroadcastingChanged = oniOSBroadcastingChanged
        }
    }
    
    public var onMediaStreamAvailabilityListener: ((Bool, MediaStream) -> Void)? {
        didSet {
            call?.onMediaStreamAvailabilityListener = onMediaStreamAvailabilityListener
        }
    }
        
    public var onSessionEnabled: (() -> Void)? {
        didSet {
            call?.onSessionEnabled = self.onSessionEnabled
        }
    }
    
    public var onSessionStarted: ((WebexSDK.Call.Breakout) -> Void)? {
        didSet {
            call?.onSessionStarted = self.onSessionStarted
        }
    }
    
    public var onBreakoutUpdated: ((WebexSDK.Call.Breakout) -> Void)? {
        didSet {
            call?.onBreakoutUpdated = self.onBreakoutUpdated
        }
    }
    
    public var onSessionJoined: ((WebexSDK.Call.BreakoutSession) -> Void)? {
        didSet {
            call?.onSessionJoined = self.onSessionJoined
        }
    }
    
    public var onJoinedSessionUpdated: ((WebexSDK.Call.BreakoutSession) -> Void)? {
        didSet {
            call?.onJoinedSessionUpdated = self.onJoinedSessionUpdated
        }
    }
    
    public var onJoinableSessionListUpdated: (([WebexSDK.Call.BreakoutSession]) -> Void)? {
        didSet {
            call?.onJoinableSessionListUpdated = self.onJoinableSessionListUpdated
        }
    }
    
    public var onHostAskingReturnToMainSession: (() -> Void)? {
        didSet {
            call?.onHostAskingReturnToMainSession = self.onHostAskingReturnToMainSession
        }
    }
    
    public var onBroadcastMessageReceivedFromHost: ((String) -> Void)? {
        didSet {
            call?.onBroadcastMessageReceivedFromHost = self.onBroadcastMessageReceivedFromHost
        }
    }
    
    public var onSessionClosing: (() -> Void)? {
        didSet {
            call?.onSessionClosing = self.onSessionClosing
        }
    }
    
    public var onReturnedToMainSession: (() -> Void)? {
        didSet {
            call?.onReturnedToMainSession = self.onReturnedToMainSession
        }
    }
    
    public var onBreakoutErrorHappened: ((WebexSDK.BreakoutError) -> Void)? {
        didSet {
            call?.onBreakoutErrorHappened = self.onBreakoutErrorHappened
        }
    }
    
    public var onMediaQualityInfoChanged: ((MediaQualityInfo) -> Void)? {
        didSet {
            call?.onMediaQualityInfoChanged = onMediaQualityInfoChanged
        }
    }
    
    public var onReceivingNoiseInfoChanged: ((ReceivingNoiseInfo) -> Void)? {
        didSet {
            call?.onReceivingNoiseInfoChanged = onReceivingNoiseInfoChanged
        }
    }
    
    public var receivingNoiseInfo: ReceivingNoiseInfo? {
        return call?.receivingNoiseInfo
    }
    
    public var onTranscriptionArrived: ((Transcription) -> Void)? {
        didSet {
            call?.wxa.onTranscriptionArrived = onTranscriptionArrived
        }
    }
    
    public var onClosedCaptionArrived: ((CaptionItem) -> Void)? {
        didSet {
            call?.onClosedCaptionArrived = onClosedCaptionArrived
        }
    }
    
    public var onClosedCaptionsInfoChanged: ((ClosedCaptionsInfo) -> Void)? {
        didSet {
            call?.onClosedCaptionsInfoChanged = onClosedCaptionsInfoChanged
        }
    }
    
    public var onPhotoCaptured: ((_ imageData: Data?) -> Void)? {
        didSet {
            call?.onPhotoCaptured = onPhotoCaptured
        }
    }
    
    public func returnToMainSession() {
        call?.returnToMainSession()
    }
    
    public func joinBreakoutSession(breakoutSession: WebexSDK.Call.BreakoutSession) {
        call?.joinBreakoutSession(breakoutSession: breakoutSession)
    }
    
    public func holdCall(putOnHold: Bool) {
        call?.holdCall(putOnHold: putOnHold)
    }
    
    public func hangup(completionHandler: @escaping (Error?) -> Void) {
        call?.hangup(completionHandler: completionHandler)
    }
    
    public func updateAudioSession() {
        call?.updateAudioSession()
    }
    
    public func switchToVideoCall(completionHandler: @escaping (Result<Void>) -> Void) {
        call?.switchToVideoCall(completionHandler:completionHandler)
    }
    
    public func switchToAudioCall(completionHandler: @escaping (Result<Void>) -> Void ) {
        call?.switchToVideoCall(completionHandler:completionHandler)
    }
    
    public func forceSendingVideoLandscape(forceLandscape: Bool, completionHandler: @escaping (Bool) -> Void) {
        call?.forceSendingVideoLandscape(forceLandscape: forceLandscape, completionHandler: completionHandler)
    }
    
    public func handleSwapCameraAction(isFrontCamera: Bool) {
        call?.facingMode = isFrontCamera ? .user : .environment
    }

    public func answer(selfVideoView:  MediaRenderViewKS? = nil, remoteVideoViewRepresentable: RemoteVideoViewRepresentable? = nil, screenShareView: MediaRenderViewKS? = nil, isMoveMeeting: Bool = false, completionHandler: @escaping (Error?) -> Void) {
        let mediaOption = WebexPhone().getMediaOption(isMoveMeeting: isMoveMeeting, selfVideoView: selfVideoView, remoteVideoViewRepresentable: remoteVideoViewRepresentable, screenShareView: screenShareView)
        call?.answer(option: mediaOption, completionHandler: completionHandler)
    }
    
    public func reject(completionHandler: @escaping (Error?) -> Void) {
        call?.reject(completionHandler: completionHandler)
    }

    public func startAssociatedCall(dialNumber: String, associationType: CallAssociationTypeKS, isAudioCall: Bool, completionHandler:  @escaping (Swift.Result<CallProtocol, Error>) -> Void) {
        call?.startAssociatedCall(dialNumber: dialNumber, associationType: associationType.toCallAssociationType(), isAudioCall: isAudioCall, completionHandler: { result in
            switch result {
            case .success(let call):
                if let call = call
                {
                    completionHandler(.success(CallKS(call: call)))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            @unknown default:
               print("default case of dialPhoneNumber")
            }
        })
    }
    
    public func mergeCall(targetCallId: String) {
        call?.mergeCall(targetCallId: targetCallId)
    }
    
    public func transferCall(toCallId: String) {
        call?.transferCall(toCallId: toCallId)
    }
    
    public func directTransferCall(toPhoneNumber: String, completionHandler: @escaping (Error?) -> Void) {
        call?.directTransferCall(toPhoneNumber: toPhoneNumber, completionHandler: completionHandler)
    }
    
    public func startSharing(shareConfig: ShareConfigKS?, completionHandler: @escaping (Error?) -> Void) {
        let config = ShareConfig(shareType: ShareOptimizeTypeKS.convertToShareOptimizeType(shareConfig?.shareType ?? .Default) , enableAudio: shareConfig?.enableAudio ?? false)
        call?.startSharing(shareConfig: config, completionHandler: completionHandler)
    }
    
    public func stopSharing(completionHandler: @escaping (Error?) -> Void) {
        call?.stopSharing(completionHandler: completionHandler)
    }
    
    public func setMediaStreamCategoryA(duplicate: Bool, quality: MediaStreamQuality) {
        call?.setMediaStreamCategoryA(duplicate: duplicate, quality: quality)
    }
    
    public func setMediaStreamsCategoryB(numStreams: Int, quality: MediaStreamQuality) {
        call?.setMediaStreamsCategoryB(numStreams: numStreams, quality: quality)
    }
    
    public func setMediaStreamCategoryC(participantId: String, quality: MediaStreamQuality) {
        call?.setMediaStreamCategoryC(participantId: participantId, quality: quality)
    }
    
    public func removeMediaStreamCategoryA() {
        call?.removeMediaStreamCategoryA()
    }
    
    public func removeMediaStreamCategoryB() {
        call?.removeMediaStreamsCategoryB()
    }
    
    public func removeMediaStreamCategoryC(participantId: String) {
        call?.removeMediaStreamCategoryC(participantId: participantId)
    }

    public var onCallMembershipChanged: ((Call.CallMembershipChangedEvent) -> Void)? {
        didSet {
            call?.onCallMembershipChanged = { [weak self] event in
                if let block = self?.onCallMembershipChanged {
                    block(event)
                }
            }
        }
    }
    
    public func inviteParticipant(participant: String, completionHandler: @escaping (Result<Void>) -> Void) {
        call?.inviteParticipant(participant: participant, completionHandler: completionHandler)
    }
    
    public func reclaimHost(hostKey: String = "", completionHandler: @escaping (Result<Void>) -> Void) {
        call?.reclaimHost(hostKey: hostKey, completionHandler: completionHandler)
    }
    
    public func makeHost(participantId: String, completionHandler: @escaping (Result<Void>) -> Void) {
        call?.makeHost(participantId:participantId, completionHandler: completionHandler)
    }
    
    public func setParticipantAudioMuteState(participantId: String, isMuted: Bool) {
        call?.setParticipantAudioMuteState(participantId: participantId, isMuted: isMuted)
    }
    
    public func enableReceivingNoiseRemoval(shouldEnable: Bool, completionHandler: @escaping (ReceivingNoiseRemovalEnableResult) -> Void ) {
        call?.enableReceivingNoiseRemoval(shouldEnable: shouldEnable, completionHandler: completionHandler)
    }
    
    public func setCameraFocusAtPoint(pointX: Float, pointY: Float) -> Bool {
        return call?.setCameraFocusAtPoint(pointX: pointX, pointY: pointY) ?? false
    }
    
    public func setCameraCustomExposure(duration: UInt64, iso: Float) -> Bool {
        return call?.setCameraCustomExposure(duration: duration, iso: iso) ?? false
    }
    
    public func setCameraAutoExposure(targetBias: Float) -> Bool {
        return call?.setCameraAutoExposure(targetBias: targetBias) ?? false
    }
    
    public func takePhoto() -> Bool {
        return call?.takePhoto() ?? false
    }
    
    public func setRenderMode(mode: Call.VideoRenderMode) {
        self.renderMode = mode
        self.call?.remoteVideoRenderMode = mode
    }
    
    public func setTorchMode(mode: Call.TorchMode) {
        self.torchMode = mode
        self.call?.cameraTorchMode = mode
    }

    public func setFlashMode(mode: Call.FlashMode) {
        self.flashMode = mode
        self.call?.cameraFlashMode = mode
    }
    
    public func updateZoomFactor(factor: Float) {
        self.call?.zoomFactor = factor
    }
    
    public func setCurrentSpokenLanguage(language: LanguageItem, completionHandler: @escaping (SpokenLanguageSelectionError?) -> Void) {
        call?.setCurrentSpokenLanguage(language: language, completionHandler: completionHandler)
    }
    
    public func setCurrentTranslationLanguage(language: LanguageItem, completionHandler: @escaping (TranslationLanguageSelectionError?) -> Void) {
        call?.setCurrentTranslationLanguage(language: language, completionHandler: completionHandler)
    }
    
    public func getClosedCaptions() -> [CaptionItem] {
        return call?.getClosedCaptions() ?? []
    }
    
    public func toggleClosedCaption(enable: Bool, completionHandler: @escaping (Bool) -> Void ) {
        call?.toggleClosedCaption(enable: enable, completionHandler: completionHandler)
    }
    
    public func getClosedCaptionsInfo() -> WebexSDK.ClosedCaptionsInfo? {
        guard let info = call?.getClosedCaptionsInfo() else { return nil }
        return info
    }
    
    public func enableWXA(isEnabled: Bool, callback:@escaping ((Bool)->Void)) -> Void {
        call?.wxa.enableWXA(isEnabled: isEnabled, callback: callback)
    }
    
    public func send(dtmfCode: String, completionHandler: ((Error?) -> Void)?) {
        call?.send(dtmf: dtmfCode, completionHandler: completionHandler)
    }
}

extension Call.BreakoutSession: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.sessionId)
    }
    
    public static func == (lhs: Call.BreakoutSession, rhs: Call.BreakoutSession) -> Bool {
        return lhs.sessionId == rhs.sessionId
    }
}
