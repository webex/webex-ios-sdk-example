import UIKit
import AVKit
import WebexSDK

protocol PasswordCaptchaViewViewDelegate: AnyObject {
    func refreshCaptcha(captcha: Phone.Captcha?)
}

class PasswordCaptchaView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    weak var delegate: PasswordCaptchaViewViewDelegate?
    var audioURL: URL?
    var audioPlayer : AVPlayer!
    lazy var hostKeyTextField: UITextField = {
        let field = UITextField(frame: .zero)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.accessibilityIdentifier = "hostKeyTextField"
        field.placeholder = "Host Key"
        field.borderStyle = .roundedRect
        field.text = ""
        field.keyboardType = .emailAddress
        let keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(doneButtonClicked(_:)))
        keyboardDoneButtonView.items = [doneButton]
        field.inputAccessoryView = keyboardDoneButtonView
        return field
    }()
    
    lazy var passwordTextField: UITextField = {
        let field = UITextField(frame: .zero)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.accessibilityIdentifier = "passwordTextField"
        field.placeholder = "Meeting Password"
        field.borderStyle = .roundedRect
        field.text = ""
        field.keyboardType = .emailAddress
        let keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(doneButtonClicked(_:)))
        keyboardDoneButtonView.items = [doneButton]
        field.inputAccessoryView = keyboardDoneButtonView
        return field
    }()
    
    lazy var captchaTextField: UITextField = {
        let field = UITextField(frame: .zero)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.accessibilityIdentifier = "captchaTextField"
        field.placeholder = "Captcha"
        field.borderStyle = .roundedRect
        field.text = ""
        field.keyboardType = .emailAddress
        let keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(doneButtonClicked(_:)))
        keyboardDoneButtonView.items = [doneButton]
        field.inputAccessoryView = keyboardDoneButtonView
        return field
    }()
    
    
    private lazy var audioButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "audioButton"
        var image = UIImage()
        if #available(iOS 13.0, *) {
            image = UIImage(systemName: "speaker.wave.2") ?? UIImage()
        }
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(self.handleAudioButtonAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var refreshButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "refreshButton"
        var image = UIImage()
        if #available(iOS 13.0, *) {
            image = UIImage(systemName: "arrow.clockwise") ?? UIImage()
        }
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(self.handleRefreshButtonAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var captchaImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    
    @objc private func handleAudioButtonAction(_ sender: UIButton) {
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
    
    @objc private func handleRefreshButtonAction(_ sender: UIButton) {
        webex.phone.refreshMeetingCaptcha { [weak self] result in
            switch result {
            case .success(let captcha):
                guard let imageURL = URL.init(string: captcha.imageUrl) else { return }
                self?.downloadImage(from: imageURL) { data in
                    DispatchQueue.main.async {
                        self?.captchaImageView.image = UIImage(data: data)
                        self?.delegate?.refreshCaptcha(captcha: captcha)
                    }
                }
            case .failure(let error):
                print("error" + error.localizedDescription)
            }
            
        }
    }
    
    @objc func doneButtonClicked(_ sender: UISwitch) {
        self.endEditing(true)
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
        downloadTask = URLSession.shared.downloadTask(with: url as URL, completionHandler: { [weak self](URL, response, error) -> Void in
            completionHandler(URL)
        })
        downloadTask.resume()
    }
    
    func setupViews() {
        addSubview(hostKeyTextField)
        addSubview(passwordTextField)
        addSubview(captchaImageView)
        addSubview(audioButton)
        addSubview(refreshButton)
        addSubview(captchaTextField)
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 4
    }
    
    func setupConstraints() {
        var customConstraints: [NSLayoutConstraint] = []
        
        customConstraints.append(captchaImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16))
        customConstraints.append(captchaImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8))
        customConstraints.append(captchaImageView.heightAnchor.constraint(equalToConstant: 60))
        customConstraints.append(captchaImageView.widthAnchor.constraint(equalToConstant: 150))
    
        customConstraints.append(audioButton.leftAnchor.constraint(equalTo: self.captchaImageView.rightAnchor, constant: 10))
        customConstraints.append(audioButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 8))
        customConstraints.append(audioButton.heightAnchor.constraint(equalToConstant: 40))
        customConstraints.append(audioButton.widthAnchor.constraint(equalToConstant: 40))
        
        customConstraints.append(refreshButton.leftAnchor.constraint(equalTo: self.audioButton.rightAnchor, constant: 10))
        customConstraints.append(refreshButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 8))
        customConstraints.append(refreshButton.heightAnchor.constraint(equalToConstant: 40))
        customConstraints.append(refreshButton.widthAnchor.constraint(equalToConstant: 40))
        
        customConstraints.append(captchaTextField.centerXAnchor.constraint(equalTo: self.centerXAnchor))
        customConstraints.append(captchaTextField.topAnchor.constraint(equalTo: captchaImageView.bottomAnchor, constant: 8))
        captchaTextField.fillWidth(of: self, padded: 16)
        
        customConstraints.append(passwordTextField.centerXAnchor.constraint(equalTo: self.centerXAnchor))
        customConstraints.append(hostKeyTextField.centerXAnchor.constraint(equalTo: self.centerXAnchor))

        if captchaTextField.isHidden {
            customConstraints.append(passwordTextField.topAnchor.constraint(equalTo: self.topAnchor, constant: 8))
            passwordTextField.fillWidth(of: self, padded: 16)
            customConstraints.append(hostKeyTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 8))
            hostKeyTextField.fillWidth(of: self, padded: 16)
        } else {
            customConstraints.append(passwordTextField.topAnchor.constraint(equalTo: captchaTextField.bottomAnchor, constant: 8))
            passwordTextField.fillWidth(of: self, padded: 16)
            customConstraints.append(hostKeyTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 8))
            hostKeyTextField.fillWidth(of: self, padded: 16)
        }
      
        NSLayoutConstraint.activate(customConstraints)
    }

    
    func setupViewForPassword() {
        self.captchaTextField.isHidden = true
        self.audioButton.isHidden = true
        self.refreshButton.isHidden = true
        setupConstraints()
    }
    
    func setupViewForPasswordAndCaptcha() {
        self.captchaTextField.isHidden = false
        self.audioButton.isHidden = false
        self.refreshButton.isHidden = false
        setupConstraints()
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
                self?.captchaImageView.image = UIImage(data: data)
            }
        }
    }
}
