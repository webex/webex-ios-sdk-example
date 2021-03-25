import AVKit
import ReplayKit
import UIKit
import WebexSDK

class CallViewController: UIViewController {
    // MARK: Properties
    let space: Space
    var oldCallId: String?
    var call: Call?
    var currentCallId: String?
    var callFailed = false
    var isLocalAudioMuted = false
    var isLocalVideoMuted = false
    var isLocalScreenSharing = false
    var isCallControlsHidden = false
    var participants: [CallMembership] = []
    var onHold = false
    var addedCall: Bool? = false
    var incomingCall: Bool? = false
    var fullScreenConstraints: [NSLayoutConstraint] = []
    var miniScreenConstraints: [NSLayoutConstraint] = []
    let broadcastUIHelper: BroadcastUIHelperProtocol?
    let broadcastUIHelperFactory = BroadcastUIHelperFactory()
    var screenShareService: ScreenShareService?
    var player = AVAudioPlayer()
    var isReceivingAudio = false
    var isReceivingVideo = false
    var isReceivingScreenshare = false
    var isFrontCamera = true
    // MARK: Initializers
    init(space: Space, addedCall: Bool = false, currentCallId: String = "", oldCallId: String = "", incomingCall: Bool = false, call: Call? = nil) {
        self.space = space
        self.addedCall = addedCall
        self.currentCallId = currentCallId
        self.oldCallId = oldCallId
        self.incomingCall = incomingCall
        if incomingCall {
            self.call = call
        }
        broadcastUIHelper = broadcastUIHelperFactory.makeBroadcastUIHelper()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Views
    private var selfVideoView: MediaRenderView = {
        let view = MediaRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setSize(width: 100, height: 230)
        return view
    }()
    
    private var remoteVideoView: MediaRenderView = {
        let view = MediaRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var screenShareView: MediaRenderView = {
        let view = MediaRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        label.text = space.title
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
        let stack = UIStackView(arrangedSubviews: [muteButton, holdButton, audioRouteButton, startScreenShareButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.alignment = .center
        return stack
    }()
    
    private lazy var bottomStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [addCallButton, toggleVideoButton, mergeCallButton, transferCallButton, showParticipantsButton, isReceivingButton])
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
    
    private var isReceivingButton: UIButton = {
        let button = CallButton(style: .cta, size: .medium, type: .more)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(70)
        button.setHeight(70)
        button.accessibilityIdentifier = "isReceivingButton"
        button.addTarget(self, action: #selector(handleIsReceivingAction(_:)), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        setupViews()
        setupConstraints()
        makeInitialCallChecks()
        updatePhoneSettinsg()
        if let addedCall = addedCall, !addedCall, let incomingCall = incomingCall, !incomingCall {
            connectCall()
        } else if let incomingCall = incomingCall, incomingCall {
            answerCall()
            guard let currentCallId = currentCallId else { return }
            screenShareService = ScreenShareService(callId: currentCallId)
            screenShareService?.start()
            activeCallId = currentCallId
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.remoteVideoView.isUserInteractionEnabled = true
        remoteVideoView.addGestureRecognizer(tap)
        self.view.addGestureRecognizer(tap)
    }
    
    // MARK: Methods
    
    private func updateStates(callInfo: Call) {
        self.isLocalAudioMuted = !callInfo.sendingAudio
        self.isLocalVideoMuted = !callInfo.sendingVideo
        self.isLocalScreenSharing = callInfo.sendingScreenShare
        self.isReceivingAudio = callInfo.receivingAudio
        self.isReceivingVideo = callInfo.receivingVideo
        self.isReceivingScreenshare = callInfo.receivingScreenShare
        self.isFrontCamera = callInfo.facingMode == .user ? true : false
        self.showVideo()
    }
    
    private func updatePhoneSettinsg() {
        webex.phone.audioBNREnabled = true
        webex.phone.audioBNRMode = .LP
        webex.phone.defaultFacingMode = .user
        webex.phone.videoMaxRxBandwidth = Phone.DefaultBandwidth.maxBandwidth720p.rawValue
        webex.phone.videoMaxTxBandwidth = Phone.DefaultBandwidth.maxBandwidth720p.rawValue
        webex.phone.sharingMaxRxBandwidth = Phone.DefaultBandwidth.maxBandwidthSession.rawValue
        webex.phone.audioMaxRxBandwidth = Phone.DefaultBandwidth.maxBandwidthAudio.rawValue
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
    
    private func connectCall() {
        guard let spaceId = space.id else {
            let alert = UIAlertController(title: "Error", message: "Calling address is null", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
            return
        }
        
        webex.phone.dial(spaceId, option: MediaOption.audioVideo(local: selfVideoView, remote: remoteVideoView), completionHandler: { result in
            switch result {
            case .success(let call):
                self.currentCallId = call.callId
                guard let currentCallId = self.currentCallId else { return }
                self.screenShareService = ScreenShareService(callId: currentCallId)
                self.screenShareService?.start()
                activeCallId = currentCallId
                DispatchQueue.main.async {
                    self.webexCallStatesProcess(call: call)
                }
                self.call = call
            case .failure(let error):
                let alert = UIAlertController(title: "Call Failed", message: "\(error)", preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Ok"))
                self.present(alert, animated: true)
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
        
        call.answer(option: MediaOption.audioVideoScreenShare(video: (local: selfVideoView, remote: remoteVideoView), screenShare: screenShareView), completionHandler: { error in
            if error == nil {
                self.webexCallStatesProcess(call: call)
            }
        })
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
            self.holdButton.backgroundColor = self.onHold ? .systemGray6 : .systemGray2
        }
    }
    
    private func checkIfAddedCall() {
        if let addedCall = addedCall, addedCall {
            mergeCallButton.backgroundColor = .systemGray6
            transferCallButton.backgroundColor = .systemGray6
        }
    }
    
    private func checkIsScreenSharing() {
        startScreenShareButton.backgroundColor = isLocalScreenSharing == true ? .systemGray6 : .systemGray2
    }
    
    private func makeInitialCallChecks() {
        checkIsOnHold()
        checkIfAddedCall()
    }
    
    // MARK: Actions
    @objc private func handleEndCallAction(_ sender: UIButton) {
        guard let call = call else {
            let alert = UIAlertController(title: "Error", message: "Call not found", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
            return
        }
        call.hangup(completionHandler: { error in
            if error != nil {
                self.dismiss(animated: true)
            }
        })
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
        guard let call = call, let oldCallId = oldCallId else {
            let alert = UIAlertController(title: "Error", message: "Call not found", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
            return
        }
        call.mergeCall(callId: currentCallId ?? "", targetCallId: oldCallId)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleMuteCallAction(_ sender: UIButton) {
        isLocalAudioMuted.toggle()
        self.call?.sendingAudio = !isLocalAudioMuted
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
        guard let onNewCall = addedCall else { return }
        if !onNewCall {
            UserDefaults.standard.set(currentCallId, forKey: "oldCallId")
            let dialViewController = DialCallViewController(addedCall: true, oldCallId: self.currentCallId ?? "", call: call)
            dialViewController.presentationController?.delegate = self
            self.present(dialViewController, animated: true, completion: { [weak self] in
                guard let self = self else { return }
                self.call?.holdCall(putOnHold: true)
            })
        } else {
            guard let oldCallId = oldCallId else { return }
            call?.transferCall(fromCallId: oldCallId, toCallId: currentCallId ?? "")
            self.dismiss(animated: false, completion: nil)
        }
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
        guard let call = call else { return }
        broadcastUIHelper?.showBroadcastPickerView(sourceView: self.view)
        self.screenShareService?.onSharingStateChanged(call: call)
    }
    
    @objc private func handleIsReceivingAction(_ sender: UIButton) {
        let alertController = UIAlertController(title: "", message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(.dismissAction(withTitle: "Cancel"))
        
        alertController.addAction(UIAlertAction(title: "Receiving Video - \(isReceivingVideo)", style: .default) {  _ in
            self.setReceivingVideo(isReceiving: (!self.isReceivingVideo))
        })
        
        alertController.addAction(UIAlertAction(title: "Receiving Audio - \(isReceivingAudio)", style: .default) {  _ in
            self.setReceivingAudio(isReceiving: (!self.isReceivingAudio))
        })
        
        alertController.addAction(UIAlertAction(title: "Receiving Screenshare - \(isReceivingScreenshare)", style: .default) {  _ in
            self.setReceivingScreenshare(isReceiving: (!self.isReceivingScreenshare))
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
    
    private func showVideo() {
        DispatchQueue.main.async {
            self.toggleVideoButton.backgroundColor = self.isLocalVideoMuted ? .systemRed : .systemBlue
        }
        if !isLocalVideoMuted {
            isCallControlsHidden = true
            toggleControls()
            setSelfViewConstraints()
        }
    }
    
    private func showScreenShare() {
        isCallControlsHidden = true
        toggleControls()
        if isReceivingVideo {
            sideRemoteVideoView()
        } else {
            makeFullScreen(remoteVideoView)
        }
    }
    
    private func makeFullScreen(_ desiredView: UIView) {
        DispatchQueue.main.async {
            self.miniScreenConstraints.forEach { $0.deactivate() }
            self.fullScreenConstraints.forEach { $0.activate() }
            
            UIView.animate(withDuration: 1) { [weak self] in
                guard let self = self else { return }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func setSelfViewConstraints() {
        DispatchQueue.main.async {
            self.selfVideoView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20).activate()
            self.selfVideoView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).activate()
            self.view.layoutIfNeeded()
        }
    }
    
    private func sideRemoteVideoView() {
        DispatchQueue.main.async {
            self.fullScreenConstraints.forEach { $0.deactivate() }
            
            self.miniScreenConstraints = [self.remoteVideoView.widthAnchor.constraint(equalToConstant: 100), self.remoteVideoView.heightAnchor.constraint(equalToConstant: 230), self.remoteVideoView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20), self.remoteVideoView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20)]
            self.miniScreenConstraints.forEach { $0.activate() }
            
            UIView.animate(withDuration: 0.5) { [weak self] in
                guard let self = self else { return }
                self.view.layoutIfNeeded()
            }
        }
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
        view.addSubview(selfVideoView)
        view.addSubview(callingLabel)
        view.addSubview(nameLabel)
        view.addSubview(endCallButton)
        view.addSubview(stackView)
        view.addSubview(bottomStackView)
        view.addSubview(swapCameraButton)
    }
    
    private func setupConstraints() {
        callingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        callingLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30).activate()
        
        nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        nameLabel.topAnchor.constraint(equalTo: callingLabel.topAnchor, constant: 44).activate()
        
        endCallButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        endCallButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -140).activate()
        
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        stackView.bottomAnchor.constraint(equalTo: bottomStackView.topAnchor, constant: -50).activate()
        
        bottomStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        bottomStackView.bottomAnchor.constraint(equalTo: endCallButton.topAnchor, constant: -100).activate()
        
        swapCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60).activate()
        swapCameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).activate()
        
        screenShareView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).activate()
        screenShareView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).activate()
        screenShareView.leadingAnchor.constraint(equalTo: view.leadingAnchor).activate()
        screenShareView.trailingAnchor.constraint(equalTo: view.trailingAnchor).activate()
        
        fullScreenConstraints = [remoteVideoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), remoteVideoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor), remoteVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor), remoteVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor)]
        fullScreenConstraints.forEach { $0.activate() }
    }
    
    public func ssoLogin (success: Bool?) {
        guard success ?? false else { return }
        let alert = UIAlertController(title: "UC Services", message: "Log in Successful", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
        }))
        self.present(alert, animated: true )
    }
    
    func webexCallStatesProcess(call: Call) {
        print("Call Status: \(call.status)")
        call.onConnected = { [weak self] in
            guard let self = self else { return }
            self.player.stop()
            DispatchQueue.main.async {
                call.videoRenderViews = (self.selfVideoView, self.remoteVideoView)
                call.screenShareRenderView = self.screenShareView
                self.nameLabel.text = call.title
                self.callingLabel.text = "On Call"
                if let addedCall = self.addedCall, addedCall {
                    self.addCallButton.isHidden = true
                    self.toggleVideoButton.isHidden = true
                    self.mergeCallButton.isHidden = false
                    self.transferCallButton.isHidden = false
                }
            }
            self.updateStates(callInfo: call)
        }
        
        call.onMediaChanged = { [weak self] mediaEvents in
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
                        call.videoRenderViews = (self.selfVideoView, self.remoteVideoView)
                    }
                    if !self.isReceivingScreenshare && isSending {
                        self.makeFullScreen(self.remoteVideoView)
                    }
                    
                /* This might be triggered when the local party muted or unmuted the audio. */
                case .sendingAudio(let isSending):
                    self.isLocalAudioMuted = !isSending
                    if self.isLocalAudioMuted {
                        DispatchQueue.main.async {
                            self.muteButton.setImage(UIImage(named: "microphone-muted"), for: .normal)
                            self.muteButton.backgroundColor = .systemGray6
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.muteButton.setImage(UIImage(named: "microphone"), for: .normal)
                            self.muteButton.backgroundColor = .systemGray2
                        }
                    }
                    
                /* This might be triggered when the local party muted or unmuted the video. */
                case .sendingVideo(let isSending):
                    self.isLocalVideoMuted = !isSending
                    if isSending {
                        call.videoRenderViews = (self.selfVideoView, self.remoteVideoView)
                    }
                    DispatchQueue.main.async {
                        self.swapCameraButton.isHidden = !isSending
                        if isSending {
                            self.selfVideoView.alpha = 1
                        } else {
                            self.selfVideoView.alpha = 0
                        }
                    }
                    self.showVideo()
                    
                case .receivingAudio(let isReceiving):
                    print("Rmote is receiving Audio- \(isReceiving)")
                    
                case .receivingVideo(let isReceiving):
                    if !self.isReceivingScreenshare && isReceiving {
                        self.makeFullScreen(self.remoteVideoView)
                    }
                    
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
                case .sendingScreenShare(let startedSending):
                    if startedSending {
                        call.screenShareRenderView = self.screenShareView
                        self.screenShareService?.onSharingStateChanged(call: call)
                    }
                    
                /* This might be triggered when the remote video's speaker has changed.
                 */
                case .activeSpeakerChangedEvent(let from, let to):
                    print("Active speaker changed from \(String(describing: from)) to \(String(describing: to))")
                    
                default:
                    break
                }
            }
        }

        call.onFailed = {
            self.callFailed = true
            self.player.stop()
            let alert = UIAlertController(title: "Call failed!", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.dismiss(animated: true)
            }))
            self.present(alert, animated: true )
        }
        
        call.onDisconnected = { reason in
            print(reason)
            if  !self.callFailed {
                self.player.stop()
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
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
            DispatchQueue.main.async {
                call.videoRenderViews?.local.isHidden = self.onHold
                call.videoRenderViews?.remote.isHidden = self.onHold
                self.selfVideoView.isHidden = self.onHold
                self.remoteVideoView.isHidden = self.onHold
                call.screenShareRenderView?.isHidden = self.onHold
                self.holdButton.backgroundColor = self.onHold ? .systemGray6 : .systemGray2
            }
        }
    }
}

extension CallViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss( _ presentationController: UIPresentationController) {
        if #available(iOS 13, *) {
            makeInitialCallChecks()
        }
    }
}
