import AVKit
import UIKit
import WebexSDK
class IncomingCallViewController: UIViewController {
    var currentCallId: String?
    var space: Space?
    var player: AVAudioPlayer?
    var call: Call?
    
    private var startedByIncomingCall = false
    
    // MARK: Initializers
    convenience init(incomingCallId callId: String) {
        self.init()
        guard !callId.isEmpty, let call = webex.phone.getCall(callId: callId) else {
            print("Call not found for callId: \(callId)")
            return
        }
        self.call = call
        handleIncomingCall(call)
        startedByIncomingCall = true
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Views
    private var waitingLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Waiting for call..."
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()
    
    private var callingLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Incoming call..."
        label.font = .preferredFont(forTextStyle: .headline)
        label.isHidden = true
        return label
    }()
    
    private var nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title1)
        label.text = "Caller Name"
        label.isHidden = true
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [connectCallButton, endCallButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 120
        stack.alignment = .center
        stack.isHidden = true
        return stack
    }()
    
    private var connectCallButton: CallButton = {
        let button = CallButton(style: .cta, size: .medium, type: .connectCall)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(84)
        button.setHeight(84)
        button.addTarget(self, action: #selector(handleConnectCallAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private var endCallButton: CallButton = {
        let button = CallButton(style: .cta, size: .medium, type: .endCall)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(84)
        button.setHeight(84)
        button.addTarget(self, action: #selector(handleEndCallAction(_:)), for: .touchUpInside)
        return button
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if startedByIncomingCall {
            // Need not reset view in this case
            startedByIncomingCall = false
            return
        }
        toggleIncomingCallView(show: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        setupViews()
        setupConstraints()
        getIncomingCall()
    }
    
    // MARK: Actions
    @objc private func handleConnectCallAction(_ sender: UIButton) {
        self.player?.stop()
        guard let space = space, let currentCallId = currentCallId else { return }
        let callVC = CallViewController(space: space, addedCall: false, currentCallId: currentCallId, incomingCall: true, call: call)
        self.present(callVC, animated: true)
    }
    
    @objc private func handleEndCallAction(_ sender: UIButton) {
        call?.reject(completionHandler: { error in
            if error == nil {
                self.dismiss(animated: true)
            } else {
                let alert = UIAlertController(title: "Error", message: error.debugDescription, preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Ok"))
                self.present(alert, animated: true)
                return
            }
        })
    }
    
    private func setupViews() {
        view.addSubview(waitingLabel)
        view.addSubview(callingLabel)
        view.addSubview(nameLabel)
        view.addSubview(stackView)
    }
    
    private func toggleIncomingCallView(show: Bool) {
        waitingLabel.isHidden = show
        nameLabel.isHidden = !show
        callingLabel.isHidden = !show
        stackView.isHidden = !show
    }
    
    private func handleIncomingCall(_ call: Call) {
        toggleIncomingCallView(show: true)
        currentCallId = call.callId
        space = Space(id: call.conversationId ?? "", title: call.title ?? "")
        nameLabel.text = call.title
        webexCallStatesProcess(call: call)
    }
    
    private func setupConstraints() {
        waitingLabel.alignCenter()

        callingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        callingLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100).activate()
        
        nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        nameLabel.topAnchor.constraint(equalTo: callingLabel.topAnchor, constant: 44).activate()
        
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -140).activate()
    }
    
    func getIncomingCall() {
        webex.phone.onIncoming = { call in
            DispatchQueue.main.async {
                self.startRinging()
            }
            self.call = call
            self.handleIncomingCall(call)
        }
    }
    
    func startRinging() {
        let path = Bundle.main.path(forResource: "call_1_1_ringtone", ofType: "wav")!
        let url = URL(fileURLWithPath: path)
        do {
            self.player = try AVAudioPlayer(contentsOf: url)
            self.player?.numberOfLoops = -1
            self.player?.prepareToPlay()
            self.player?.play()
        } catch {
            print("There is an issue with ringtone")
        }
    }
    
    func webexCallStatesProcess(call: Call) {
        call.onFailed = {
            self.player?.stop()
            let alert = UIAlertController(title: "Call failed!", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                self?.toggleIncomingCallView(show: false)
            }))
            self.present(alert, animated: true )
        }
        
        call.onDisconnected = { reason in
            print(reason)
            self.player?.stop()
            self.toggleIncomingCallView(show: false)
        }
    }
}
