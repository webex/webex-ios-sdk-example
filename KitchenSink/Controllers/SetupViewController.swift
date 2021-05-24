import UIKit
import WebexSDK

class SetupViewController: UIViewController {
    var isPreviewing = true
    var isBackgroundConnectionEnabled = UserDefaults.standard.bool(forKey: "backgroundConnection")
    var isFrontCamera = true
    var isComposite = UserDefaults.standard.bool(forKey: "compositeMode")
    
    // MARK: Views
    private var videoView: MediaRenderView = {
        let view = MediaRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Preview
    private lazy var previewSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = isPreviewing
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(previewSwitchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let previewLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "Preview"
        label.text = "Camera"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    private lazy var previewStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [previewLabel, previewSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()
    
    @objc func previewSwitchValueDidChange(_ sender: UISwitch) {
        DispatchQueue.main.async {
            if sender.isOn == true {
                webex.phone.startPreview(view: self.videoView)
            } else {
                webex.phone.stopPreview()
            }
        }
    }
    
    // EnableBackgroundConnection
    private lazy var enableBackgroundConnectionSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = isBackgroundConnectionEnabled
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(enableBackgroundConnectionSwitchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let enableBackgroundConnectionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "Bg Connection"
        label.text = "Background Connection"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    private lazy var enableBackgroundConnectionStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [enableBackgroundConnectionLabel, enableBackgroundConnectionSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()
    
    @objc func enableBackgroundConnectionSwitchValueDidChange(_ sender: UISwitch) {
        DispatchQueue.main.async {
            if sender.isOn == true {
                UserDefaults.standard.setValue(true, forKey: "backgroundConnection")
                webex.phone.enableBackgroundConnection = true
            } else {
                UserDefaults.standard.setValue(false, forKey: "backgroundConnection")
                webex.phone.enableBackgroundConnection = false
            }
        }
    }
    
    // Switch Camera
    private lazy var flipCameraSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = isFrontCamera
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(flipCameraSwitchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let flipCameraLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "Switch Camera"
        label.text = "Front Camera"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    private lazy var flipCameraStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [flipCameraLabel, flipCameraSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()
    
    @objc func flipCameraSwitchValueDidChange(_ sender: UISwitch) {
        DispatchQueue.main.async {
            if sender.isOn == true {
                webex.phone.defaultFacingMode = .user
                self.flipCameraLabel.text = "Front Camera"
            } else {
                webex.phone.defaultFacingMode = .environment
                self.flipCameraLabel.text = "Back Camera"
            }
        }
    }
    
    // Video Stream Mode
    private lazy var videoStreamModeSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = isComposite
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(videoStreamModeSwitchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let videoStreamModeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "Video Stream Mode"
        label.text = "Composite Mode"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    private lazy var videoStreamModeStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [videoStreamModeLabel, videoStreamModeSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()
    
    @objc func videoStreamModeSwitchValueDidChange(_ sender: UISwitch) {
        DispatchQueue.main.async {
            if sender.isOn == true {
                UserDefaults.standard.setValue(true, forKey: "compositeMode")
                webex.phone.videoStreamMode = .composited
                self.videoStreamModeLabel.text = "Composite Mode"
            } else {
                UserDefaults.standard.setValue(false, forKey: "compositeMode")
                webex.phone.videoStreamMode = .auxiliary
                self.videoStreamModeLabel.text = "Auxiliary Mode"
            }
        }
    }
    
    // Call Mode
    private lazy var callModeSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = UserDefaults.standard.bool(forKey: "hasVideo")
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(callModeSwitchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let callModeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "Call Mode"
        label.text = "Start call with video"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    private lazy var callModeStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [callModeLabel, callModeSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()
    
    @objc func callModeSwitchValueDidChange(_ sender: UISwitch) {
        if sender.isOn == true {
            UserDefaults.standard.set(true, forKey: "hasVideo")
        } else {
            UserDefaults.standard.set(false, forKey: "hasVideo")
        }
    }
    
    // Heading
    private let videoStreamHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "Video Stream Mode"
        label.text = "Video Stream Mode: "
        label.font.withSize(35)
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    private let cameraModeHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "Camera Mode"
        label.text = "Camera Mode: "
        label.font.withSize(35)
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        webex.phone.startPreview(view: videoView)
        videoStreamModeLabel.text = isComposite ? "Composite Mode" : "Auxiliary Mode"
    }
    
    func setupViews() {
        view.addSubview(videoView)
        view.addSubview(previewStackView)
        view.addSubview(enableBackgroundConnectionStackView)
        view.addSubview(flipCameraStackView)
        view.addSubview(videoStreamModeStackView)
        view.addSubview(callModeStackView)
        view.addSubview(videoStreamHeaderLabel)
        view.addSubview(cameraModeHeaderLabel)
        view.backgroundColor = .white
    }
    
    func setupConstraints() {
        enableBackgroundConnectionStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        enableBackgroundConnectionStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).activate()
        enableBackgroundConnectionStackView.fillWidth(of: view, padded: 32)
        
        callModeStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        callModeStackView.topAnchor.constraint(equalTo: enableBackgroundConnectionStackView.topAnchor, constant: -50).activate()
        callModeStackView.fillWidth(of: view, padded: 32)
        
        previewStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        previewStackView.topAnchor.constraint(equalTo: callModeStackView.topAnchor, constant: -50).activate()
        previewStackView.fillWidth(of: view, padded: 32)
        
        flipCameraStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        flipCameraStackView.topAnchor.constraint(equalTo: previewStackView.topAnchor, constant: -50).activate()
        flipCameraStackView.fillWidth(of: view, padded: 32)
        
        cameraModeHeaderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        cameraModeHeaderLabel.topAnchor.constraint(equalTo: flipCameraStackView.topAnchor, constant: -20).activate()
        cameraModeHeaderLabel.fillWidth(of: view, padded: 24)
        
        videoStreamModeStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        videoStreamModeStackView.topAnchor.constraint(equalTo: cameraModeHeaderLabel.topAnchor, constant: -50).activate()
        videoStreamModeStackView.fillWidth(of: view, padded: 32)
        
        videoStreamHeaderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        videoStreamHeaderLabel.topAnchor.constraint(equalTo: videoStreamModeStackView.topAnchor, constant: -20).activate()
        videoStreamHeaderLabel.fillWidth(of: view, padded: 24)
        
        videoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).activate()
        videoView.bottomAnchor.constraint(equalTo: videoStreamHeaderLabel.topAnchor, constant: -50).activate()
        videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor).activate()
        videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor).activate()
    }
}
