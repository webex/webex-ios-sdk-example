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
import Toast_Swift

enum VideoCallRole {
    case CallPoster(String)
    case CallReceiver(String)
    case SpaceCallPoster(String, String)
}

class VideoCallViewController: BaseViewController,MultiStreamObserver {
    
    // MARK: - UI Outlets variables
    @IBOutlet private weak var disconnectionTypeLabel: UILabel!
    @IBOutlet private weak var hangupButton: UIButton!
    @IBOutlet private weak var dialpadButton: UIButton!
    @IBOutlet private weak var dialpadView: UICollectionView!
    @IBOutlet weak var loudSpeakerSwitch: UISwitch!
    @IBOutlet weak var frontCameraView: UIView!
    @IBOutlet weak var frontCameraImage: UIImageView!
    @IBOutlet weak var backCameraView: UIView!
    @IBOutlet weak var backCameraImage: UIImageView!
    @IBOutlet private weak var sendingVideoSwitch: UISwitch!
    @IBOutlet private weak var sendingAudioSwitch: UISwitch!
    @IBOutlet private weak var receivingVideoSwitch: UISwitch!
    @IBOutlet private weak var receivingAudioSwitch: UISwitch!
    @IBOutlet weak var screenShareSwitch: UISwitch!
    @IBOutlet weak var fullScreenButton: UIButton!
    @IBOutlet private weak var avatarContainerView: UIImageView!
    @IBOutlet private weak var remoteViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var selfViewWidth: NSLayoutConstraint!
    @IBOutlet private weak var selfViewHeight: NSLayoutConstraint!
    @IBOutlet weak var screenShareViewWidth: NSLayoutConstraint!
    @IBOutlet weak var screenShareViewHeight: NSLayoutConstraint!
    @IBOutlet var dialpadViewWidth: NSLayoutConstraint!
    @IBOutlet var dialpadViewHeight: NSLayoutConstraint!
    @IBOutlet var heightScaleCollection: [NSLayoutConstraint]!
    @IBOutlet var widthScaleCollection: [NSLayoutConstraint]!
    @IBOutlet var labelFontScaleCollection: [UILabel]!
    private var slideInView: UIView?
    private var slideInMsgLabel: UILabel?
    @IBOutlet weak var callFunctionTabBar: UITabBar!
    
    @IBOutlet weak var auxVideosContainerView: UIView!
    
    @IBOutlet weak var participantsTableView: UITableView!
    @IBOutlet weak var participantsView: UIView!
    
    @IBOutlet weak var callControlItem: UITabBarItem!
    
    @IBOutlet weak var auxiliaryStreamItem: UITabBarItem!
    
    @IBOutlet weak var participantsItem: UITabBarItem!
    
    @IBOutlet var auxVideoNameLabels: [UILabel]!
    @IBOutlet var auxVideoViews: [MediaRenderView]!
    @IBOutlet weak var callControlView: UIView!
    
    private var callStatus:CallStatus = .initiated
    private var isFullScreen: Bool = false
    private let avatarImageView = UIImageView()
    private var avatarImageViewHeightConstraint: NSLayoutConstraint!
    private let remoteDisplayNameLabel = UILabel()
    private let fullScreenImage = UIImage.fontAwesomeIcon(name: .expand, textColor: UIColor.white, size: CGSize.init(width: 44, height: 44))
    private let normalScreenImage = UIImage.fontAwesomeIcon(name: .compress, textColor: UIColor.white, size: CGSize.init(width: 44, height: 44))
    private static let uncheckImage = UIImage.fontAwesomeIcon(name: .square, type: .regular, textColor: UIColor.titleGreyColor(), size: CGSize.init(width: 33 * Utils.HEIGHT_SCALE, height: 33 * Utils.HEIGHT_SCALE))
    private static let checkImage = UIImage.fontAwesomeIcon(name: .checkSquare, type: .regular, textColor: UIColor.titleGreyColor(), size: CGSize.init(width: 33 * Utils.HEIGHT_SCALE, height: 33 * Utils.HEIGHT_SCALE))
    private var longPressRec1 : UILongPressGestureRecognizer?
    private var longPressRec2 : UILongPressGestureRecognizer?
    private var first: Bool = true
    // all the membership in the space
    private var participantArray: [CallMembership] = []
    // data source of table view, is 2-D array
    private var participantData: [[CallMembership]] = []
    private var personInfoArray: [Person] = []
    private var openedAuxViews: [MediaRenderView] = []
    private var auxiliaryVideoUI: [AuxiliaryStreamUICollection] = []
    
    override var navigationTitle: String? {
        get {
            return "Call status:\(self.title ?? "Unkonw")"
        }
        set(newValue) {
            title = newValue
            if let titleLabel = navigationItem.titleView as? UILabel {
                titleLabel.text = "Call status:\(self.title ?? "Unkonw")"
                titleLabel.sizeToFit()
                
            }
        }
    }
    override var prefersStatusBarHidden: Bool {
        get {
            return navigationController!.isNavigationBarHidden
        }
    }
    
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    /// videoCallRole represent if the call is posting call or reciving call
    var videoCallRole :VideoCallRole = VideoCallRole.CallReceiver("")
    
    /// MediaRenderView is an OpenGL backed UIView
    @IBOutlet private weak var selfView: MediaRenderView!
    
    /// MediaRenderView is an OpenGL backed UIView
    @IBOutlet private weak var remoteView: MediaRenderView!
    
    /// MediaRenderView is an OpenGL backed UIView
    @IBOutlet weak var screenShareView: MediaRenderView!
    
    
    /// saparkSDK reperesent for the WebexSDK API instance
    var webexSDK: Webex?
    
    /// currentCall represent current processing call instance
    var currentCall: Call?
    
    ///onAuxStreamChanged represent a call back when a existing auxiliary stream status changed.
    var onAuxStreamChanged: ((AuxStreamChangeEvent) -> Void)?
    
    ///onAuxStreamAvailable represent the call back when current call have a new auxiliary stream.
    var onAuxStreamAvailable: (() -> MediaRenderView?)?
    
    ///onAuxStreamUnavailable represent the call back when current call have an existing auxiliary stream being unavailable.
    var onAuxStreamUnavailable: (() -> MediaRenderView?)?
    
    // MARK: - Life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if first {
            switch videoCallRole {
            case .CallReceiver(let remoteAddress):
                self.didAnswerIncomingCall()
                self.setupAvatarView(remoteAddress)
                self.webexPersonWithEmailString(emailStr: remoteAddress)
            case .CallPoster(let remoteAddress):
                self.didDialWithRemoteAddress(remoteAddress)
                self.setupAvatarView(remoteAddress)
                self.webexPersonWithEmailString(emailStr: remoteAddress)
            case .SpaceCallPoster(let spaceId, let spaceName):
                self.didDialWithRemoteAddress(spaceId)
                self.setupAvatarView(spaceName)
            }
            first = false
        }
        self.updateUIStatus()
        /* WebexSDK: register callback functions for "Callstate" changing */
        self.webexCallStatesProcess()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (navigationController?.isNavigationBarHidden ?? false) == true {
            navigationController?.isNavigationBarHidden = false
        }
    }
    
    override func viewDidLayoutSubviews() {
        self.updateAvatarContainerView()
    }
    
    deinit {
        guard currentCall != nil else {
            return
        }
        // NOTE: Disconnects this call,Otherwise error will occur and completionHandler will be dispatched.
        self.currentCall?.hangup() { error in
            
        }
        self.currentCall = nil
    }
    
    // MARK: - WebexSDK: Dail/Answer/Hangup phone call
    func didDialWithRemoteAddress(_ remoteAddr: String) {
        if remoteAddr.isEmpty {
            return
        }
        
        /*
         audioVideo as making a Video call,audioOnly as making Voice only call.The default is audio call.
         */
        var mediaOption = MediaOption.audioOnly()
        if(globalVideoSetting.webexSDK == nil){
            globalVideoSetting.webexSDK = self.webexSDK
        }
        if globalVideoSetting.isVideoEnabled() {
            if #available(iOS 11.2, *) {
                mediaOption = MediaOption.audioVideoScreenShare(video: (self.self.selfView!, self.remoteView!), screenShare: nil, applicationGroupIdentifier: "group.com.cisco.webexsdk.KitchenSink")
            }
            else {
                mediaOption = MediaOption.audioVideoScreenShare(video: (self.self.selfView!, self.remoteView!))
            }
            self.webexSDK?.phone.videoMaxTxBandwidth = globalVideoSetting.txBandWidth
            self.webexSDK?.phone.videoMaxRxBandwidth = globalVideoSetting.rxBandWidth
        }
        self.callStatus = .initiated
        /* Makes a call to an intended recipient on behalf of the authenticated user.*/
        self.webexSDK?.phone.dial(remoteAddr, option: mediaOption) { [weak self] result in
            if let strongSelf = self {
                switch result {
                case .success(let call):
                    strongSelf.currentCall = call
                    strongSelf.webexCallStatesProcess()
                    strongSelf.showScreenShareView(call.remoteSendingScreenShare)
                case .failure(let error):
                    _ = strongSelf.navigationController?.popViewController(animated: true)
                    print("Dial call error: \(error)")
                }
                
                // self view init
                if globalVideoSetting.isVideoEnabled() && !globalVideoSetting.isSelfViewShow {
                    strongSelf.toggleSendingVideo(strongSelf.sendingVideoSwitch)
                }
            }
        }
    }
    
    func didAnswerIncomingCall() {
        
        var mediaOption = MediaOption.audioOnly()
        if globalVideoSetting.isVideoEnabled() {
            if #available(iOS 11.2, *) {
                mediaOption = MediaOption.audioVideoScreenShare(video: (self.self.selfView!, self.remoteView!), screenShare: nil, applicationGroupIdentifier: "group.com.cisco.webexsdk.KitchenSink")
            }
            else {
                mediaOption = MediaOption.audioVideoScreenShare(video: (self.self.selfView!, self.remoteView!))
            }
            self.webexSDK?.phone.videoMaxTxBandwidth = globalVideoSetting.txBandWidth
            self.webexSDK?.phone.videoMaxRxBandwidth = globalVideoSetting.rxBandWidth
        }
        
        if !globalVideoSetting.isSelfViewShow {
            self.sendingVideoSwitch.isOn = false
            self.showSelfView(sendingVideoSwitch.isOn)
        }
        
        if !globalVideoSetting.isLoudSpeaker {
            self.loudSpeakerSwitch.isOn = false
        }
        
        /*
         Answers this call.
         This can only be invoked when this call is incoming and in rining status.
         Otherwise error will occur and onError callback will be dispatched.
         */
        self.currentCall?.answer(option: mediaOption) { [weak self] error in
            if let strongSelf = self {
                if error != nil {
                    strongSelf.view.makeToast("Call statue error:\(error!)", duration: 2, position: ToastPosition.center, title: nil, image: nil, style: ToastStyle.init())
                    { bRet in
                        
                    }
                }
                else if strongSelf.currentCall?.remoteSendingScreenShare ?? false {
                    strongSelf.currentCall?.videoRenderViews = (strongSelf.selfView,strongSelf.screenShareView)
                    strongSelf.currentCall?.screenShareRenderView = strongSelf.remoteView
                }
            }
        }
        
    }
    func didHangUpCall(){
        self.slideInView?.removeFromSuperview()
        /* Disconnect a call. */
        self.currentCall?.hangup() { [weak self] error in
            if let strongSelf = self {
                if error != nil {
                    strongSelf.view.makeToast("Call statue error:\(error!)", duration: 2, position: ToastPosition.center, title: nil, image: nil, style: ToastStyle.init())
                    { bRet in
                        
                    }
                }
            }
        }
    }
    
    // MARK: - WebexSDK call state change processing code here...
    func webexCallStatesProcess() {
        if let call = self.currentCall {
            /* Callback when remote participant(s) is ringing. */
            call.onRinging = { [weak self] in
                if let strongSelf = self {
                    strongSelf.callStatus = .ringing
                    strongSelf.updateUIStatus()
                }
            }
            
            /* Callback when remote participant(s) answered and this *call* is connected. */
            call.onConnected = { [weak self] in
                if let strongSelf = self {
                    strongSelf.callStatus = .connected
                    strongSelf.updateUIStatus()
                    if globalVideoSetting.isVideoEnabled() && !globalVideoSetting.isSelfViewShow {
                        strongSelf.toggleSendingVideo(strongSelf.sendingVideoSwitch)
                    }
                    if self?.currentCall?.remoteSendingScreenShare ?? false {
                        strongSelf.currentCall?.videoRenderViews = (strongSelf.selfView,strongSelf.screenShareView)
                        strongSelf.currentCall?.screenShareRenderView = strongSelf.remoteView
                        strongSelf.showScreenShareView(true)
                    }
                }
                
            }
            
            
            /* Callback when this *call* is disconnected (hangup, cancelled, get declined or other self device pickup the call). */
            call.onDisconnected = {[weak self] disconnectionType in
                if let strongSelf = self {
                    strongSelf.callStatus = .disconnected
                    strongSelf.updateUIStatus()
                    strongSelf.navigationTitle = "Disconnected"
                    strongSelf.showDisconnectionType(disconnectionType)
                    strongSelf.presentCallRateVC()
                    strongSelf.slideInView?.removeFromSuperview()
                }
            }
            
            /* Callback when yourself is in lobby. */
            call.onWaiting = {[weak self] reason in
                if let strongSelf = self {
                    if reason == .meetingNotStart {
                        strongSelf.navigationTitle = "meeting not start"
                    }else {
                        strongSelf.navigationTitle = "waiting for admitting"
                    }
                }
            }
            
            /* Callback when remote participant(s) join/left/decline/inLobby connected. */
            call.onCallMembershipChanged = { [weak self] memberShipChangeType  in
                if let strongSelf = self {
                    switch memberShipChangeType {
                        /* This might be triggered when membership joined the call */
                    case .joined(let memberShip):
                        strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " joined")
                        break
                        /* This might be triggered when membership left the call */
                    case .left(let memberShip):
                        strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " left")
                        /* This might be triggered when membership declined the call */
                    case .declined(let memberShip):
                        strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " declined")
                        /* This might be triggered when membership mute/unmute the audio */
                    case .sendingAudio(let memberShip):
                        if memberShip.sendingAudio {
                            strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " unmute audio")
                        }
                        else {
                            strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " mute audio")
                        }
                        break
                        /* This might be triggered when membership mute/unmute the video */
                    case .sendingVideo(let memberShip):
                        if memberShip.sendingVideo {
                            strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " unmute video")
                        }
                        else {
                            strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " mute video")
                        }
                        break
                        /* This might be triggered when membership start/end the screen share */
                    case .sendingScreenShare(let memberShip):
                        if memberShip.sendingScreenShare {
                            strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " share screen")
                        }
                        else {
                            strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " stop share")
                        }
                        break
                        /* This might be triggered when membership is waiting in lobby */
                    case .waiting(let memberShip, _):
                        strongSelf.slideInStateView(slideInMsg: (memberShip.email ?? (memberShip.sipUrl ?? "Unknow membership")) + " inLobby")
                        break
                    }
                    self?.updateParticipantTable()
                }
            }
            
            /* Callback when the media types of this *call* have changed. */
            call.onMediaChanged = {[weak self] mediaChangeType in
                if let strongSelf = self {
                    print("remoteMediaDidChange Entering")
                    strongSelf.updateAvatarViewVisibility()
                    switch mediaChangeType {
                        
                        /* Local/Remote video rendering view size has changed */
                    case .localVideoViewSize,.remoteVideoViewSize:
                        break
                        /* This might be triggered when the remote party muted or unmuted the audio. */
                    case .remoteSendingAudio(let isSending):
                        strongSelf.receivingAudioSwitch.isOn = isSending
                        
                        /* This might be triggered when the remote party muted or unmuted the video. */
                    case .remoteSendingVideo(let isSending):
                        strongSelf.receivingVideoSwitch.isOn = isSending
                        
                        /* This might be triggered when the local party muted or unmuted the video. */
                    case .sendingAudio(let isSending):
                        strongSelf.sendingAudioSwitch.isOn = isSending
                        
                        /* This might be triggered when the local party muted or unmuted the aideo. */
                    case .sendingVideo(let isSending):
                        strongSelf.sendingVideoSwitch.isOn = isSending
                        
                        /* Camera FacingMode on local device has switched. */
                    case .cameraSwitched:
                        strongSelf.updateCheckBoxStatus()
                        
                        /* Whether loud speaker on local device is on or not has switched. */
                    case .spearkerSwitched:
                        strongSelf.loudSpeakerSwitch.isOn = call.isSpeaker
                        
                        /* Whether Screen share is blocked by local*/
                    case .receivingScreenShare(let isReceiving):
                        self?.showScreenShareView(isReceiving)
                        break
                        
                        /* Whether Remote began to send Screen share */
                    case .remoteSendingScreenShare(let startedSending):
                        if startedSending {
                            strongSelf.currentCall?.videoRenderViews = (strongSelf.selfView, strongSelf.screenShareView)
                            strongSelf.currentCall?.screenShareRenderView = strongSelf.remoteView
                        }
                        else {
                            strongSelf.currentCall?.screenShareRenderView = nil
                            strongSelf.currentCall?.videoRenderViews = (strongSelf.selfView, strongSelf.remoteView)
                        }
                        strongSelf.showScreenShareView(startedSending)
                        
                        break
                        /* Whether local began to send Screen share */
                    case .sendingScreenShare(let startedSending):
                        strongSelf.screenShareSwitch.isOn = startedSending
                        /* This might be triggered when the remote video's speaker has changed.
                         */
                    case .activeSpeakerChangedEvent(_,_):
                        strongSelf.updateActiveSpeakerView()
                        break
                    default:
                        break
                    }
                    print("remoteMediaDidChange out")
                }
            }
            
            
            /* when the iOS broadcasting status of this *call* have changed */
            call.oniOSBroadcastingChanged = {
                event in
                if #available(iOS 11.2, *) {
                    switch event {
                    case .extensionConnected :
                        if !(self.currentCall?.sendingScreenShare ?? false) {
                            let alert = UIAlertController(title: "Share Screen", message: "KitchenSink will start capturing ereryting that's displayed on your screen.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Start Now", style: .default, handler: {
                                alert in
                                self.currentCall?.startSharing() {
                                    error in
                                    if error != nil {
                                        print("share screen error:\(String(describing: error))")
                                    }
                                }
                            }))
                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                        break
                    case .extensionDisconnected:
                        print("share screen stop broadcasting")
                        break
                    }
                    
                }
                
            }
            
            /* set the observer of this call to get multi stream event */
            call.multiStreamObserver = self
            
            /* Callback when a new multi stream media being available. Return a MediaRenderView let the SDK open it automatically. Return nil if you want to open it by call the API:openAuxStream(view: MediaRenderView) later.*/
            self.onAuxStreamAvailable = { [weak self] in
                if let strongSelf = self {
                    strongSelf.updateBadgeValue()
                    if let auxUI = strongSelf.auxiliaryVideoUI.filter({!$0.inUse}).first {
                        auxUI.inUse = true
                        return auxUI.mediaRenderView
                    }
                }
                return nil
            }
            
            /* Callback when an existing multi stream media being unavailable. The SDK will close the last auxiliary stream if you don't return the specified view*/
            self.onAuxStreamUnavailable = { [weak self] in
                if let strongSelf = self {
                    strongSelf.updateBadgeValue()
                    if let auxUI = strongSelf.auxiliaryVideoUI.filter({$0.inUse}).last {
                        auxUI.inUse = false
                        return auxUI.mediaRenderView
                    }
                }
                return nil
            }
            
            /* Callback when an existing multi stream media changed*/
            self.onAuxStreamChanged = { [weak self] event in
                if let strongSelf = self {
                    switch event {
                        /* Callback for open an auxiliary stream results*/
                    case .auxStreamOpenedEvent(let view, let result):
                        switch result {
                        case .success(let auxStream):
                            strongSelf.openedAuxiliaryUI(view: view, auxStream: auxStream)
                        case .failure(let error):
                            print("========\(error)=====")
                        }
                        /* This might be triggered when the auxiliary stream's speaker has changed.
                         */
                    case .auxStreamPersonChangedEvent(let auxStream,_,_):
                        strongSelf.updateAuxiliaryUIBy(auxStream:auxStream)
                        /* This might be triggered when the speaker muted or unmuted the video. */
                    case .auxStreamSendingVideoEvent(let auxStream):
                        strongSelf.updateAuxiliaryUIBy(auxStream: auxStream)
                        /* This might be triggered when the speaker's video rendering view size has changed. */
                    case .auxStreamSizeChangedEvent(let auxStream):
                        print("Auxiliary stream size changed:\(auxStream.auxStreamSize)")
                        break
                        /* Callback for close an auxiliary stream results*/
                    case .auxStreamClosedEvent(let view, let error):
                        if error == nil {
                            strongSelf.closedAuxiliaryUI(view: view)
                        } else {
                            print("=====auxStreamClosedEvent error:\(String(describing: error))")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - WebexSDK fetch Person Info
    private func webexPersonWithEmailString(emailStr: String){
        if let emailAddress = EmailAddress.fromString(emailStr) {
            /*
             Person list is empty with SIP email address
             Lists people in the authenticated user's organization.
             */
            self.webexSDK?.people.list(email: emailAddress, max: 1) { response in
                var persons: [Person] = []
                
                switch response.result {
                case .success(let value):
                    persons = value
                    if let person = persons.first {
                        self.saveCallPersonHistory(person: person)
                    }
                case .failure(let error):
                    print("ERROR: \(error)")
                }
            }
        } else {
            print("could not parse email address \(emailStr) for retrieving user profile")
        }
    }
    
    // MARK: Xib file IBActions
    @IBAction private func toggleLoudSpeaker(_ sender: AnyObject) {
        // True if the loud speaker is selected as the audio output device for this *call*. Otherwise, false.
        self.currentCall?.isSpeaker = loudSpeakerSwitch.isOn
    }
    
    @IBAction private func toggleSendingVideo(_ sender: AnyObject) {
        // True if the local party of this *call* is sending video. Otherwise, false.
        self.currentCall?.sendingVideo = sendingVideoSwitch.isOn
        self.showSelfView(sendingVideoSwitch.isOn)
    }
    
    @IBAction private func toggleSendingAudio(_ sender: AnyObject) {
        // True if this *call* is sending audio. Otherwise, false.
        self.currentCall?.sendingAudio = sendingAudioSwitch.isOn
    }
    
    @IBAction private func toggleReceivingVideo(_ sender: AnyObject) {
        // True if the local party of this *call* is receiving video. Otherwise, false.
        self.currentCall?.receivingVideo = receivingVideoSwitch.isOn
        self.updateAvatarViewVisibility()
    }
    
    @IBAction private func toggleReceivingAudio(_ sender: AnyObject) {
        // True if the local party of this *call* is receiving audio. Otherwise, false.
        self.currentCall?.receivingAudio = receivingAudioSwitch.isOn
    }
    
    @IBAction func fullScreenButtonTouchUpInside(_ sender: Any) {
        isFullScreen = !isFullScreen
        if isFullScreen {
            self.fullScreenPortrait(UIScreen.main.bounds.height)
        }
        else {
            self.normalSizePortrait()
            
        }
    }
    
    @IBAction func pressDialpadButton(_ sender: AnyObject) {
        self.hideDialpadView(!dialpadView.isHidden)
    }
    
    @IBAction private func hangUpBtnClicked(_ sender: AnyObject) {
        self.didHangUpCall()
    }
    
    @IBAction func toggleScreenShare(_ sender: Any) {

        if #available(iOS 11.2, *) {
            if screenShareSwitch.isOn {
                if #available(iOS 12.0, *) {
                    let broadcastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
                    broadcastPicker.preferredExtension =  "com.cisco.webexsdk.KitchenSink.KitchenSinkBroadcastExtension"
                    for subview in broadcastPicker.subviews {
                        if let button = subview as? UIButton {
                            button.sendActions(for: .allTouchEvents)
                        }
                    }
                }
                self.currentCall?.startSharing() {
                    error in
                    print("ERROR: \(String(describing: error))")
                }
            } else {
                self.currentCall?.stopSharing() {
                    error in
                    print("ERROR: \(String(describing: error))")
                }
            }
        } else {
            screenShareSwitch.isOn = false
            self.view.makeToast("Screen share only available in iOS 11.2 and higher", duration: 2, position: ToastPosition.center, title: nil, image: nil, style: ToastStyle.init())
        }
    }
    
    // MARK: - UI Implementation
    override func initView() {
        for label in labelFontScaleCollection {
            label.font = UIFont.labelLightFont(ofSize: label.font.pointSize * Utils.HEIGHT_SCALE)
        }
        for heightConstraint in heightScaleCollection {
            heightConstraint.constant *= Utils.HEIGHT_SCALE
        }
        for widthConstraint in widthScaleCollection {
            widthConstraint.constant *= Utils.WIDTH_SCALE
        }
        
        fullScreenButton.setBackgroundImage(fullScreenImage, for: .normal)
        
        //checkbox init
        var tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(handleCapGestureEvent(sender:)))
        self.frontCameraView.addGestureRecognizer(tapGesture)
        
        tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(handleCapGestureEvent(sender:)))
        self.backCameraView.addGestureRecognizer(tapGesture)
        
        //tab bar image
        self.participantsItem.image =
            UIImage.fontAwesomeIcon(name: .users, textColor: UIColor.labelGreyColor(), size: CGSize.init(width: 32*Utils.WIDTH_SCALE, height: 32*Utils.HEIGHT_SCALE))
        self.participantsItem.selectedImage =
            UIImage.fontAwesomeIcon(name: .users, textColor: UIColor.buttonBlueHightlight(), size: CGSize.init(width: 32*Utils.WIDTH_SCALE, height: 32*Utils.HEIGHT_SCALE))
        self.callControlItem.image =
            UIImage.fontAwesomeIcon(name: .cogs, textColor: UIColor.labelGreyColor(), size: CGSize.init(width: 32*Utils.WIDTH_SCALE, height: 32*Utils.HEIGHT_SCALE))
        self.callControlItem.selectedImage =
            UIImage.fontAwesomeIcon(name: .cogs, textColor: UIColor.buttonBlueHightlight(), size: CGSize.init(width: 32*Utils.WIDTH_SCALE, height: 32*Utils.HEIGHT_SCALE))
        self.auxiliaryStreamItem.image =
            UIImage.fontAwesomeIcon(name: .fileVideo, type: .regular, textColor: UIColor.labelGreyColor(), size: CGSize.init(width: 32*Utils.WIDTH_SCALE, height: 32*Utils.HEIGHT_SCALE))
        self.auxiliaryStreamItem.selectedImage =
            UIImage.fontAwesomeIcon(name: .fileVideo, type: .regular, textColor: UIColor.buttonBlueHightlight(), size: CGSize.init(width: 32*Utils.WIDTH_SCALE, height: 32*Utils.HEIGHT_SCALE))
        
        callFunctionTabBar.delegate = self
        self.participantsTableView.dataSource = self
        self.participantsTableView.delegate = self
        self.participantsTableView.allowsSelection = true
        self.callFunctionTabBar.selectedItem = callControlItem
        
        for index in 0..<self.auxVideoViews.count {
            self.auxiliaryVideoUI.append(AuxiliaryStreamUICollection.init(nameLabel: auxVideoNameLabels[index],mediaRenderView: auxVideoViews[index]))
        }
    }
    
    func updateCheckBoxStatus() {
        guard globalVideoSetting.isVideoEnabled() != false else {
            self.backCameraImage.image = VideoCallViewController.uncheckImage
            self.frontCameraImage.image = VideoCallViewController.uncheckImage
            return
        }
        
        if let isFacingMode =  self.currentCall?.facingMode {
            if isFacingMode == .user {
                self.backCameraImage.image = VideoCallViewController.uncheckImage
                self.frontCameraImage.image = VideoCallViewController.checkImage
            }
            else {
                self.backCameraImage.image = VideoCallViewController.checkImage
                self.frontCameraImage.image = VideoCallViewController.uncheckImage
            }
        }
        else if globalVideoSetting.facingMode == .user {
            self.backCameraImage.image = VideoCallViewController.uncheckImage
            self.frontCameraImage.image = VideoCallViewController.checkImage
        }
        else {
            self.backCameraImage.image = VideoCallViewController.checkImage
            self.frontCameraImage.image = VideoCallViewController.uncheckImage
        }
    }
    
    
    private func setupAvatarView(_ remoteAddr: String) {
        self.avatarImageView.image = UIImage(named: "DefaultAvatar")
        self.avatarImageView.layer.masksToBounds = true
        self.avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        self.remoteDisplayNameLabel.text = remoteAddr
        self.remoteDisplayNameLabel.font = UIFont.labelLightFont(ofSize: 17 * Utils.HEIGHT_SCALE)
        self.remoteDisplayNameLabel.textColor = UIColor.white
        self.remoteDisplayNameLabel.textAlignment = NSTextAlignment.center
        self.remoteDisplayNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.avatarContainerView.addSubview(avatarImageView)
        self.avatarContainerView.addSubview(remoteDisplayNameLabel)
        
        
        let avatarImageViewCenterXConstraint = NSLayoutConstraint.init(item: avatarImageView, attribute: .centerX, relatedBy: .equal, toItem: avatarContainerView, attribute: .centerX, multiplier: 1, constant: 0)
        let avatarImageViewCenterYConstraint = NSLayoutConstraint.init(item: avatarImageView, attribute: .centerY, relatedBy: .equal, toItem: avatarContainerView, attribute: .centerY, multiplier: 1, constant: -(remoteViewHeight.constant/3/4))
        
        self.avatarImageViewHeightConstraint = NSLayoutConstraint.init(item: avatarImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: remoteViewHeight.constant/3)
        let avatarImageViewWidthConstraint = NSLayoutConstraint.init(item: avatarImageView, attribute: .width, relatedBy: .equal, toItem: avatarImageView, attribute: .height, multiplier: 1, constant: 0)
        
        let remoteDisplayNameLabelLeadingConstraint = NSLayoutConstraint.init(item: remoteDisplayNameLabel, attribute: .leading, relatedBy: .equal, toItem: avatarContainerView, attribute: .leading, multiplier: 1, constant: 0)
        let remoteDisplayNameLabelTrailingConstraint = NSLayoutConstraint.init(item: remoteDisplayNameLabel, attribute: .trailing, relatedBy: .equal, toItem: avatarContainerView, attribute: .trailing, multiplier: 1, constant: 0)
        let remoteDisplayNameLabelHeightConstraint = NSLayoutConstraint.init(item: remoteDisplayNameLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 21 * Utils.HEIGHT_SCALE)
        let remoteDisplayNameLabelTopConstraint = NSLayoutConstraint.init(item: remoteDisplayNameLabel, attribute: .top, relatedBy: .equal, toItem: avatarImageView, attribute: .bottom, multiplier: 1, constant: 15 * Utils.HEIGHT_SCALE)
        
        self.remoteDisplayNameLabel.addConstraint(remoteDisplayNameLabelHeightConstraint)
        
        self.avatarContainerView.addConstraint(avatarImageViewCenterXConstraint)
        self.avatarContainerView.addConstraint(avatarImageViewCenterYConstraint)
        self.avatarContainerView.addConstraint(remoteDisplayNameLabelLeadingConstraint)
        self.avatarContainerView.addConstraint(remoteDisplayNameLabelTrailingConstraint)
        self.avatarContainerView.addConstraint(remoteDisplayNameLabelTopConstraint)
        self.avatarImageView.addConstraint(avatarImageViewHeightConstraint)
        self.avatarImageView.addConstraint(avatarImageViewWidthConstraint)
        
        view.setNeedsUpdateConstraints()
        
        self.slideInViewSetUp()
    }
    
    private func saveCallPersonHistory(person: Person){
        //record this person in call history
        UserDefaultsUtil.addPersonHistory(person)
        self.remoteDisplayNameLabel.text = person.emails?[0].toString()
        if let displayName = person.displayName {
            self.remoteDisplayNameLabel.text = displayName
        }
        if let avatarUrl = person.avatar {
            self.fetchAvatarImage(avatarUrl)
        }
    }
    
    private func fetchAvatarImage(_ avatarUrl: String) {
        Utils.downloadAvatarImage(avatarUrl) { [weak self] avatarImage in
            if let strongSelf = self {
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
                    strongSelf.avatarImageView.alpha = 1
                    strongSelf.avatarImageView.alpha = 0.1
                    strongSelf.view.layoutIfNeeded()
                }, completion: { [weak self] finished in
                    if let strongSelf = self {
                        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
                            strongSelf.avatarImageView.image = avatarImage
                            strongSelf.avatarImageView.alpha = 1
                            strongSelf.view.layoutIfNeeded()
                        }, completion: nil)
                    }
                })
            }
        }
    }
    
    private func updateAvatarViewVisibility() {
        guard self.currentCall != nil else {
            return
        }
        if !isCallConnected() {
            self.showAvatarContainerView(true)
            return
        }
        
        if !(self.currentCall!.receivingVideo)
            || (!self.currentCall!.remoteSendingVideo && !self.currentCall!.remoteSendingScreenShare)
        {
            self.showAvatarContainerView(true)
        } else {
            self.showAvatarContainerView(false)
        }
    }
    
    private func updateUIStatus() {
        DispatchQueue.main.async {
            self.updateStatusLabel()
            self.updateSwitches()
            self.updateAvatarViewVisibility()
            self.hideDialpadButton(false)
            self.hideDialpadView(true)
            self.updateSelfViewVisibility()
            self.showScreenShareView(self.currentCall?.remoteSendingScreenShare ?? false)
            if self.isCallDisconnected() {
                self.hideCallView()
            }
            self.updateParticipantTable()
        }
        
    }
    
    private func updateStatusLabel() {
        switch callStatus {
        case .connected:
            navigationTitle = "Connected"
        case .disconnected:
            navigationTitle = "Disconnected"
        case .initiated:
            navigationTitle = "Initiated"
        case .ringing:
            navigationTitle = "Ringing"
        case .waiting:
            navigationTitle = "In Lobby"
        }
    }
    
    private func showDisconnectionType(_ type: Call.DisconnectReason) {
        var disconnectionTypeString = ""
        switch type {
        case .localCancel:
            disconnectionTypeString = "local cancel"
        case .localDecline:
            disconnectionTypeString = "local decline"
        case .localLeft:
            disconnectionTypeString = "local left"
        case .otherConnected:
            disconnectionTypeString = "other connected"
        case .otherDeclined:
            disconnectionTypeString = "other declined"
        case .remoteCancel:
            disconnectionTypeString = "remote cancel"
        case .remoteDecline:
            disconnectionTypeString = "remote decline"
        case .remoteLeft:
            disconnectionTypeString = "remote left"
        case .error(let error):
            disconnectionTypeString = "error: \(error)"
        }
        
        self.disconnectionTypeLabel.text = disconnectionTypeLabel.text! + disconnectionTypeString
        self.view.bringSubviewToFront(self.disconnectionTypeLabel)
        self.disconnectionTypeLabel.isHidden = false
    }
    
    private func updateSwitches() {
        self.updateCheckBoxStatus()
        self.loudSpeakerSwitch.isOn = self.currentCall?.isSpeaker ?? globalVideoSetting.isLoudSpeaker
        self.sendingVideoSwitch.isOn = self.currentCall?.sendingVideo ?? globalVideoSetting.isSelfViewShow
        self.sendingAudioSwitch.isOn = self.currentCall?.sendingAudio ?? true
        self.receivingVideoSwitch.isOn = self.currentCall?.receivingVideo ?? true
        self.receivingAudioSwitch.isOn = self.currentCall?.receivingAudio ?? true
        self.screenShareSwitch.isOn = self.currentCall?.sendingScreenShare ?? false
        
        if !globalVideoSetting.isVideoEnabled() {
            self.frontCameraView.isUserInteractionEnabled = false
            self.backCameraView.isUserInteractionEnabled = false
            self.sendingVideoSwitch.isOn = false
            self.receivingVideoSwitch.isOn = false
            self.sendingVideoSwitch.isEnabled = false
            self.receivingVideoSwitch.isEnabled = false
        }
        else {
            self.frontCameraView.isUserInteractionEnabled = true
            self.backCameraView.isUserInteractionEnabled = true
        }
    }
    
    private func updateSelfViewVisibility() {
        self.showSelfView(self.currentCall?.sendingVideo ?? false)
    }
    
    private func hideCallView() {
        self.showSelfView(false)
        self.hideControlView(true)
    }
    
    private func showSelfView(_ shown: Bool) {
        self.selfView.isHidden = !shown
    }
    
    private func showScreenShareView( _ shown: Bool){
        self.screenShareView.isHidden = !shown
    }
    
    private func showCallFunctionViews() {
        if self.isCallDisconnected() {
            self.callControlView.isHidden = true
            self.participantsView.isHidden = true
            self.auxVideosContainerView.isHidden = true
            self.callFunctionTabBar.isHidden = true
        } else {
            if self.callFunctionTabBar.selectedItem?.tag == TabBarItemType.callControl.rawValue {
                self.view.bringSubviewToFront(self.callControlView)
                self.callControlView.isHidden = false
                self.participantsView.isHidden = true
                self.auxVideosContainerView.isHidden = true
            } else if self.callFunctionTabBar.selectedItem?.tag == TabBarItemType.auxiliaryVide.rawValue {
                self.view.bringSubviewToFront(self.auxVideosContainerView)
                self.callControlView.isHidden = true
                self.participantsView.isHidden = true
                self.auxVideosContainerView.isHidden = false
            } else if self.callFunctionTabBar.selectedItem?.tag == TabBarItemType.participants.rawValue {
                self.view.bringSubviewToFront(self.participantsView)
                self.callControlView.isHidden = true
                self.participantsView.isHidden = false
                self.auxVideosContainerView.isHidden = true
            }
            
            self.hideDialpadButton(false)
            self.callFunctionTabBar.isHidden = false
        }
    }
    
    private func hideCallFunctionViews() {
        self.callControlView.isHidden = true
        self.participantsView.isHidden = true
        self.auxVideosContainerView.isHidden = true
        self.callFunctionTabBar.isHidden = true
        self.hideDialpadButton(true)
    }
    
    private func showAvatarContainerView(_ shown: Bool) {
        DispatchQueue.main.async {
            self.avatarContainerView.isHidden = !shown
        }
    }
    
    private func hideDialpadView(_ hidden: Bool) {
        self.dialpadView.isHidden = hidden
    }
    
    private func hideDialpadButton(_ hidden: Bool) {
        self.dialpadButton.isHidden = hidden
        if hidden {
            self.hideDialpadView(true)
        }
    }
    
    private func presentCallRateVC() {
        let callRateVC = storyboard?.instantiateViewController(withIdentifier: "CallFeedbackViewController") as? CallRateViewController
        callRateVC?.modalPresentationStyle = .fullScreen
        callRateVC?.modalTransitionStyle = .coverVertical
        
        /// sending current call to callRateVC
        callRateVC?.finishedCall = self.currentCall
        present(callRateVC!, animated: true, completion: nil)
    }
    
    private func showEndCallAlert() {
        let alert = UIAlertController(title: nil, message: "Do you want to end current call?", preferredStyle: .alert)
        
        let endCallHandler = {
            (action: UIAlertAction!) in
            alert.dismiss(animated: true, completion: nil)
            self.currentCall?.hangup() { error in
                
            }
            _ = self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "End call", style: .default, handler: endCallHandler))
        present(alert, animated: true, completion: nil)
    }
    
    override func goBack() {
        if self.isCallDisconnected() {
            _ = navigationController?.popViewController(animated: true)
        } else {
            self.showEndCallAlert()
        }
    }
    
    @objc func handleCapGestureEvent(sender:UITapGestureRecognizer) {
        // Switch the camera facing mode selected for this *call*.
        if let view = sender.view {
            if view == frontCameraView {
                if  self.currentCall?.facingMode != .user {
                    self.currentCall?.facingMode = .user
                }
                
            }
            else if view == backCameraView {
                if  self.currentCall?.facingMode != .environment {
                    self.currentCall?.facingMode = .environment
                }
            }
            self.updateCheckBoxStatus()
        }
    }
    
    private func isFacingModeUser(_ mode: Phone.FacingMode) -> Bool {
        return mode == .user
    }
    
    private func isCallConnected() -> Bool {
        return callStatus == .connected
    }
    
    private func isCallDisconnected() -> Bool {
        return callStatus == .disconnected
    }
    
    private func updateParticipantTable() {
        DispatchQueue.main.async {
            self.participantArray = self.currentCall?.memberships ?? []
            
            var inMeeting = [CallMembership]()
            var inLobby = [CallMembership]()
            var notInMeeting = [CallMembership]()
            self.participantArray.forEach { (callMembership) in
                if callMembership.state == .joined {
                    inMeeting.append(callMembership)
                }
                else if callMembership.state == .waiting {
                    inLobby.append(callMembership)
                }
                else {
                    notInMeeting.append(callMembership)
                }
            }
            let array:[Array<CallMembership>] = [inMeeting, inLobby, notInMeeting]
            self.participantData = array.filter({$0.count > 0})
            
            self.participantsTableView.reloadData()
        }
    }
    
    private func updateActiveSpeakerView() {
        DispatchQueue.main.async {
            self.participantsTableView.reloadData()
        }
    }
    
    private func openedAuxiliaryUI(view:MediaRenderView,auxStream:AuxStream) {
        if let auxiliaryUI = self.auxiliaryVideoUI.filter({$0.mediaRenderView == view }).first {
            auxiliaryUI.auxStream = auxStream
            self.updateAuxiliaryUIBy(auxStream: auxStream)
        }
    }
    
    private func closedAuxiliaryUI(view:MediaRenderView) {
        if let auxiliaryUI = self.auxiliaryVideoUI.filter({$0.mediaRenderView == view }).first {
            auxiliaryUI.auxStream = nil
        }
    }
    
    private func updateAuxiliaryUIBy(auxStream:AuxStream) {
        if let auxiliaryUI = self.auxiliaryVideoUI.filter({ $0.mediaRenderView == auxStream.renderView }).first {
            if let fetchedPerson = self.personInfoArray.filter({$0.id == auxStream.person?.personId}).first {
                auxiliaryUI.update(person: fetchedPerson)
            } else if let personId = auxStream.person?.personId {
                self.webexSDK?.people.get(personId: personId) { [weak self] response in
                    if self != nil {
                        switch response.result {
                        case .success(let person):
                            auxiliaryUI.update(person: person)
                            self?.personInfoArray.append(person)
                        case .failure:
                            print("======get person info failure=======")
                            break
                        }
                    }
                }
            } else {
                auxiliaryUI.update(person: nil)
            }
        }
    }
    
    func updateBadgeValue() {
        if let auxStreamCount = self.currentCall?.availableAuxStreamCount, auxStreamCount != 0 {
            self.auxiliaryStreamItem.badgeValue = String(auxStreamCount)
        } else {
            self.auxiliaryStreamItem.badgeValue = nil
        }
        
        self.participantsItem.badgeValue = self.participantArray.count == 0 ? nil:String(self.participantArray.filter{$0.state == .joined || $0.state == .waiting}.count)
    }
    
    // MARK: Slide In View SetUp
    private func slideInViewSetUp(){
        if(self.slideInView == nil){
            self.slideInView = UIView(frame: CGRect(x:0,y:-64,width:(UIApplication.shared.keyWindow?.bounds.width)!,height: 64))
            self.slideInView?.backgroundColor = UIColor.buttonBlueNormal()
            UIApplication.shared.keyWindow?.addSubview(self.slideInView!)
            
            self.slideInMsgLabel = UILabel(frame: CGRect(x: 0, y: 20, width: (UIApplication.shared.keyWindow?.bounds.width)!, height: 40))
            self.slideInMsgLabel?.text = ""
            self.slideInMsgLabel?.font = UIFont.navigationBoldFont(ofSize: 18)
            self.slideInMsgLabel?.textColor = UIColor.white
            self.slideInMsgLabel?.textAlignment = .center
            self.slideInView?.isHidden = true
            self.slideInView?.addSubview(self.slideInMsgLabel!)
            
        }
    }
    
    private func slideInStateView(slideInMsg: String){
        self.slideInView?.isHidden = false
        self.slideInMsgLabel?.text = slideInMsg
        UIView.animate(withDuration: 0.25, animations: {
            self.slideInView?.transform = CGAffineTransform.init(translationX: 0, y: 64)
        }) { (_) in
            UIView.animate(withDuration: 0.25, delay: 1.5, options: .curveEaseInOut, animations: {
                self.slideInView?.transform = CGAffineTransform.init(translationX: 0, y: 0)
            }, completion: { (_) in
                self.slideInView?.isHidden = true
            })
        }
    }
    
    // MARK: - Orientation manage
    private func fullScreenLandscape(_ height:CGFloat) {
        self.remoteViewHeight.constant = height
        self.selfViewWidth.constant = 100 * Utils.HEIGHT_SCALE
        self.selfViewHeight.constant = 70 * Utils.WIDTH_SCALE
        self.screenShareViewWidth.constant = 150 * Utils.HEIGHT_SCALE
        self.screenShareViewHeight.constant = 100 * Utils.WIDTH_SCALE
        self.slideInView?.frame = CGRect(x:0,y:-64,width:(UIApplication.shared.keyWindow?.bounds.height)!,height: 64)
        self.slideInMsgLabel?.frame = CGRect(x: 0, y: 20, width: (UIApplication.shared.keyWindow?.bounds.height)!, height: 40)
        self.slideInView?.center = CGPoint(x: (UIApplication.shared.keyWindow?.bounds.midY)!, y: -32.0)
        self.hideControlView(true)
        self.fullScreenButton.isHidden = true
        self.addMoveReconizerOnSelfViewAndScreenShareView()
    }
    private func fullScreenPortrait(_ height:CGFloat) {
        self.remoteViewHeight.constant = height
        self.selfViewWidth.constant = 70 * Utils.WIDTH_SCALE
        self.selfViewHeight.constant = 100 * Utils.HEIGHT_SCALE
        self.screenShareViewWidth.constant = 150 * Utils.HEIGHT_SCALE
        self.screenShareViewHeight.constant = 100 * Utils.WIDTH_SCALE
        self.slideInView?.frame = CGRect(x:0,y:-64,width:(UIApplication.shared.keyWindow?.bounds.height)!,height: 64)
        self.slideInMsgLabel?.frame = CGRect(x: 0, y: 20, width: (UIApplication.shared.keyWindow?.bounds.height)!, height: 40)
        self.hideControlView(true)
        self.fullScreenButton.isHidden = false
        self.fullScreenButton.setBackgroundImage(normalScreenImage, for: .normal)
        self.addMoveReconizerOnSelfViewAndScreenShareView()
    }
    
    private func normalSizePortrait() {
        self.remoteViewHeight.constant = 210 * Utils.HEIGHT_SCALE
        self.selfViewWidth.constant = 70 * Utils.WIDTH_SCALE
        self.selfViewHeight.constant = 100 * Utils.HEIGHT_SCALE
        self.screenShareViewWidth.constant = 150 * Utils.HEIGHT_SCALE
        self.screenShareViewHeight.constant = 100 * Utils.WIDTH_SCALE
        self.slideInView?.frame = CGRect(x:0,y:-64,width:(UIApplication.shared.keyWindow?.bounds.width)!,height: 64)
        self.slideInMsgLabel?.frame = CGRect(x: 0, y: 20, width: (UIApplication.shared.keyWindow?.bounds.width)!, height: 40)
        self.hideControlView(false)
        self.fullScreenButton.isHidden = false
        self.fullScreenButton.setBackgroundImage(fullScreenImage, for: .normal)
        if let reconizer = self.longPressRec1{
            selfView.removeGestureRecognizer(reconizer)
            self.longPressRec1 = nil
        }
        if let reconizer = self.longPressRec2{
            screenShareView.removeGestureRecognizer(reconizer)
            self.longPressRec2 = nil
        }
        
    }
    
    private func hideControlView(_ isHidden: Bool) {
        self.fullScreenButton.isHidden = UIDevice.current.orientation.isLandscape
        if isHidden {
            self.hideCallFunctionViews()
        } else {
            self.showCallFunctionViews()
        }
        if self.isCallDisconnected() && !UIDevice.current.orientation.isLandscape {
            navigationController?.isNavigationBarHidden = false
        } else {
            navigationController?.isNavigationBarHidden = isHidden
        }
        
        if self.isCallDisconnected() {
            self.disconnectionTypeLabel.isHidden = false
        } else {
            self.disconnectionTypeLabel.isHidden = true
        }
    }
    
    private func addMoveReconizerOnSelfViewAndScreenShareView(){
        if(self.longPressRec1 == nil){
            self.longPressRec1 = UILongPressGestureRecognizer(target: self, action: #selector(selfViewMoved))
            self.longPressRec1?.minimumPressDuration = 0.05
            self.selfView.addGestureRecognizer(self.longPressRec1!)
        }
        
        if(self.longPressRec2 == nil){
            self.longPressRec2 = UILongPressGestureRecognizer(target: self, action: #selector(screenViewMoved))
            self.longPressRec2?.minimumPressDuration = 0.05
            self.screenShareView.addGestureRecognizer(self.longPressRec2!)
        }
    }
    
    @objc func selfViewMoved(recognizer: UILongPressGestureRecognizer){
        let point = recognizer.location(in: self.view)
        if(recognizer.state == .began){
            self.selfView.center = point
        }else if(recognizer.state == .changed){
            self.selfView.center = point
        }else if(recognizer.state == .ended){
            
        }
    }
    
    @objc func screenViewMoved(recognizer: UILongPressGestureRecognizer){
        let point = recognizer.location(in: self.view)
        if(recognizer.state == .began){
            self.screenShareView.center = point
        }else if(recognizer.state == .changed){
            self.screenShareView.center = point
        }else if(recognizer.state == .ended){
            
        }
    }
    
    // MARK: Landscape
    private func viewOrientationChange(_ isLandscape:Bool,with size:CGSize) {
        if isLandscape {
            self.fullScreenLandscape(size.height)
            self.isFullScreen = true
        }
        else if isFullScreen {
            fullScreenPortrait(size.height)
        }
        else {
            normalSizePortrait()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.viewOrientationChange(UIDevice.current.orientation.isLandscape,with:size)
        self.updateAvatarContainerView()
    }
    
    private func updateAvatarContainerView() {
        self.avatarImageViewHeightConstraint.constant = remoteViewHeight.constant/3
        self.avatarImageView.layer.cornerRadius = avatarImageViewHeightConstraint.constant/2
    }
    
    //MARK: - Auxiliary UI class(views container and update method)
    private class AuxiliaryStreamUICollection {
        
        let nameLabel: UILabel
        let mediaRenderView: MediaRenderView
        let noVideoView: UIView
        var avatarImageView: UIImageView
        var auxStream: AuxStream? {
            didSet {
                if auxStream == nil {
                    cleanUp()
                }
            }
        }
    
        var inUse: Bool = false
        
        private var currentPerson: Person?
        private var currentAvatar: UIImage?
        
        init(nameLabel: UILabel, mediaRenderView: MediaRenderView) {
            self.nameLabel = nameLabel
            self.mediaRenderView = mediaRenderView
            self.noVideoView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.mediaRenderView.frame.size.width, height: self.mediaRenderView.frame.size.height))
            self.mediaRenderView.addSubview(self.noVideoView)
            self.noVideoView.translatesAutoresizingMaskIntoConstraints = false
            self.mediaRenderView.addConstraints([NSLayoutConstraint.init(item: self.noVideoView, attribute: .width, relatedBy: .equal, toItem: self.mediaRenderView, attribute: .width, multiplier: 1, constant: 0),NSLayoutConstraint.init(item: self.noVideoView, attribute: .height, relatedBy: .equal, toItem: self.mediaRenderView, attribute: .height, multiplier: 1, constant: 0),NSLayoutConstraint.init(item: self.noVideoView, attribute: .centerX, relatedBy: .equal, toItem: self.mediaRenderView, attribute: .centerX, multiplier: 1, constant: 0),NSLayoutConstraint.init(item: self.noVideoView, attribute: .centerY, relatedBy: .equal, toItem: self.mediaRenderView, attribute: .centerY, multiplier: 1, constant: 0)])
            self.avatarImageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: self.mediaRenderView.frame.size.width, height: self.mediaRenderView.frame.size.height))
            self.noVideoView.addSubview(self.avatarImageView)
            self.avatarImageView.translatesAutoresizingMaskIntoConstraints = false
            self.noVideoView.addConstraints([NSLayoutConstraint.init(item: self.avatarImageView, attribute: .width, relatedBy: .equal, toItem: self.noVideoView, attribute: .width, multiplier: 1, constant: 0),NSLayoutConstraint.init(item: self.avatarImageView, attribute: .height, relatedBy: .equal, toItem: self.noVideoView, attribute: .height, multiplier: 1, constant: 0),NSLayoutConstraint.init(item: self.avatarImageView, attribute: .centerX, relatedBy: .equal, toItem: self.noVideoView, attribute: .centerX, multiplier: 1, constant: 0),NSLayoutConstraint.init(item: self.avatarImageView, attribute: .centerY, relatedBy: .equal, toItem: self.noVideoView, attribute: .centerY, multiplier: 1, constant: 0)])
            self.noVideoView.backgroundColor = self.mediaRenderView.backgroundColor
            self.auxStream = nil
            self.currentPerson = nil
        }
        
        func update(person:Person?) {
            DispatchQueue.main.async {
                if let stream = self.auxStream, let updatePerson = person {
                    self.nameLabel.text = updatePerson.displayName
                    if stream.isSendingVideo {
                        self.noVideoView.isHidden = true
                        self.avatarImageView.isHidden = true
                    }  else {
                        
                        self.avatarImageView.isHidden = false
                        if self.currentPerson?.id != updatePerson.id {
                            self.avatarImageView.image = nil
                            Utils.downloadAvatarImage(updatePerson.avatar, completionHandler: {
                                self.avatarImageView.image = $0
                                self.currentAvatar = $0
                                self.currentPerson = updatePerson
                            })
                        } else {
                            self.avatarImageView.image = self.currentAvatar
                        }
                        self.noVideoView.isHidden = false
                    }
                } else {
                    self.cleanUp()
                }
            }
        }
        
        private func cleanUp() {
            self.nameLabel.text = "Waiting.."
            self.avatarImageView.image = nil
            self.avatarImageView.isHidden = true
            self.noVideoView.isHidden = false
            self.mediaRenderView.bringSubviewToFront(self.noVideoView)
            self.currentPerson = nil
        }
    }
}

// MARK: - DTMF dialpad view
extension VideoCallViewController : UICollectionViewDataSource {
    private static let DTMFKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"]
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return VideoCallViewController.DTMFKeys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dialpadCell", for: indexPath)
        let dialButton = cell.viewWithTag(105) as! UILabel
        dialButton.text = VideoCallViewController.DTMFKeys[indexPath.item]
        dialButton.layer.borderColor = UIColor.gray.cgColor
        return cell
    }
}

// MARK: - DTMF Collection View
extension VideoCallViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        UIView.animate(withDuration: 0.2, animations: {
            cell?.alpha = 0.7
        }, completion: { (finished: Bool) -> Void in
            cell?.alpha = 1
        })
        
        let dialButton = cell!.viewWithTag(105) as! UILabel
        let dtmfEvent = dialButton.text
        self.currentCall?.send(dtmf: dtmfEvent!, completionHandler: nil)
    }
}

// MARK: - Tab bar control
extension VideoCallViewController :UITabBarDelegate {
    enum TabBarItemType: Int {
        case callControl = 0
        case auxiliaryVide = 1
        case participants = 2
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.tag == TabBarItemType.callControl.rawValue {
            self.view.bringSubviewToFront(self.callControlView)
            self.callControlView.isHidden = false
            self.auxVideosContainerView.isHidden = true
            self.participantsView.isHidden = true
        } else if item.tag == TabBarItemType.auxiliaryVide.rawValue {
            self.view.bringSubviewToFront(self.auxVideosContainerView)
            self.callControlView.isHidden = true
            self.auxVideosContainerView.isHidden = false
            self.participantsView.isHidden = true
        } else if item.tag == TabBarItemType.participants.rawValue {
            self.view.bringSubviewToFront(self.participantsView)
            self.callControlView.isHidden = true
            self.auxVideosContainerView.isHidden = true
            self.participantsView.isHidden = false
        }
    }
}

// MARK: - Participants table view delegate & data source
extension VideoCallViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100 * Utils.HEIGHT_SCALE
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.participantsTableView {
            self.updateBadgeValue()
            return self.participantData[section].count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30 * Utils.HEIGHT_SCALE
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.participantData.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let state = self.participantData[section].first?.state
        switch state {
        case .joined:
            return "In Meeting"
        case .waiting:
            return "In Lobby"
        default:
            return "Not In Meeting"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantCell", for: indexPath) as! ParticipantTableViewCell
        
        let dataSource: [[CallMembership]]?
        dataSource = self.participantData
        
        func updateCellInfo(cell: ParticipantTableViewCell, person: Person?, callmembership: CallMembership) {
            if let cellPerson = person {
                Utils.downloadAvatarImage(cellPerson.avatar, completionHandler: {
                    cell.avatarImageView.image = $0
                })
                cell.nameLabel.text = cellPerson.displayName
                cell.activeSpeakerLabel.isHidden = !callmembership.isActiveSpeaker
                cell.audioStatusImage.isHighlighted = !callmembership.sendingAudio
                cell.videoStatusImage.isHighlighted = !callmembership.sendingVideo
            }
        }
        
        if let participant = dataSource?[indexPath.section][indexPath.row] {
            if let oldPerson = self.personInfoArray.filter({$0.id == participant.personId}).first {
                updateCellInfo(cell: cell, person: oldPerson, callmembership: participant)
            } else if let personId = participant.personId {
                self.webexSDK?.people.get(personId: personId) { [weak self] response in
                    if self != nil {
                        switch response.result {
                        case .success(let person):
                            updateCellInfo(cell: cell,person: person,callmembership: participant)
                            self?.personInfoArray.append(person)
                        case .failure:
                            break
                        }
                    }
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dataSource = self.participantData
        let membership = dataSource[indexPath.section][indexPath.row]
        if membership.state == .waiting && membership.isSelf == false {
            let alertVC = UIAlertController(title: "Let in?", message: nil, preferredStyle: .alert)
            let letinAction = UIAlertAction(title: "Yes", style: .default) { (action) in
                // let sb in the meeting
                self.currentCall?.letIn([membership], completionHandler: { (error) in
                    if error != nil {
                        print("Let in failed " + error.debugDescription)
                    }
                })
            }
            let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
            alertVC.addAction(letinAction)
            alertVC.addAction(cancelAction)
            self.present(alertVC, animated: true, completion: nil)
        }
    }
}
