import AVKit
import ReplayKit
import UIKit
import WebexSDK

class CallViewController: UIViewController, MultiStreamObserver, UICollectionViewDataSource, UICollectionViewDelegate {
    // MARK: Properties
    var space: Space?
    var callInviteAddress: String?
    var oldCallId: String?
    var call: Call?
    var currentCallId: String?
    var isLocalAudioMuted = false
    var isLocalVideoMuted = false
    var isLocalScreenSharing = false
    var isCallControlsHidden = false
    var participants: [CallMembership] = []
    var onHold = false
    var addedCall = false
    var incomingCall = false
    var player = AVAudioPlayer()
    var isReceivingAudio = false
    var isReceivingVideo = false
    var isReceivingScreenshare = false
    var isFrontCamera = true
    var compositedLayout: MediaOption.CompositedVideoLayout = .single
    var renderMode: Call.VideoRenderMode = .fit
    var torchMode: Call.TorchMode = .off
    var flashMode: Call.FlashMode = .off
    var cameraTargetBias: Call.CameraExposureTargetBias?
    var cameraISO: Call.CameraExposureISO?
    var cameraDuration: Call.CameraExposureDuration?
    var zoomFactor: Float = 1.0
    private let kCellId: String = "AuxCell"
    var auxViews: [MediaRenderView] = []
    var auxDict: [MediaRenderView: AuxStream] = [:]
    var auxDictNew: [MediaRenderView: MediaStream] = [:]
    var isModerator = false
    var pinOrPassword = ""
    var captcha: Phone.Captcha?
    var captchaVerifyCode: String = ""
    var isCUCMOrWxcCall = false
    private let virtualBackgroundCell = "VirtualBackgroundCell"
    private var backgroundItems: [Phone.VirtualBackground] = []
    private var imagePicker = UIImagePickerController()
    private var canControlWXA = false
    private var isWXAEnabled = false
    private var transcriptionItems: [Transcription] = []
    private var participantId = ""
    private var isMultiStreamEnabled = false
    private var breakout: Call.Breakout?
    private var sessions: [Call.BreakoutSession] = []
    private var breakoutJoined = false
    private var duration = 0
    private var timer = Timer()
    
    // MARK: Initializers
    init(space: Space, addedCall: Bool = false, currentCallId: String = "", oldCallId: String = "", incomingCall: Bool = false, call: Call? = nil) {
        self.space = space
        self.addedCall = addedCall
        self.currentCallId = currentCallId
        self.oldCallId = oldCallId
        self.incomingCall = incomingCall
        if incomingCall || addedCall {
            self.call = call
        }
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    init(callInviteAddress: String) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
        self.callInviteAddress = callInviteAddress
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Views
    private var selfVideoView: MediaRenderView = {
        let view = MediaRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setSize(width: 80, height: 150)
        return view
    }()
    
    private var remoteVideoView: MediaStreamView = {
        let view = MediaStreamView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var screenShareView: MediaRenderView = {
        let view = MediaRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var durationLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .headline)
        label.accessibilityIdentifier = "durationLabel"
        label.textColor = .momentumOrange50
        label.isHidden = true
        return label
    }()
    
    private var callingLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Calling..."
        label.font = .preferredFont(forTextStyle: .headline)
        label.accessibilityIdentifier = "callLabel"
        return label
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title1)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = space?.title ?? call?.title ?? "Ongoing Call"
        label.accessibilityIdentifier = "nameLabel"
        return label
    }()
    
    private lazy var endCallButton: CallButton = {
        let button = CallButton(style: .cta, size: .medium, type: .endCall)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(84)
        button.setHeight(84)
        button.accessibilityIdentifier = "endButton"
        button.addTarget(self, action: #selector(handleEndCallAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var invisibleVolumeView: AVRoutePickerView = {
        let view = AVRoutePickerView(frame: .zero)
        view.isHidden = true
        return view
    }()
    
    private lazy var audioRouteButton: CallButton = {
        let button = CallButton(frame: invisibleVolumeView.bounds, style: .cta, size: .medium, type: .audioRoute)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(70)
        button.setHeight(70)
        button.accessibilityIdentifier = "audioRouteButton"
        button.insertSubview(invisibleVolumeView, aboveSubview: button)
        button.addTarget(self, action: #selector(showAudioRouteSelector(_:)), for: .touchUpInside)
        return button
    }()
    
    private var addCallButton: CallButton = {
        let button = CallButton(style: .cta, size: .medium, type: .addCall)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(70)
        button.setHeight(70)
        button.accessibilityIdentifier = "addCallButton"
        button.addTarget(self, action: #selector(handleAddCallAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private var mergeCallButton: CallButton = {
        let button = CallButton(style: .cta, size: .medium, type: .mergeCall)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(70)
        button.setHeight(70)
        button.accessibilityIdentifier = "mergeCallButton"
        button.isHidden = true
        if #available(iOS 13.0, *) {
            button.backgroundColor = .systemGray2
        } else {
            button.backgroundColor = .systemGray
        }
        button.addTarget(self, action: #selector(handleMergeCallAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private var toggleVideoButton: CallButton = {
        let button = CallButton(style: .cta, size: .medium, type: .toggleVideo)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(70)
        button.setHeight(70)
        button.accessibilityIdentifier = "startVideoButton"
        button.addTarget(self, action: #selector(handleToggleVideoCallAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var muteButton: CallButton = {
        var button = CallButton(style: .cta, size: .medium, type: .muteCall)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(70)
        button.setHeight(70)
        button.accessibilityIdentifier = "muteButton"
        button.addTarget(self, action: #selector(handleMuteCallAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private var holdButton: CallButton = {
        let button = CallButton(style: .cta, size: .medium, type: .holdCall)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(70)
        button.setHeight(70)
        button.accessibilityIdentifier = "holdButton"
        button.addTarget(self, action: #selector(handleHoldCallAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private var transferCallButton: CallButton = {
        let button = CallButton(style: .cta, size: .medium, type: .transferCall)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(70)
        button.setHeight(70)
        button.accessibilityIdentifier = "transferCallButton"
        button.addTarget(self, action: #selector(handletransferCallAction(_:)), for: .touchUpInside)
        button.isHidden = true
        if #available(iOS 13.0, *) {
            button.backgroundColor = .systemGray2
        } else {
            button.backgroundColor = .systemGray
        }
        return button
    }()
    
    private var showParticipantsButton: CallButton = {
        let button = CallButton(style: .cta, size: .medium, type: .showParticipants)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(70)
        button.setHeight(70)
        button.accessibilityIdentifier = "showParticipantsButton"
        button.addTarget(self, action: #selector(showParticipantsList(_:)), for: .touchUpInside)
        return button
    }()
    
    private var startScreenShareButton: CallButton = {
        let button = CallButton(style: .cta, size: .medium, type: .screenShare)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(70)
        button.setHeight(70)
        button.accessibilityIdentifier = "startScreenShareButton"
        button.addTarget(self, action: #selector(handleScreenShareAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [muteButton, holdButton, audioRouteButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.alignment = .center
        return stack
    }()
    
    private lazy var bottomStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [toggleVideoButton, showParticipantsButton, moreButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.alignment = .center
        return stack
    }()
    
    private var swapCameraButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(30)
        button.setHeight(30)
        button.accessibilityIdentifier = "swapCameraButton"
        button.addTarget(self, action: #selector(handleSwapCameraAction(_:)), for: .touchUpInside)
        button.setImage(UIImage(named: "swap-camera"), for: .normal)
        button.isHidden = true
        return button
    }()
    
    private var moreButton: UIButton = {
        let button = CallButton(style: .cta, size: .medium, type: .more)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(70)
        button.setHeight(70)
        button.accessibilityIdentifier = "isReceivingButton"
        button.addTarget(self, action: #selector(handleMoreAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var auxCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 170, height: 155)
        layout.minimumLineSpacing = 10
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .backgroundColor
        view.dataSource = self
        view.delegate = self
        view.register(AuxCollectionViewCell.self, forCellWithReuseIdentifier: kCellId)
        view.isScrollEnabled = false
        return view
    }()
    
    private lazy var virtualBgcollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 50, height: 50)
        layout.minimumLineSpacing = 20
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.setHeight(80)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray
        view.dataSource = self
        view.delegate = self
        view.register(VirtualBackgroundViewCell.self, forCellWithReuseIdentifier: virtualBackgroundCell)
        view.isScrollEnabled = true
        view.isHidden = true
        return view
    }()

    private lazy var transcriptionsTable: UITableView = {
        let tv = UITableView()
        tv.setHeight(200)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .lightGray
        tv.dataSource = self
        tv.isScrollEnabled = true
        tv.isHidden = true
        tv.allowsSelection = false
        return tv
    }()
    
    private lazy var badNetworkIcon: CallButton = {
        var button = CallButton(style: .outlined, size: .large, type: .qualityIndicator)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(50)
        button.setHeight(50)
        button.isHidden = true
        button.accessibilityIdentifier = "badNetworkIcon"
        button.addTarget(self, action: #selector(handleMuteCallAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var multiStreamSettingsView: MultiStreamSettingsView = {
        let view = MultiStreamSettingsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setHeight(250)
        view.alpha = 1
        view.delegate = self
        return view
    }()
    
    /// onAuxStreamChanged represent a call back when a existing auxiliary stream status changed.
    var onAuxStreamChanged: ((AuxStreamChangeEvent) -> Void)?
    
    /// onAuxStreamAvailable represent the call back when current call have a new auxiliary stream.
    var onAuxStreamAvailable: (() -> MediaRenderView?)?
    
    /// onAuxStreamUnavailable represent the call back when current call have an existing auxiliary stream being unavailable.
    var onAuxStreamUnavailable: (() -> MediaRenderView?)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        setupViews()
        setupConstraints()
        checkIsOnHold()
        updatePhoneSettings()
        imagePicker.delegate = self
        if !addedCall && !incomingCall {
            callingLabel.text = "calling..."
            connectCall()
        } else if incomingCall {
            answerCall()
            callingLabel.text = "connecting..."
        } else if addedCall {
            guard let call = call else { print("Call is empty"); return }
            callingLabel.text = "connecting..."
            self.isCUCMOrWxcCall = call.isCUCMCall || call.isWebexCallingOrWebexForBroadworks
            DispatchQueue.main.async {
                self.webexCallStatesProcess(call: call)
            }
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.remoteVideoView.isUserInteractionEnabled = true
        remoteVideoView.addGestureRecognizer(tap)
        self.view.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false
        if !isCUCMOrWxcCall {
            DispatchQueue.main.async {
                self.auxCollectionView.reloadData()
            }
        }
        self.multiStreamSettingsView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.shared.callKitManager?.delegate = self
        updateVirtualBackgrounds()
    }
    
    // MARK: Methods
    
    private func updateStates(callInfo: Call) {
        self.renderMode = callInfo.remoteVideoRenderMode
        self.torchMode = callInfo.cameraTorchMode
        self.flashMode = callInfo.cameraFlashMode
        self.cameraTargetBias = callInfo.exposureTargetBias
        self.cameraISO = callInfo.exposureISO
        self.cameraDuration = callInfo.exposureDuration
        self.zoomFactor = callInfo.zoomFactor
        self.compositedLayout = callInfo.compositedVideoLayout ?? .single
        self.isLocalAudioMuted = !callInfo.sendingAudio
        self.isLocalVideoMuted = !callInfo.sendingVideo
        self.isLocalScreenSharing = callInfo.sendingScreenShare
        self.isReceivingAudio = callInfo.receivingAudio
        self.isReceivingVideo = callInfo.receivingVideo
        self.isReceivingScreenshare = callInfo.receivingScreenShare
        self.isFrontCamera = callInfo.facingMode == .user ? true : false
        self.canControlWXA = callInfo.wxa.canControlWXA
        self.isWXAEnabled = callInfo.wxa.isEnabled
        self.showVideo()
        self.updateMuteState()
    }
    
    private func updatePhoneSettings() {
        let isComposite = UserDefaults.standard.bool(forKey: "compositeMode")
        let is1080pEnabled = UserDefaults.standard.bool(forKey: "VideoRes1080p")
        webex.phone.videoStreamMode = isComposite ? .composited : .auxiliary
        webex.phone.audioBNREnabled = true
        webex.phone.audioBNRMode = .LP
        webex.phone.defaultFacingMode = .user
        webex.phone.videoMaxRxBandwidth = is1080pEnabled ? Phone.DefaultBandwidth.maxBandwidth1080p.rawValue : Phone.DefaultBandwidth.maxBandwidth720p.rawValue
        webex.phone.videoMaxTxBandwidth = is1080pEnabled ? Phone.DefaultBandwidth.maxBandwidth1080p.rawValue : Phone.DefaultBandwidth.maxBandwidth720p.rawValue
        webex.phone.sharingMaxRxBandwidth = Phone.DefaultBandwidth.maxBandwidthSession.rawValue
        webex.phone.audioMaxRxBandwidth = Phone.DefaultBandwidth.maxBandwidthAudio.rawValue
        webex.phone.enableBackgroundConnection = true
        webex.phone.defaultLoudSpeaker = false
        updateAdvancedSettings()
    }
    
    private func updateAdvancedSettings() {
        var advancedSettings: [Phone.AdvancedSettings] = []
        let videoMosaic = Phone.AdvancedSettings.videoEnableDecoderMosaic(true)
        let videoMaxFPS = Phone.AdvancedSettings.videoMaxTxFPS(30)
        advancedSettings.append(videoMosaic)
        advancedSettings.append(videoMaxFPS)
        webex.phone.advancedSettings = advancedSettings
    }
    
    private func updateUI(isCUCMOrWxcCall: Bool) {
        if isCUCMOrWxcCall {
            DispatchQueue.main.async {
                self.bottomStackView.addArrangedSubview(self.addCallButton)
                self.bottomStackView.addArrangedSubview(self.mergeCallButton)
                self.bottomStackView.addArrangedSubview(self.transferCallButton)
                self.view.layoutIfNeeded()
            }
        } else {
            DispatchQueue.main.async {
                self.stackView.addArrangedSubview(self.startScreenShareButton)
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func updateMuteState() {
        if self.isLocalAudioMuted {
            DispatchQueue.main.async {
                self.muteButton.setImage(UIImage(named: "microphone-muted"), for: .normal)
                if #available(iOS 13.0, *) {
                    self.muteButton.backgroundColor = .systemGray6
                } else {
                    self.muteButton.backgroundColor = .systemGray
                }
            }
        } else {
            DispatchQueue.main.async {
                self.muteButton.setImage(UIImage(named: "microphone"), for: .normal)
                if #available(iOS 13.0, *) {
                    self.muteButton.backgroundColor = .systemGray2
                } else {
                    self.muteButton.backgroundColor = .systemGray
                }
            }
        }
    }
    
    private func connectCall() {
        guard let joinAddress = callInviteAddress ?? space?.id else {
            let alert = UIAlertController(title: "Error", message: "Calling address is null", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
            return
        }
        let mediaOption = getMediaOption(isModerator: isModerator, pin: pinOrPassword, captchaId: captcha?.id ?? "", captchaVerifyCode: captchaVerifyCode)
        webex.phone.dial(joinAddress, option: mediaOption, completionHandler: { result in
            switch result {
            case .success(let call):
                self.currentCallId = call.callId
                DispatchQueue.main.async {
                    self.webexCallStatesProcess(call: call)
                }
                self.call = call
                self.isCUCMOrWxcCall = call.isCUCMCall || call.isWebexCallingOrWebexForBroadworks
                CallObjectStorage.self.shared.addCallObject(call: call)
            case .failure(let error):
                guard let err = error as? WebexError else {
                    let alert = UIAlertController(title: "Call Failed", message: "\(error)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {_ in
                        self.dismiss(animated: true)
                    }))
                    DispatchQueue.main.async {
                        self.present(alert, animated: true)
                    }
                    return
                }
                self.showPasswordCaptchaAlert(error: err)
            }
        })
    }
    
    private func answerCall() {
        guard let call = call else {
            let alert = UIAlertController(title: "Error", message: "Call not found", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
            return
        }
        self.isCUCMOrWxcCall = call.isCUCMCall || call.isWebexCallingOrWebexForBroadworks
        let mediaOption = getMediaOption(isModerator: isModerator, pin: pinOrPassword)
        self.webexCallStatesProcess(call: call)
        call.answer(option: mediaOption, completionHandler: { error in
            if error != nil {
                print("Answer call error:\(String(describing: error))")
            }
        })
    }
    
    func getMediaOption(isModerator: Bool, pin: String?, captchaId: String = "", captchaVerifyCode: String = "") -> MediaOption {
        var mediaOption = MediaOption.audioOnly()
        let hasVideo = UserDefaults.standard.bool(forKey: "hasVideo")
        if hasVideo {
            mediaOption = MediaOption.audioVideoScreenShare(video: (local: selfVideoView, remote: remoteVideoView.mediaRenderView), screenShare: screenShareView)
        }
        mediaOption.moderator = isModerator
        mediaOption.pin = pin
        mediaOption.captchaId = captchaId
        mediaOption.captchaVerifyCode = captchaVerifyCode
        return mediaOption
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        isCallControlsHidden.toggle()
        toggleControls()
    }
    
    private func toggleControls () {
        DispatchQueue.main.async {
            self.stackView.isHidden = self.isCallControlsHidden
            self.bottomStackView.isHidden = self.isCallControlsHidden
            self.endCallButton.isHidden = self.isCallControlsHidden
        }
        
        if !isCallControlsHidden {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                self.isCallControlsHidden = true
                self.toggleControls()
            })
        }
    }
    
    private func checkIsOnHold() {
        guard let call = call else {
            let alert = UIAlertController(title: "Error", message: "Call not found", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
            return
        }
        onHold = call.isOnHold
        DispatchQueue.main.async {
            if #available(iOS 13.0, *) {
                self.holdButton.backgroundColor = self.onHold ? .systemGray6 : .systemGray2
            } else {
                self.holdButton.backgroundColor = self.onHold ? .systemGray : .white
            }
        }
    }
    
    fileprivate func endCall() {
        if let call = self.call {
            call.hangup(completionHandler: { error in
                if error == nil {
                    DispatchQueue.main.async { [weak self] in
                        self?.dismiss(animated: true)
                    }
                } else {
                    let alert = UIAlertController(title: "Error", message: error.debugDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak self] _ in
                        self?.dismiss(animated: true)
                    }))
                    DispatchQueue.main.async {  [weak self] in
                        self?.present(alert, animated: true)
                    }
                }
            })
        } else {
            webex.phone.cancel()
            self.dismiss(animated: true)
        }
    }
    
    func toggleMuteButton() {
        isLocalAudioMuted.toggle()
        self.call?.sendingAudio = !isLocalAudioMuted
    }
    
    // MARK: Actions
    @objc private func handleEndCallAction(_ sender: UIButton) {
        endCall()
        AppDelegate.shared.callKitManager?.endCall()
    }
    
    @objc private func showAudioRouteSelector(_ sender: UIButton) {
        invisibleVolumeView.subviews.compactMap { $0 as? UIButton }.first?.sendActions(for: .touchUpInside)
    }
    
    @objc private func handleAddCallAction(_ sender: UIButton) {
        guard let call = call else {
            let alert = UIAlertController(title: "Error", message: "Call not found", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
            return
        }
        call.holdCall(putOnHold: true)
        let dialViewController = DialCallViewController(addedCall: true, oldCallId: self.currentCallId ?? "", call: call)
        dialViewController.presentationController?.delegate = self
        present(dialViewController, animated: true, completion: nil)
    }
    
    @objc private func handleMergeCallAction(_ sender: UIButton) {
        guard let oldCallId = oldCallId, let call = CallObjectStorage.shared.getCallObject(callId: oldCallId) else {
            let alert = UIAlertController(title: "Error", message: "Call not found", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
            return
        }
        call.mergeCall(targetCallId: currentCallId ?? "")
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @objc private func handleMuteCallAction(_ sender: UIButton) {
        toggleMuteButton()
    }
    
    @objc private func handleHoldCallAction(_ sender: UIButton) {
        guard let call = call else {
            let alert = UIAlertController(title: "Error", message: "Call not found", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
            return
        }
        onHold.toggle()
        call.holdCall(putOnHold: onHold)
    }
    
    @objc private func handletransferCallAction(_ sender: UIButton) {
        guard let oldCallId = oldCallId, let call = CallObjectStorage.shared.getCallObject(callId: oldCallId) else {
            let alert = UIAlertController(title: "Error", message: "Call not found", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
            return
        }
        call.transferCall(toCallId: currentCallId ?? "")
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleToggleVideoCallAction(_ sender: UIButton) {
        isLocalVideoMuted.toggle()
        self.call?.sendingVideo = !isLocalVideoMuted
    }
    
    @objc private func handleSwapCameraAction(_ sender: UIButton) {
        isFrontCamera.toggle()
        self.call?.facingMode = isFrontCamera ? .user : .environment
    }
    
    @objc private func handleScreenShareAction(_ sender: UIButton) {
        if #available(iOS 12.0, *) {
            let broadcastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            broadcastPicker.preferredExtension = "com.webex.sdk.KitchenSinkv3.0.KitchenSinkBroadcastExtension"
            for subview in broadcastPicker.subviews {
                if let button = subview as? UIButton {
                    button.sendActions(for: .allTouchEvents)
                }
            }
        } else {
            if isLocalScreenSharing {
                self.call?.stopSharing() {
                    error in
                        print("ERROR: \(String(describing: error))")
                }
            } else {
                self.call?.startSharing() {
                    error in
                        print("ERROR: \(String(describing: error))")
                }
            }
        }
    }
    
    @objc private func handleMoreAction(_ sender: UIButton) {
        
        self.torchMode = call?.cameraTorchMode ?? .off
        self.flashMode = call?.cameraFlashMode ?? .off
        self.cameraTargetBias = call?.exposureTargetBias
        self.cameraISO = call?.exposureISO
        self.cameraDuration = call?.exposureDuration
        self.zoomFactor = call?.zoomFactor ?? 1.0

        let compositedLayouts: [MediaOption.CompositedVideoLayout] = [.single, .grid, .filmstrip, .notSupported]
        let renderModes: [Call.VideoRenderMode] = [.fit, .cropFill, .stretchFill]
        let flashModes: [Call.FlashMode] = [.on, .off, .auto]
        let torchModes: [Call.TorchMode] = [.on, .off, .auto]

        let alertController = UIAlertController.actionSheetWith(title: "", message: nil, sourceView: self.view)
        
        alertController.addAction(.dismissAction(withTitle: "Cancel"))
        
        alertController.addAction(UIAlertAction(title: "Composited Layout - \(String(describing: self.compositedLayout))", style: .default) {  _ in
            guard var index = compositedLayouts.firstIndex(of: self.compositedLayout) else { return }
            if index == compositedLayouts.count - 1 {
                return
            }
            if index == compositedLayouts.count - 2 {
                index = 0
            } else {
                index += 1
            }
            self.setCompositedLayout(layout: compositedLayouts[index])
        })
        
        alertController.addAction(UIAlertAction(title: "Video Render Mode - \(String(describing: self.renderMode))", style: .default) {  _ in
            guard var index = renderModes.firstIndex(of: self.renderMode) else { return }
            if index == renderModes.count - 1 {
                index = 0
            } else {
                index += 1
            }
            self.setRenderMode(mode: renderModes[index])
        })
        
        // DTMF Keyboard only supported for CUCM or WxC call
        alertController.addAction(UIAlertAction(title: "Enter authorisation code", style: .default) {  _ in
            let alertController = UIAlertController(title: "Authorisation Code", message: "", preferredStyle: .alert)
            
            alertController.addTextField { (textField: UITextField!) -> Void in
                textField.placeholder = "Enter Authorisation Code"
            }
            
            let saveAction = UIAlertAction(title: "Ok", style: .default, handler: { alert -> Void in
                let firstTextField = alertController.textFields![0] as UITextField
                if let dtmf = firstTextField.text {
                    self.call?.send(dtmf: dtmf, completionHandler: { res in
                        if let res = res {
                            print("Send DTMF error: \(res)")
                        }
                    })
                }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil )
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        })

        alertController.addAction(UIAlertAction(title: "Receiving Video - \(isReceivingVideo)", style: .default) {  _ in
            self.setReceivingVideo(isReceiving: (!self.isReceivingVideo))
        })
        
        alertController.addAction(UIAlertAction(title: "Receiving Audio - \(isReceivingAudio)", style: .default) {  _ in
            self.setReceivingAudio(isReceiving: (!self.isReceivingAudio))
        })
        
        alertController.addAction(UIAlertAction(title: "Receiving Screenshare - \(isReceivingScreenshare)", style: .default) {  _ in
            self.setReceivingScreenshare(isReceiving: (!self.isReceivingScreenshare))
        })
        
        if virtualBgcollectionView.isHidden {
            alertController.addAction(UIAlertAction(title: "Change Virtual Background", style: .default) {  _ in
                self.virtualBgAction(tag: 0)
            })
        } else {
            alertController.addAction(UIAlertAction(title: "Add Virtual Background", style: .default) {  _ in
                self.virtualBgAction(tag: 1)
            })
        }
        
        if isMultiStreamEnabled {
            alertController.addAction(UIAlertAction(title: "Multi Stream Options", style: .default) {  _ in
                self.showMultiStreamOptions()
            })
        }
        
        if (call?.isWebexCallingOrWebexForBroadworks ?? false) {
            alertController.addAction(UIAlertAction(title: "Direct Transfer Call", style: .default) {  _ in
                let alertController = UIAlertController(title: "Enter phone number to direct transfer", message: "", preferredStyle: .alert)
                
                alertController.addTextField { (textField: UITextField!) -> Void in
                    textField.placeholder = "Phone number"
                }
                
                let saveAction = UIAlertAction(title: "Ok", style: .default, handler: { alert -> Void in
                    let firstTextField = alertController.textFields![0] as UITextField
                    if let phoneNumber = firstTextField.text {
                        self.call?.directTransferCall(toPhoneNumber: phoneNumber, completionHandler: { err in
                            if err == nil {
                                print("Blind Transfer success")
                            }
                            else
                            {
                                self.slideInStateView(slideInMsg: "Blind Transfer error \(err.debugDescription)")
                            }
                        })
                    }
                })
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil )
                
                alertController.addAction(saveAction)
                alertController.addAction(cancelAction)
                
                self.present(alertController, animated: true, completion: nil)
            })
        }
        
        // Media Quality Indicator
        alertController.addAction(UIAlertAction(title: "receive MediaQualityInfoChangedCallback- \(self.call?.onMediaQualityInfoChanged != nil)", style: .default) {  _ in
            if self.call?.onMediaQualityInfoChanged == nil {
                self.badNetworkIcon.isHidden = false
                self.setMediaQualityInfoChangedCallback()
            } else {
                self.badNetworkIcon.isHidden = true
                self.call?.onMediaQualityInfoChanged = nil
            }
        })
        
        // Webex Calling escalate to Audio / Video call
        
        if let call = call {
            if call.isWebexCallingOrWebexForBroadworks {
                
                if call.isAudioOnly {
                    alertController.addAction(UIAlertAction(title: "Switch to Video call", style: .default) { [self] _ in
                        call.switchToVideoCall { result in
                            switch result {
                            case .success:
                                print("Switched to Video Call")
                                self.slideInStateView(slideInMsg: "Switched to Video Call")
                            case .failure:
                                print("Error switching to Video: \(result.error.debugDescription)")
                                self.slideInStateView(slideInMsg: "Error switching to Video call: \(result.error.debugDescription)")
                            @unknown default:
                                fatalError()
                            }
                            
                        }
                    })
                    
                } else {
                    alertController.addAction(UIAlertAction(title: "Switch to Audio only call", style: .default) { [self] _ in
                        
                        call.switchToAudioCall { result in
                            switch result {
                            case .success:
                                print("Switched to Audio Call")
                                self.slideInStateView(slideInMsg: "Switched to audio-only Call")
                            case .failure:
                                print("Error switching to audio-only: \(result.error.debugDescription)")
                                self.slideInStateView(slideInMsg: "Error switching to audio-only: \(result.error.debugDescription)")
                            @unknown default:
                                fatalError()
                            }
                        }
                    })
                }
                
            }
        }
        
        // Transcriptions
        if let call = call {
            if call.wxa.isEnabled {
                alertController.addAction(UIAlertAction(title: "\(transcriptionsTable.isHidden ? "Show":"Hide") Transcriptions", style: .default) { [self] _ in
                    self.transcriptionsTable.isHidden = !transcriptionsTable.isHidden
                    self.transcriptionsTable.reloadData()
                })
            }
            
            var wxaText: String
            if call.wxa.canControlWXA {
                wxaText = "\(call.wxa.isEnabled ? "Disable" : "Enable") WebEx Assistant"
            } else {
                wxaText = "WebEx Assistant \(call.wxa.isEnabled ? "enabled" : "disabled")"
            }
            
            let wxaToggleAction = UIAlertAction(title: wxaText, style: .default) { [self] _ in
                
                let isWXAEnabled = !call.wxa.isEnabled
                call.wxa.enableWXA(isEnabled: isWXAEnabled, callback: { success in
                    print("setting WXA to: \(isWXAEnabled) operation returned: \(success)")
                    var message: String
                    if success {
                        message = isWXAEnabled ? "WXA enabled" : "WXA disabled"
                    } else {
                        message = isWXAEnabled ? "Could not enable WXA" : "Could not disable WXA"
                    }
                    self.slideInStateView(slideInMsg: message)
                })
            }
            if !call.wxa.canControlWXA {
                // Disable WebEx Assistant toggle if user doesn't have permissions to control it
                wxaToggleAction.isEnabled = false
            }
            
            alertController.addAction(wxaToggleAction)
        }
        
        // BreakoutSession
        if let breakout = breakout {
            if (breakout.allowJoinLater) {
                for session in sessions {
                    alertController.addAction(UIAlertAction(title: "Join Breakout Session \(session.name)", style: .default) {  _ in
                        self.call?.joinBreakoutSession(breakoutSession: session)
                    })
                }
            }
            
            if (breakout.allowReturnToMainSession && breakoutJoined) {
                alertController.addAction(UIAlertAction(title: "Return To Main Session", style: .default) {  _ in
                    self.call?.returnToMainSession()
                })
            }
        }
        
        alertController.addAction(UIAlertAction(title: "Video Torch Mode - \(String(describing: self.torchMode))", style: .default) {  _ in
            guard var index = torchModes.firstIndex(of: self.torchMode) else { return }
            if index == torchModes.count - 1 {
                index = 0
            } else {
                index += 1
            }
            self.setTorchMode(mode: torchModes[index])
        })
        
        alertController.addAction(UIAlertAction(title: "Video Flash Mode - \(String(describing: self.flashMode))", style: .default) {  _ in
            guard var index = flashModes.firstIndex(of: self.flashMode) else { return }
            if index == flashModes.count - 1 {
                index = 0
            } else {
                index += 1
            }
            self.setFlashMode(mode: flashModes[index])
        })
        
        alertController.addAction(UIAlertAction(title: "Camera Zoom Factor: Zoom- \(zoomFactor)", style: .default) {  _ in
            let alertController = UIAlertController(title: "Camera Zoom Factor", message: "", preferredStyle: .alert)
            
            alertController.addTextField { (textField: UITextField!) -> Void in
                textField.placeholder = "Enter Zoom value"
            }
            
            let saveAction = UIAlertAction(title: "Ok", style: .default, handler: { alert -> Void in
                let firstTextField = alertController.textFields![0] as UITextField
                if let zoom = firstTextField.text {
                    self.call?.zoomFactor = Float(zoom) ?? 1.0
                }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil )
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        })
        
        alertController.addAction(UIAlertAction(title: "Auto Exposure: Target Bias- \(cameraTargetBias?.current ?? 0)", style: .default) {  _ in
            let alertController = UIAlertController(title: "Camera Auto Exposure", message: "", preferredStyle: .alert)
            
            alertController.addTextField { (textField: UITextField!) -> Void in
                textField.placeholder = "Enter Target Bias value"
            }
            
            let saveAction = UIAlertAction(title: "Ok", style: .default, handler: { alert -> Void in
                let firstTextField = alertController.textFields![0] as UITextField
                if let targetBias = firstTextField.text {
                    if !(self.call?.setCameraAutoExposure(targetBias: Float(targetBias) ?? 0.0) ?? false) {
                        print("Error: setCameraAutoExposure failed")
                    }
                }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil )
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        })
        
        alertController.addAction(UIAlertAction(title: "Custom Exposure: Duration- \(cameraDuration?.current ?? 0) ISO- \(cameraISO?.current ?? 0)", style: .default) {  _ in
            let alertController = UIAlertController(title: "Camera Custom Exposure", message: "", preferredStyle: .alert)
            
            alertController.addTextField { (textField: UITextField!) -> Void in
                textField.placeholder = "Enter Duration value"
            }
            
            alertController.addTextField { (textField: UITextField!) -> Void in
                textField.placeholder = "Enter ISO value"
            }
            
            let saveAction = UIAlertAction(title: "Ok", style: .default, handler: { alert -> Void in
                let firstTextField = alertController.textFields![0] as UITextField
                let secondTextField = alertController.textFields![1] as UITextField
                if let duration = firstTextField.text, let iso = secondTextField.text {
                    if !(self.call?.setCameraCustomExposure(duration: UInt64(duration) ?? 0, iso: Float(iso) ?? 0) ?? false) {
                        print("Error: setCameraCustomExposure failed")
                    }
                }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil )
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        })
        
        alertController.addAction(UIAlertAction(title: "Set Camera Focus", style: .default) {  _ in
            let alertController = UIAlertController(title: "Camera Focus", message: "", preferredStyle: .alert)
            
            alertController.addTextField { (textField: UITextField!) -> Void in
                textField.placeholder = "Enter point X value"
            }
            
            alertController.addTextField { (textField: UITextField!) -> Void in
                textField.placeholder = "Enter point Y value"
            }
            
            let saveAction = UIAlertAction(title: "Ok", style: .default, handler: { alert -> Void in
                let firstTextField = alertController.textFields![0] as UITextField
                let secondTextField = alertController.textFields![1] as UITextField
                if let x = firstTextField.text, let y = secondTextField.text {
                    if !(self.call?.setCameraFocusAtPoint(pointX: Float(x) ?? 0, pointY: Float(y) ?? 0) ?? false) {
                        print("Error: camerFocusAtPoint failed")
                    }
                }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil )
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        })
        alertController.addAction(UIAlertAction(title: "Take Photo", style: .default) {  _ in
            if !(self.call?.takePhoto() ?? false) {
                print("Error: takePhoto")
            }
        })
        
        present(alertController, animated: true)
    }
    
    private func setReceivingVideo(isReceiving: Bool) {
        self.isReceivingVideo = isReceiving
        self.call?.receivingVideo = isReceiving
    }
    
    private func setReceivingAudio(isReceiving: Bool) {
        self.isReceivingAudio = isReceiving
        self.call?.receivingAudio = isReceiving
    }
    
    private func setReceivingScreenshare(isReceiving: Bool) {
        self.isReceivingScreenshare = isReceiving
        self.call?.receivingScreenShare = isReceiving
    }
    
    private func setCompositedLayout(layout: MediaOption.CompositedVideoLayout) {
        self.compositedLayout = layout
        self.call?.compositedVideoLayout = layout
    }
    
    private func setRenderMode(mode: Call.VideoRenderMode) {
        self.renderMode = mode
        self.call?.remoteVideoRenderMode = mode
    }
    
    private func setTorchMode(mode: Call.TorchMode) {
        self.torchMode = mode
        self.call?.cameraTorchMode = mode
    }

    private func setFlashMode(mode: Call.FlashMode) {
        self.flashMode = mode
        self.call?.cameraFlashMode = mode
    }
    
    private func showVideo() {
        DispatchQueue.main.async {
            self.toggleVideoButton.backgroundColor = self.isLocalVideoMuted ? .systemRed : .systemBlue
        }
        if !isLocalVideoMuted {
            isCallControlsHidden = true
            toggleControls()
        }
    }
    
    private func showScreenShare() {
        call?.screenShareRenderView = self.screenShareView
        isCallControlsHidden = true
        toggleControls()
    }
    
    @objc private func showParticipantsList(_ sender: UIButton) {
        guard let call = self.call else { print("Call not found"); return }
        let callParticipantArr = call.memberships
        if !callParticipantArr.isEmpty {
            participants = callParticipantArr
        }
        let participantViewController = ParticipantListViewController(participants: participants, call: call)
        let navigationController = UINavigationController(rootViewController: participantViewController)
        navigationController.presentationController?.delegate = self
        self.present(navigationController, animated: true, completion: nil)
    }
    
    private func setupViews() {
        view.addSubview(screenShareView)
        view.addSubview(remoteVideoView)
        view.addSubview(auxCollectionView)
        view.addSubview(durationLabel)
        view.addSubview(callingLabel)
        view.addSubview(badNetworkIcon)
        view.addSubview(nameLabel)
        view.addSubview(multiStreamSettingsView)
        view.addSubview(stackView)
        view.addSubview(bottomStackView)
        view.addSubview(virtualBgcollectionView)
        view.addSubview(transcriptionsTable)
        view.addSubview(selfVideoView)
        view.addSubview(swapCameraButton)
        view.addSubview(endCallButton)
    }
    
    private func setupConstraints() {
        durationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        durationLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).activate()
        
        callingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        callingLabel.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 10).activate()
        
        nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        nameLabel.topAnchor.constraint(equalTo: callingLabel.topAnchor, constant: 44).activate()
        
        badNetworkIcon.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30).activate()
        badNetworkIcon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30).activate()

        endCallButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        endCallButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -140).activate()
        
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        stackView.bottomAnchor.constraint(equalTo: bottomStackView.topAnchor, constant: -50).activate()
        
        bottomStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        bottomStackView.bottomAnchor.constraint(equalTo: endCallButton.topAnchor, constant: -100).activate()
        
        swapCameraButton.centerXAnchor.constraint(equalTo: selfVideoView.centerXAnchor).activate()
        swapCameraButton.centerYAnchor.constraint(equalTo: selfVideoView.centerYAnchor).activate()
        
        screenShareView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).activate()
        screenShareView.bottomAnchor.constraint(equalTo: auxCollectionView.topAnchor).activate()
        screenShareView.widthAnchor.constraint(equalToConstant: view.bounds.width / 2).activate()
        screenShareView.leadingAnchor.constraint(equalTo: view.leadingAnchor).activate()
        screenShareView.trailingAnchor.constraint(equalTo: remoteVideoView.leadingAnchor).activate()
        
        remoteVideoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).activate()
        remoteVideoView.bottomAnchor.constraint(equalTo: auxCollectionView.topAnchor).activate()
        remoteVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor).activate()
        
        selfVideoView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20).activate()
        selfVideoView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -50).activate()
        
        auxCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: (view.bounds.height / 2) - 50).activate()
        auxCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).activate()
        auxCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).activate()
        auxCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).activate()
        
        virtualBgcollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).activate()
        virtualBgcollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).activate()
        virtualBgcollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).activate()
        
        multiStreamSettingsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).activate()
        multiStreamSettingsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).activate()
        multiStreamSettingsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).activate()
        
        transcriptionsTable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).activate()
        transcriptionsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor).activate()
        transcriptionsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor).activate()
    }
    
    public func ssoLogin (success: Bool?) {
        guard success ?? false else { return }
        let alert = UIAlertController(title: "UC Services", message: "Log in Successful", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
        }))
        self.present(alert, animated: true )
    }
    
    func setMediaQualityInfoChangedCallback() {
        self.call?.onMediaQualityInfoChanged = { indicator in
            var msg = ""
            switch indicator {
            case .Good:
                    msg = "good"
                    self.badNetworkIcon.tintColor = .systemGreen
                    self.badNetworkIcon.imageView?.tintColor = .systemGreen
            case .PoorUplink:
                    msg = "PoorUplink!"
                    self.badNetworkIcon.tintColor = .systemYellow
                    self.badNetworkIcon.imageView?.tintColor = .systemYellow
            case .PoorDownlink:
                    msg = "PoorDownlink!"
                    self.badNetworkIcon.tintColor = .systemYellow
                    self.badNetworkIcon.imageView?.tintColor = .systemYellow
            case .NetworkLost:
                    msg = "networkLost!"
                    self.badNetworkIcon.tintColor = .systemRed
                    self.badNetworkIcon.imageView?.tintColor = .systemRed
            case .DeviceLimitation:
                    msg = "CPUStaticCondition!"
                    self.badNetworkIcon.tintColor = .systemYellow
                    self.badNetworkIcon.imageView?.tintColor = .systemYellow
            case .HighCpuUsage:
                    msg = "CPUDynamicCondition!"
                    self.badNetworkIcon.tintColor = .systemYellow
                    self.badNetworkIcon.imageView?.tintColor = .systemYellow
            @unknown default:
                    msg = "good"
                    self.badNetworkIcon.tintColor = .systemGreen
                    self.badNetworkIcon.imageView?.tintColor = .systemGreen
            }
            let alert = UIAlertController(title: "Network Quality Info", message: msg, preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            if !msg.isEmpty {
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: {
                       // self.dismiss(animated: true)
                    })
                }
            }
        }
    }
    
    fileprivate func registerNewMultiStreamCallBacks(_ call: Call) {
        call.onMediaStreamAvailabilityListener = { [weak self] available, stream in
            if available, let strongSelf = self {
                if stream.streamType == .Stream1 { // remote view
                    strongSelf.remoteVideoView.updateView(with: stream)
                    stream.setOnMediaStreamInfoChanged { [weak self] type, info in
                        self?.onMediaStreamChanged(type: type, info: info)
                    }
                } else { // aux view
                    let view = MediaRenderView()
                    view.translatesAutoresizingMaskIntoConstraints = false
                    view.setSize(width: 150, height: 150)
                    strongSelf.auxViews.append(view)
                    strongSelf.auxDictNew[view] = stream
                    stream.renderView = strongSelf.auxViews[strongSelf.auxViews.count - 1]
                    strongSelf.auxCollectionView.reloadData()
                }
                
                stream.setOnMediaStreamInfoChanged { [weak self] type, info in
                    self?.onMediaStreamChanged(type: type, info: info)
                }
            } else if !available {
                if let indexToRemove = self?.auxViews.firstIndex(where: { $0 == stream.renderView }) {
                    self?.auxViews.remove(at: indexToRemove)
                    self?.auxCollectionView.reloadData()
                }
            }
        }
    }
        
    func onMediaStreamChanged(type: MediaStreamChangeEventType, info: MediaStreamChangeEventInfo) {
        if info.stream.streamType == .Stream1 {
            remoteVideoView.updateView(with: info.stream)
            return
        }
        //removing the changed stream and attaching new stream irrespective of type
        DispatchQueue.main.async {
            if let indexToRemove = self.auxViews.firstIndex(where: { $0 == info.stream.renderView }) {
                if let view = info.stream.renderView {
                    self.auxViews.remove(at: indexToRemove)
                    self.auxViews.insert(view, at: indexToRemove)
                    self.auxDictNew[view] = info.stream
                    self.auxCollectionView.reloadData()
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
    
    fileprivate func registerMultiStreamCallbacks(_ call: Call) {
        /* set the observer of this call to get multi stream event */
        call.multiStreamObserver = self
        
        // Callback when a new multi stream media being available. Return a MediaRenderView let the SDK open it automatically. Return nil if you want to open it by call the API:openAuxStream(view: MediaRenderView) later.
        self.onAuxStreamAvailable = { [weak self] in
            if let strongSelf = self {
                let view = MediaRenderView()
                view.translatesAutoresizingMaskIntoConstraints = false
                view.setSize(width: 80, height: 150)
                strongSelf.auxViews.append(view)
                return strongSelf.auxViews[strongSelf.auxViews.count - 1]
            }
            return nil
        }
        
        // Callback when an existing multi stream media being unavailable. The SDK will close the last auxiliary stream if you don't return the specified view
        self.onAuxStreamUnavailable = {
            return nil
        }
        
        // Callback when an existing multi stream media changed
        
        self.onAuxStreamChanged = { [weak self] event in
            if let strongSelf = self {
                switch event {
                    /* Callback for open an auxiliary stream results*/
                case .auxStreamOpenedEvent(let view, let result):
                    switch result {
                    case .success(let auxStream):
                        strongSelf.openedAuxiliaryUI(view: view, auxStream: auxStream)
                    case .failure(let error):
                        strongSelf.closedAuxiliaryUI(view: view)
                        print("========\(error)=====")
                    @unknown default:
                        break
                    }
                    /* This might be triggered when the auxiliary stream's speaker has changed.
                     */
                case .auxStreamPersonChangedEvent(let auxStream, let old, let new):
                    strongSelf.updateAuxiliaryUI(auxStream: auxStream)
                    print("Auxiliary stream has changed: Person from \(String(describing: old?.displayName)) to \(String(describing: new?.displayName))")
                    /* This might be triggered when the speaker muted or unmuted the video. */
                case .auxStreamSendingVideoEvent(let auxStream):
                    strongSelf.updateAuxiliaryUI(auxStream: auxStream)
                    print("Auxiliary stream has changed: Sendng Video \(auxStream.isSendingVideo)")
                    /* This might be triggered when the speaker's video rendering view size has changed. */
                case .auxStreamSizeChangedEvent(let auxStream):
                    print("Auxiliary stream size changed: Size \(auxStream.auxStreamSize)")
                    /* Callback for close an auxiliary stream results*/
                case .auxStreamClosedEvent(let view, let error):
                    if error == nil {
                        print("closedAuxiliaryUI: renderView \(view)")
                        strongSelf.closedAuxiliaryUI(view: view)
                    } else {
                        print("=====auxStreamClosedEvent error:\(String(describing: error))")
                    }
                @unknown default:
                    break
                }
            }
        }
    }
    
    func webexCallStatesProcess(call: Call) {
        print("Call Status: \(call.status)")
        
        call.onConnected = { [weak self] in
            guard let self = self else { return }
            self.player.stop()
            if self.call?.onMediaChanged != nil {
                self.badNetworkIcon.isHidden = false
            }
            self.setMediaQualityInfoChangedCallback()
            DispatchQueue.main.async {
                call.videoRenderViews = (self.selfVideoView, self.remoteVideoView.mediaRenderView)
                call.screenShareRenderView = self.screenShareView
                self.nameLabel.text = call.title
                self.callingLabel.text = "On Call"
                if self.addedCall {
                    self.addCallButton.isHidden = true
                    self.toggleVideoButton.isHidden = true
                    self.mergeCallButton.isHidden = false
                    self.transferCallButton.isHidden = false
                }
            }
            self.updateStates(callInfo: call)
            self.updateUI(isCUCMOrWxcCall: self.isCUCMOrWxcCall)
        }
        
        call.onMediaChanged = { [weak self] mediaEvents in
            print("Call isSpeaker:", call.isSpeaker)
            if let self = self {
                self.updateStates(callInfo: call)
                switch mediaEvents {
                /* Local/Remote video rendering view size has changed */
                case .localVideoViewSize, .remoteVideoViewSize, .remoteScreenShareViewSize, .localScreenShareViewSize:
                    break
                    
                /* This might be triggered when the remote party muted or unmuted the audio. */
                case .remoteSendingAudio(let isSending):
                    print("Rmote is sending Audio- \(isSending)")
                    
                /* This might be triggered when the remote party muted or unmuted the video. */
                case .remoteSendingVideo(let isSending):
                    DispatchQueue.main.async {
                        if isSending {
                            self.remoteVideoView.alpha = 1
                        } else {
                            self.remoteVideoView.alpha = 0
                        }
                    }
                    if isSending {
                        call.videoRenderViews = (self.selfVideoView, self.remoteVideoView.mediaRenderView)
                    }
                    
                /* This might be triggered when the local party muted or unmuted the audio. */
                case .sendingAudio(let isSending):
                    self.isLocalAudioMuted = !isSending
                    self.updateMuteState()
                    
                /* This might be triggered when the local party muted or unmuted the video. */
                case .sendingVideo(let isSending):
                    self.isLocalVideoMuted = !isSending
                    if isSending {
                        call.videoRenderViews = (self.selfVideoView, self.remoteVideoView.mediaRenderView)
                        print("wme-camera zoomFactor", call.zoomFactor)
                        print("wme-camera cameraFlashMode", call.cameraFlashMode)
                        print("wme-camera cameraTorchMode", call.cameraTorchMode)
                        print("wme-camera exposureDuration min", call.exposureDuration.min)
                        print("wme-camera exposureDuration max", call.exposureDuration.max)
                        print("wme-camera exposureDuration current", call.exposureDuration.current)
                        print("wme-camera exposureISO min", call.exposureISO.min)
                        print("wme-camera exposureISO max", call.exposureISO.max)
                        print("wme-camera exposureISO current", call.exposureISO.current)
                        print("wme-camera exposureTargetBias min", call.exposureTargetBias.min)
                        print("wme-camera exposureTargetBias max", call.exposureTargetBias.max)
                        print("wme-camera exposureTargetBias current", call.exposureTargetBias.current)
                    }
                    DispatchQueue.main.async {
                        self.swapCameraButton.isHidden = !isSending
                        if isSending {
                            call.forceSendingVideoLandscape(forceLandscape: false, completionHandler: { success in
                                if success {
                                    print("forceSendingVideoLandscape: \(success)")
                                }
                            })
                            self.selfVideoView.alpha = 1
                        } else {
                            self.selfVideoView.alpha = 0
                        }
                    }
                    self.showVideo()
                    
                case .receivingAudio(let isReceiving):
                    print("Rmote is receiving Audio- \(isReceiving)")
                    
                case .receivingVideo(_):
                    break
                    
                /* Camera FacingMode on local device has switched. */
                case .cameraSwitched:
                    self.isFrontCamera.toggle()
                    
                /* Whether loud speaker on local device is on or not has switched. */
                case .spearkerSwitched:
                    break
                    
                /* Whether Screen share is blocked by local*/
                case .receivingScreenShare(let isReceiving):
                    DispatchQueue.main.async {
                        if isReceiving {
                            self.screenShareView.alpha = 1
                        } else {
                            self.screenShareView.alpha = 0
                        }
                    }
                    if isReceiving {
                        self.showScreenShare()
                    }
                    
                /* Whether Remote began to send Screen share */
                case .remoteSendingScreenShare(let remoteSending):
                    DispatchQueue.main.async {
                        if remoteSending {
                            self.screenShareView.alpha = 1
                        } else {
                            self.screenShareView.alpha = 0
                        }
                    }
                    if remoteSending {
                        self.showScreenShare()
                    }
                    
                /* Whether local began to send Screen share */
                case .sendingScreenShare( _):
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
        
        call.onFailed = { reason in
            print("Call Failed!")
            self.player.stop()
            let alert = UIAlertController(title: "Call Failed", message: reason, preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: {
                    self.dismiss(animated: true)
                })
            }
        }
        
        call.onDisconnected = { reason in
            self.player.stop()
            // We will need to report call ended to CallKit when we are disconnected from a CallKit call
            AppDelegate.shared.callKitManager?.reportEndCall()
            
            switch reason {
            case .callEnded:
                CallObjectStorage.self.shared.removeCallObject(callId: call.callId ?? "")
                DispatchQueue.main.async { [weak self] in
                    self?.dismiss(animated: true)
                }
            case .localLeft:
                print(reason)
                
            case .localDecline:
                print(reason)
                
            case .localCancel:
                print(reason)
                
            case .remoteLeft:
                print(reason)
                
            case .remoteDecline:
                print(reason)
                
            case .remoteCancel:
                print(reason)
                
            case .otherConnected:
                print(reason)
                
            case .otherDeclined:
                print(reason)
                
            case .error(let error):
                print(error)
            @unknown default:
                print(reason)
            }
        }
        
        call.onWaiting = { reason in
            print(reason)
        }
        
        call.onRinging = { [weak self] in
            guard let self = self else { return }
            guard let path = Bundle.main.path(forResource: "call_1_1_ringback", ofType: "wav") else { return }
            let url = URL(fileURLWithPath: path)
            do {
                self.player = try AVAudioPlayer(contentsOf: url)
                self.player.numberOfLoops = -1
                self.player.play()
            } catch {
                print("There is an issue with ringtone")
            }
        }
        
        call.onInfoChanged = {
            self.onHold = call.isOnHold
            
            if self.isWXAEnabled != call.wxa.isEnabled {
                self.isWXAEnabled = call.wxa.isEnabled
                self.slideInStateView(slideInMsg: "WXA \(self.isWXAEnabled ? "enabled" : "disabled")")
            }
            
            if self.canControlWXA != call.wxa.canControlWXA {
                self.canControlWXA = call.wxa.canControlWXA
                if self.canControlWXA {
                    self.slideInStateView(slideInMsg: "You can now control WXA")
                }
            }
            
            DispatchQueue.main.async {
                call.videoRenderViews?.local.isHidden = self.onHold
                call.videoRenderViews?.remote.isHidden = self.onHold
                call.screenShareRenderView?.isHidden = self.onHold
                self.selfVideoView.isHidden = self.onHold
                self.remoteVideoView.isHidden = self.onHold
                self.screenShareView.isHidden = self.onHold
                if #available(iOS 13.0, *) {
                    self.holdButton.backgroundColor = self.onHold ? .systemGray6 : .systemGray2
                } else {
                    self.holdButton.backgroundColor = self.onHold ? .systemGray : .white
                }
            }
        }
        
        isMultiStreamEnabled = UserDefaults.standard.bool(forKey: "isMultiStreamEnabled")
        
        if isMultiStreamEnabled {
            registerNewMultiStreamCallBacks(call)
        } else {
            registerMultiStreamCallbacks(call)
        }
        
        call.oniOSBroadcastingChanged = { event in
            switch event {
            case .extensionConnected:
                call.startSharing(completionHandler: { error in
                    if error != nil {
                        print("share screen error:\(String(describing: error))")
                    }
                })
                print("Extension Connected")
            case .extensionDisconnected:
                call.stopSharing(completionHandler: { error in
                    if error != nil {
                        print("share screen error:\(String(describing: error))")
                    }
                })
                print("Extension stopped Broadcasting")
            @unknown default:
                break
            }
        }
        
        call.onCpuHitThreshold = {
            let alert = UIAlertController(title: "CPU Threshold Reached!", message: "Please stop video or remove virtual background", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: {
                    self.dismiss(animated: true)
                })
            }
        }
        
        call.wxa.onTranscriptionArrived = { [self] transcription in
            transcriptionItems.append(transcription)
            transcriptionsTable.reloadData()
            let indexPath = IndexPath(item: transcriptionItems.count - 1, section: 0)
            transcriptionsTable.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.bottom, animated: true)
        }
        print("UUID of Call: \(call.uuid)")
        
        call.onPhotoCaptured = { imageData in
            let showAlert = UIAlertController(title: "Take Photo Result", message: nil, preferredStyle: .alert)
            let imageView = UIImageView(frame: CGRect(x: 10, y: 50, width: 250, height: 230))
            imageView.image = UIImage(data: imageData ?? Data())
            showAlert.view.addSubview(imageView)
            let height = NSLayoutConstraint(item: showAlert.view as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 320)
            let width = NSLayoutConstraint(item: showAlert.view as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 250)
            showAlert.view.addConstraint(height)
            showAlert.view.addConstraint(width)
            showAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            }))
            DispatchQueue.main.async {
                self.present(showAlert, animated: true, completion: nil)
            }
        }

        call.onSessionEnabled = {
            print("BreakoutSession: Session Enabled")
            self.slideInStateView(slideInMsg: "Breakout Session: Enabled")
        }
        
        call.onSessionStarted = { [weak self] breakout in
            self?.breakout = breakout
            if let _duration = breakout.duration {
                self?.duration = Int(_duration)
                self?.durationLabel.isHidden = false
                self?.runTimer()
            }
            print("BreakoutSession: Session Started \(breakout)")
            self?.slideInStateView(slideInMsg: "Breakout Session: Started")
        }
        
        call.onBreakoutUpdated = { [weak self] breakout in
            self?.breakout = breakout
            if breakout.duration == nil {
                self?.durationLabel.isHidden = true
            }
            print("BreakoutSession: Breakout Updated \(breakout)")
            self?.slideInStateView(slideInMsg: "Breakout Session: Breakout Updated")
        }
        
        call.onSessionJoined = { [weak self] session in
            self?.breakoutJoined = true
            print("BreakoutSession: Session Joined \(session)")
            self?.slideInStateView(slideInMsg: "Breakout Session: \(session.name) Joined")
            self?.nameLabel.text = session.name
        }
        
        call.onJoinableSessionListUpdated = { [weak self] sessions in
            print("BreakoutSession: Joinable Session List Updated \(sessions)")
            self?.sessions = sessions
        }
        
        call.onHostAskingReturnToMainSession = { [weak self] in
            print("BreakoutSession: Host Asking Return To Main Session")
            self?.slideInStateView(slideInMsg: "Host Asking Return To Main Session")
        }
        
        call.onBroadcastMessageReceivedFromHost = { [weak self] message in
            print("BreakoutSession: Broadcast Message Received From Host \(message)")
            self?.slideInStateView(slideInMsg: "Message Received From Host \n \(message)")
        }
        
        call.onJoinedSessionUpdated = { [weak self] session in
            print("BreakoutSession: Session Updated \(session)")
            self?.slideInStateView(slideInMsg: "Breakout Session: \(session.name) Updated")
            self?.nameLabel.text = session.name
        }
        
        call.onSessionClosing = { [weak self] in
            print("BreakoutSession: Session Closing")
            if let delay = self?.breakout?.delay {
                self?.slideInStateView(slideInMsg: "Breakout Session: Closing in \(Int(delay)) seconds")
            }
        }
        
        call.onReturnedToMainSession = { [weak self] in
            self?.breakoutJoined = false
            self?.durationLabel.isHidden = true
            print("BreakoutSession: Returned To Main Session")
            self?.slideInStateView(slideInMsg: "Returned To Main Session")
            self?.nameLabel.text = call.title
        }
        
        call.onBreakoutErrorHappened = { [weak self] error in
            print("BreakoutSession: Breakout Error Happened")
            self?.slideInStateView(slideInMsg: "Breakout Error: \(error.rawValue)")
        }
    }
    
    private func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
   }
    
    @objc private func updateTimer() {
        duration -= 1
        durationLabel.text = "Breakout session duration \(timeString(time: TimeInterval(duration)))"
    }
    
    private func timeString(time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    private func openedAuxiliaryUI(view: MediaRenderView, auxStream: AuxStream) {
        auxDict[view] = auxStream
        DispatchQueue.main.async {
            self.auxCollectionView.reloadData()
        }
    }
    
    private func closedAuxiliaryUI(view: MediaRenderView) {
        let stream = auxDict[view]
        self.auxDict.removeValue(forKey: view)
        if let indexToRemove = self.auxViews.firstIndex(where: { $0 == stream?.renderView }) {
            self.auxViews.remove(at: indexToRemove)
            DispatchQueue.main.async {
                self.auxCollectionView.reloadData()
            }
        }
    }
    
    private func updateAuxiliaryUI(auxStream: AuxStream) {
        if let renderView = auxStream.renderView {
            self.auxDict[renderView] = auxStream
        }
        DispatchQueue.main.async {
            self.auxCollectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if  collectionView == auxCollectionView {
            return auxViews.count
        } else {
            return backgroundItems.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == auxCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellId, for: indexPath) as? AuxCollectionViewCell else { return UICollectionViewCell() }
            
            if isMultiStreamEnabled {
                cell.updateCell(with: auxDictNew[auxViews[indexPath.item]])
                cell.moreButton.tag = indexPath.row
                cell.moreButton.addTarget(self, action: #selector(handleMoreActionOfStream(_:)), for: .touchUpInside)
                cell.moreButton.isHidden = !(call?.isMediaStreamsPinningSupported ?? false)
            } else {
                cell.updateCell(with: auxDict[auxViews[indexPath.item]])
            }
            
            auxViews[indexPath.item].frame = cell.streamView.mediaRenderView.frame
            cell.streamView.setRenderView(view: auxViews[indexPath.item])
            auxViews[indexPath.item].frame = cell.streamView.mediaRenderView.bounds
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: virtualBackgroundCell, for: indexPath) as? VirtualBackgroundViewCell else { return UICollectionViewCell() }
            cell.setupCell(with: backgroundItems[indexPath.item], buttonActionHandler: { [weak self] in self?.deleteItem(item: self?.backgroundItems[indexPath.item]) })
            return cell
        }
    }
                                          
    @objc private func handleMoreActionOfStream(_ sender: UIButton) {

        if isMultiStreamEnabled {
          participantId = auxDictNew[auxViews[sender.tag]]?.person.personId ?? ""
        }
        let alertController = UIAlertController.actionSheetWith(title: "Multi Stream Options", message: nil, sourceView: self.view)

        if auxDictNew[auxViews[sender.tag]]?.isPinned == true {

          alertController.addAction(UIAlertAction(title: "Remove Category C", style: .default) { [weak self]  _ in
              self?.call?.removeMediaStreamCategoryC(participantId: self?.participantId ?? "")
          })
          alertController.addAction(UIAlertAction(title: "Cancel", style: .default) {  _ in
              alertController.dismiss(animated: true)
          })
        } else {
          alertController.addAction(UIAlertAction(title: "Pin Stream", style: .default) { [weak self] _ in
              self?.showMultiStreamCategoryCOptions()
          })
          alertController.addAction(UIAlertAction(title: "Cancel", style: .default) {  _ in
              alertController.dismiss(animated: true)
          })
        }
        self.present(alertController, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == virtualBgcollectionView {
            DispatchQueue.main.async {
                webex.phone.applyVirtualBackground(background: self.backgroundItems[indexPath.row], mode: .call, completionHandler: { result in
                    switch result {
                    case .success(_):
                        DispatchQueue.main.async {
                            self.slideInStateView(slideInMsg: "Successfully updated background")
                            let item = self.navigationItem.rightBarButtonItem
                            item?.image = UIImage(named: "virtual-bg")
                            item?.tag = 0
                            self.virtualBgcollectionView.isHidden = true
                            self.updateVirtualBackgrounds()
                        }
                    case .failure(let error):
                        self.slideInStateView(slideInMsg: "Failed updating background with error: \(error)")
                    @unknown default:
                        self.slideInStateView(slideInMsg: "Failed updating background")
                    }
                })
            }
        }
    }
    
    private func slideInStateView(slideInMsg: String) {
        let alert = UIAlertController(title: nil, message: slideInMsg, preferredStyle: .alert)
        self.present(alert, animated: true)
        let duration: Double = 2
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
            alert.dismiss(animated: true)
        }
    }
    
    @objc private func virtualBgAction(tag: Int) {
        guard let sendingVideo = call?.sendingVideo else {
            print("call.sending video is null")
            return
        }
        if !sendingVideo {
            let alert = UIAlertController(title: "Camera is off", message: "Please enable camera for selecting virtual background", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
        } else if tag == 0 {
            virtualBgcollectionView.reloadData()
            virtualBgcollectionView.isHidden = false
        } else if tag == 1 {
            if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
                imagePicker.sourceType = .photoLibrary
                imagePicker.allowsEditing = false
                present(imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    private func updateVirtualBackgrounds() {
        print("Limit of virtual backgroud is: \(webex.phone.virtualBackgroundLimit)")
        webex.phone.fetchVirtualBackgrounds(completionHandler: { result in
            switch result {
            case .success(let backgrounds):
                self.backgroundItems = backgrounds
                self.virtualBgcollectionView.reloadData()
            case .failure(let error):
                print("Error: \(error)")
            @unknown default:
                print("Error")
            }
        })
    }
}

extension CallViewController {
    func deleteItem(item: Phone.VirtualBackground?) {
        guard let item = item else {
            print("Virtual background item is nil")
            return
        }
        webex.phone.removeVirtualBackground(background: item, completionHandler: { result in
            switch result {
            case .success(_):
                self.slideInStateView(slideInMsg: "Successfully deleted background")
                self.updateVirtualBackgrounds()
            case .failure(let error):
                self.slideInStateView(slideInMsg: "Failed deleting background with error: \(error)")
            @unknown default:
                self.slideInStateView(slideInMsg: "Failed updating background")
            }
        })
    }
}

extension CallViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        var fileName = ""
        var fileType = ""
        
        if let url = info[UIImagePickerController.InfoKey.imageURL] as? URL {
            fileName = url.lastPathComponent
            fileType = url.pathExtension
        }
        
        let resizedthumbnail = image.resizedImage(for: CGSize(width: 64, height: 64))

        guard let imageData = image.pngData() else { return }
        let path = FileUtils.writeToFile(data: imageData, fileName: fileName)
        guard let imagePath = path?.absoluteString.replacingOccurrences(of: "file://", with: "") else { print("Failed to process image path"); return }

        guard let thumbnailData = resizedthumbnail?.pngData() else { return }
        let thumbnailFilePath = FileUtils.writeToFile(data: thumbnailData, fileName: "thumbnail\(fileName)")
        guard let thumbnailPath = thumbnailFilePath?.absoluteString.replacingOccurrences(of: "file://", with: "") else { print("Failed to process thumbnail path"); return }
        
        let thumbnail = LocalFile.Thumbnail(path: thumbnailPath, mime: fileType, width: Int(image.size.width), height: Int(image.size.height))
        guard let localFile = LocalFile(path: imagePath, name: fileName, mime: fileType, thumbnail: thumbnail) else { print("Failed to get local file"); return }
        
        webex.phone.addVirtualBackground(image: localFile, completionHandler: { result in
            picker.dismiss(animated: true, completion: nil)
            switch result {
            case .success(let newItem):
                DispatchQueue.main.async {
                    print("new background item: \(newItem)")
                    self.slideInStateView(slideInMsg: "Successfully uploaded background")
                    self.updateVirtualBackgrounds()
                }
            case .failure(let error):
                self.slideInStateView(slideInMsg: "Failed uploading background with error: \(error)")
            @unknown default:
                self.slideInStateView(slideInMsg: "Failed uploading background")
            }
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension CallViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss( _ presentationController: UIPresentationController) {
        if #available(iOS 13, *) {
            checkIsOnHold()
        }
    }
}

extension CallViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transcriptionItems.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Transcriptions"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "TranscriptionCellIdentifier")
        let transcriptionItem = transcriptionItems[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = "\(transcriptionItem.personName) \(transcriptionItem.timestamp)"
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = transcriptionItem.content
        return cell
    }
}

extension CallViewController: MultiStreamSettingsViewDelegate {
    func cancelClicked() {
        self.multiStreamSettingsView.isHidden = true
    }
  
    func setCategoryAStream(selectedQuality: MediaStreamQuality, duplicate: Bool) {
        call?.setMediaStreamCategoryA(duplicate: duplicate, quality: selectedQuality)
        self.multiStreamSettingsView.isHidden = true
    }
    
    func setCategoryBStreams(noOfStreams: Int, selectedQuality: MediaStreamQuality) {
        call?.setMediaStreamsCategoryB(numStreams: noOfStreams, quality: selectedQuality)
        self.multiStreamSettingsView.isHidden = true
    }
    
    func setCategoryCStream(selectedQuality: MediaStreamQuality) {
        call?.setMediaStreamCategoryC(participantId: participantId, quality: selectedQuality)
        self.multiStreamSettingsView.isHidden = true
    }
    
    fileprivate func showMultiStreamCategoryCOptions() {
        self.multiStreamSettingsView.isHidden = false
        self.multiStreamSettingsView.setupViewForCategoryC()
    }
    
    fileprivate func showMultiStreamOptions() {
            let alertController = UIAlertController.actionSheetWith(title: "Multi Stream Options", message: nil, sourceView: self.view)
            alertController.addAction(UIAlertAction(title: "Set Category A Option", style: .default) {  _ in
                self.multiStreamSettingsView.isHidden = false
                self.multiStreamSettingsView.setupViewForCategoryA()
            })
            alertController.addAction(UIAlertAction(title: "Set Category B Option", style: .default) {  _ in
                self.multiStreamSettingsView.isHidden = false
                self.multiStreamSettingsView.setupViewForCategoryB()
            })
            alertController.addAction(UIAlertAction(title: "Remove Category A", style: .default) {  _ in
                self.call?.removeMediaStreamCategoryA()
            })
            alertController.addAction(UIAlertAction(title: "Remove Category B", style: .default) {  _ in
                self.call?.removeMediaStreamsCategoryB()
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .default) {  _ in
                alertController.dismiss(animated: true)
            })
            self.present(alertController, animated: true, completion: nil)
    }
}


extension CallViewController: PasswordCaptchaViewViewDelegate {   // captcha
    
    func refreshCaptcha(captcha: Phone.Captcha?) {
        self.captcha = captcha
    }
    
    func showPasswordCaptchaAlert(error: WebexError) {
        
        DispatchQueue.main.async {
            let captchaView  = PasswordCaptchaView(frame: CGRect(x: 0, y: 120, width: 270, height: 220))
            captchaView.delegate = self
            var title = ""
            var message = ""
            switch error {
            case .requireHostPinOrMeetingPassword(reason: let reason):
                self.captcha = nil
                title = reason
                message = "If you are the host, please enter host key. Otherwise, enter the meeting password."
                captchaView.setupViewForPassword()
            case .invalidPassword(reason: let reason):
                self.captcha = nil
                title = reason
                message = "If you are the host, please enter correct host key. Otherwise, enter the correct meeting password."
                captchaView.setupViewForPassword()
            case .captchaRequired(captcha: let captchaObject):
                self.captcha = captchaObject
                title = "captcha Required"
                message = "Please enter the captcha shown in image or by playing audio"
                captchaView.setupViewForPasswordAndCaptcha()
            case .invalidPasswordOrHostKeyWithCaptcha(captcha: let captchaObject):
                self.captcha = captchaObject
                title = "Invalid Password With Captcha"
                message = "Please enter the captcha shown in image or by playing audio"
                captchaView.setupViewForPasswordAndCaptcha()
            default:
                self.captcha = nil
                return
            }
        
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

            alert.view.addSubview(captchaView)
            let height = NSLayoutConstraint(item: alert.view as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 380)
            let width = NSLayoutConstraint(item: alert.view as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 250)
            alert.view.addConstraint(height)
            alert.view.addConstraint(width)
        
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.isModerator = false
                self.pinOrPassword = captchaView.passwordTextField.text ?? ""
                self.captchaVerifyCode =  captchaView.captchaTextField.text ?? ""
                if let hostKey = captchaView.hostKeyTextField.text, !hostKey.isEmpty {
                    self.isModerator = true
                    self.pinOrPassword = hostKey
                }
                self.connectCall()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                alert.dismiss(animated: true, completion: {
                    self.dismiss(animated: true, completion: nil)
                })
            }))
            self.present(alert, animated: true, completion: nil)
            captchaView.updateCaptcha(captcha: self.captcha)
        }
    }
}

extension CallViewController: CallKitManagerDelegate {
    
    func muteButtonToggle() {
        toggleMuteButton()
    }
    
    func callDidEnd() {
        endCall()
    }
    
    func callDidHold(isOnHold: Bool) {
        guard let call = call else {
            let alert = UIAlertController(title: "Error", message: "Call not found", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
            return
        }
        onHold.toggle()
        call.holdCall(putOnHold: onHold)
    }
    
    func callDidFail() {
        print("call failed")
    }
    
    
}
