import UIKit
import WebexSDK

class SetupViewController: UIViewController {
    var isPreviewing = true
    
    // MARK: Views
    private var videoView: MediaRenderView = {
        let view = MediaRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var previewButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(handleStartStopAction), for: .touchUpInside)
        view.setTitle("Stop", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumBlue50
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var frontButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(handleFrontAction), for: .touchUpInside)
        view.setTitle("Front", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var backButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(handleBackAction), for: .touchUpInside)
        view.setTitle("Back", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [frontButton, backButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.alignment = .center
        stack.distribution = .fillEqually
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        webex.phone.startPreview(view: videoView)
        if webex.phone.defaultFacingMode == .user {
            frontButton.isEnabled = false
            frontButton.backgroundColor = .momentumRed50

            backButton.isEnabled = true
            backButton.backgroundColor = .momentumBlue50
        } else {
            frontButton.isEnabled = true
            frontButton.backgroundColor = .momentumBlue50

            backButton.isEnabled = false
            backButton.backgroundColor = .momentumRed50
        }
    }

    @objc func handleStartStopAction() {
        isPreviewing.toggle()
        DispatchQueue.main.async {
            if self.isPreviewing {
                webex.phone.startPreview(view: self.videoView)
                self.previewButton.setTitle("Stop", for: .normal)
                self.videoView.isHidden = false
            } else {
                webex.phone.stopPreview()
                self.previewButton.setTitle("Start", for: .normal)
                self.videoView.isHidden = true
            }
        }
    }
    
    @objc func handleFrontAction() {
        webex.phone.defaultFacingMode = .user
        frontButton.isEnabled = false
        frontButton.backgroundColor = .momentumRed50
        
        backButton.isEnabled = true
        backButton.backgroundColor = .momentumBlue50
    }
    
    @objc func handleBackAction() {
        webex.phone.defaultFacingMode = .environment
        frontButton.isEnabled = true
        frontButton.backgroundColor = .momentumBlue50
        
        backButton.isEnabled = false
        backButton.backgroundColor = .momentumRed50
    }
    
    func setupViews() {
        view.addSubview(videoView)
        view.addSubview(previewButton)
        view.addSubview(stackView)
    }
    
    func setupConstraints() {
        videoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).activate()
        videoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).activate()
        videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor).activate()
        videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor).activate()
        
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 100).activate()
        stackView.fillWidth(of: view, padded: 64)
        
        previewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        previewButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 30).activate()
        previewButton.fillWidth(of: view, padded: 64)
    }
}
