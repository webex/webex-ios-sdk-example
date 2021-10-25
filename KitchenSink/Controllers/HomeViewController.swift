import MessageUI
import UIKit
import WebexSDK

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    // MARK: Properties
    fileprivate enum Feedback: CaseIterable {
        static let recipient = "webex-mobile-sdk@cisco.com"
        
        case reportBug, featureRequest
        
        var title: String {
            switch self {
            case .reportBug: return "Bug Report"
            case .featureRequest: return "Feature Request"
            }
        }
    }
    weak var webexUCLoginDelegate = webex.ucLoginDelegate
    private let kCellId: String = "FeatureCell"
    
    private lazy var features: [Feature] = [
        Feature(title: "UC Login", icon: "sign-in", tileColor: .momentumBlue50, action: { [weak self] in
            self?.setPreferencesForUCLogin()
        }),
        Feature(title: "Initiate Call", icon: "outgoing-call", tileColor: .momentumGreen50, action: { [weak self] in
            self?.navigationController?.pushViewController(InitiateCallViewController(), animated: true)
        }),
        Feature(title: "Waiting Call", icon: "incoming-call", tileColor: .momentumYellow50, action: { [weak self] in
            self?.navigationController?.pushViewController(ScheduledMeetingViewController(), animated: true)
        }),
        Feature(title: "Messaging", icon: "bubble-left", tileColor: .momentumMint50, action: { [weak self] in
            self?.navigationController?.pushViewController(MessagingViewController(), animated: true)
        }),
        Feature(title: "Send Feedback", icon: "feedback", tileColor: .momentumOrange50, action: { [weak self] in
            self?.manageFeedback()
        }),
        Feature(title: "Extras", icon: "webhook", tileColor: .momentumGold50, action: { [weak self] in
            self?.navigationController?.pushViewController(ExtrasViewController(), animated: true)
        }),
        Feature(title: "Logout", icon: "sign-out", tileColor: .momentumRed50, action: {
            webex.authenticator?.deauthorize {
                DispatchQueue.main.async { [weak self] in
                    guard let appDelegate = (UIApplication.shared.delegate as? AppDelegate) else { fatalError() }
                    self?.navigationController?.dismiss(animated: true)
                    UserDefaults.standard.removeObject(forKey: "loginType")
                    UserDefaults.standard.removeObject(forKey: "userEmail")
                    appDelegate.navigateToLoginViewController()
                }
            }
        })
    ]
    
    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor

        title = "Kitchen Sink"
        navigationController?.navigationBar.prefersLargeTitles = true
        setupViews()
        setupConstraints()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            self.deviceRegistration()
        })
        if !UserDefaults.standard.bool(forKey: "addedCustomBg") {
            addCustomBackground()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let status = webex.getUCServerConnectionStatus()
        ucServerConnectionSuccess(status: status)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        webex.ucLoginDelegate = self
        webex.messages.onEvent = { messageEvent in
            switch messageEvent {
            case .messageReceived(let message):
                var messageAlertText = "The message is: "
                
                messageAlertText += (message.text ?? "" + "\n")
                
                let alert = UIAlertController(title: "New Message Arrived", message: messageAlertText, preferredStyle: .alert)
                
                alert.addAction(.init(title: "dismiss", style: .cancel, handler: { _ in
                    alert.dismiss(animated: true, completion: nil)
                }))
//             Uncomment this to get incoming message alerts
//                self.present(alert, animated: true)
                
            default:
                break
            }
        }
        
        UIView.animate(withDuration: 2, animations: { [weak self] in
            self?.currentUserButton.alpha = 1
        }, completion: { _ in
            webex.people.getMe(completionHandler: { [weak self] in
                switch $0 {
                case .success(let user):
                    self?.currentUserButton.setTitle(user.initials, for: .normal)
                    self?.currentUserButton.layer.borderWidth = 2
                case .failure(let error):
                    let userAlert = UIAlertController(title: "Error", message: "Error getting current user: " + error.localizedDescription, preferredStyle: .alert)
                    userAlert.addAction(.dismissAction(withTitle: "Ok"))
                    self?.present(userAlert, animated: true, completion: nil)
                }
            })
        })
    }
    
    // MARK: CollectionView Datasource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return features.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellId, for: indexPath) as? FeatureCollectionViewCell else { return UICollectionViewCell() }
        cell.setupCell(with: features[indexPath.item])
        return cell
    }
    
    // MARK: CollectionView Delegates
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        features[indexPath.item].action()
    }
    
    // MARK: Views and Constraints
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumLineSpacing = 32
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .backgroundColor
        view.dataSource = self
        view.delegate = self
        view.register(FeatureCollectionViewCell.self, forCellWithReuseIdentifier: kCellId)
        return view
    }()
    
    private let userButtonWidth: CGFloat = 80
    private lazy var currentUserButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitleColor(.lightText, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 28)
        button.backgroundColor = .darkGray
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = userButtonWidth / 2
        button.layer.borderColor = UIColor.momentumGreen40.cgColor
        button.alpha = 0
        button.addTarget(self, action: #selector(getMyDetails), for: .touchUpInside)
        return button
    }()
    
    private lazy var ucConnectionStatusLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = ""
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title2)
        label.isHidden = true
        return label
    }()
    
    func setupViews() {
        view.addSubview(ucConnectionStatusLabel)
        view.addSubview(collectionView)
        view.addSubview(currentUserButton)
    }
    
    func setupConstraints() {
        let rowHeight = features.count.isMultiple(of: 3) ? (features.count / 3) * 135 : ((features.count / 3) + 1) * 135
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: CGFloat(rowHeight)),
            
            currentUserButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            currentUserButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(UIScreen.main.bounds.height / 7)),
            currentUserButton.widthAnchor.constraint(equalToConstant: userButtonWidth),
            currentUserButton.heightAnchor.constraint(equalToConstant: userButtonWidth),
            
            ucConnectionStatusLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            ucConnectionStatusLabel.topAnchor.constraint(equalTo: currentUserButton.bottomAnchor, constant: 20)
        ])
    }
}

// MARK: UC Login
extension HomeViewController {
    func setPreferencesForUCLogin() {
        if webex.isUCLoggedIn() {
            let alert = UIAlertController(title: "UC Services", message: "Already logged in", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true )
        } else {
            let alert = UIAlertController(title: "UC Login", message: "Enter UC Domain or Server Address to proceed", preferredStyle: .alert)
            var ucDomain: String?
            var serverAddress: String?
            alert.addTextField { textField in
                textField.placeholder = "Enter UC Domain"
                ucDomain = textField.text
            }
            alert.addTextField { textField in
                textField.placeholder = "Enter Server Address"
                serverAddress = textField.text
            }
            alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { [weak self] _ in
                ucDomain = alert.textFields![0].text
                serverAddress = alert.textFields![1].text
                webex.ucLoginDelegate = self
                webex.setUCDomainServerUrl(ucDomain: ucDomain ?? "", serverUrl: serverAddress ?? "")
            }))
            self.present(alert, animated: true)
        }
    }
    
    func nonSSOLogin() {
        let alert = UIAlertController(title: "UC Login", message: "Enter username and password to proceed", preferredStyle: .alert)
        var username: String?
        var password: String?
        alert.addTextField { textField in
            textField.placeholder = "Enter your username"
            username = textField.text
        }
        alert.addTextField { textField in
            textField.placeholder = "Enter password"
            password = textField.text
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Login", style: UIAlertAction.Style.default, handler: { _ in
            guard let username = username, let password = password else { return }
            webex.setCUCMCredential(username: username, password: password)
        }))
        self.present(alert, animated: true)
    }
    
    public func successUCLogin (success: Bool?) {
        var message = "Login Successful"
        guard let success = success else { return }
        if !success {
            message = "Login Failed"
        }
        let alert = UIAlertController(title: "UC Services", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true )
    }
    
    public func showSSOLogin(url: String) {
        webexUCLoginDelegate?.showUCSSOLoginView(to: url)
    }
    
    public func ucServerConnectionSuccess(status: UCLoginServerConnectionStatus, failureReason: PhoneServiceRegistrationFailureReason? = nil ) {
        ucConnectionStatusLabel.isHidden = true
        if let failureReason = failureReason, failureReason != .None {
            ucConnectionStatusLabel.textColor = .momentumRed50
            ucConnectionStatusLabel.text = "UC connection status: \(status). \n Reason: \(failureReason)"
        } else {
            ucConnectionStatusLabel.textColor = .momentumGreen50
            ucConnectionStatusLabel.text = "UC connection status: \(status)"
        }
        ucConnectionStatusLabel.isHidden = false
    }
}

// MARK: Webex Delegate
extension HomeViewController: WebexUCLoginDelegate {
    func onUCLoginFailed() {
        successUCLogin(success: false)
    }
    
    func onUCServerConnectionStateChanged(status: UCLoginServerConnectionStatus, failureReason: PhoneServiceRegistrationFailureReason) {
        ucServerConnectionSuccess(status: status, failureReason: failureReason)
    }
    
    func showUCSSOLoginView(to url: String) {
        webex.getUCSSOLoginView(parentViewController: self, ssoUrl: url, completionHandler: successUCLogin(success:))
    }
    
    func showUCNonSSOLoginView() {
        nonSSOLogin()
    }
        
    func onUCLoggedIn() {
        successUCLogin(success: true)
    }
        
    func onUcSSONavigate(to url: String) {
        print("on uc sso navigate to")
    }
}

// MARK: Feedback
extension HomeViewController {
    func manageFeedback() {
        let alert = UIAlertController(title: nil, message: "Choose Topic", preferredStyle: .actionSheet)
        Feedback.allCases.forEach { feedback in
            alert.addAction(UIAlertAction(title: feedback.title, style: .default, handler: { [weak self] _ in self?.configureMail(for: feedback) }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func configureMail(for feedback: Feedback) {
        MFMailComposeViewController.canSendMail() ? sendMailViaComposer(feedback) : sendViaBrowser(feedback)
    }
    
    private func sendMailViaComposer(_ feedback: Feedback) {
        let controller = MFMailComposeViewController()
        controller.setSubject(feedback.title)
        controller.setToRecipients([Feedback.recipient])
    
        // add log file as attachment
        if let logFileUrl = webex.getLogFileUrl(), let fileContents = NSData(contentsOf: logFileUrl) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .long
            
            let fileName = "webex-sdk-ios-logs-" + dateFormatter.string(from: Date()) + ".zip"
            controller.addAttachmentData(fileContents as Data, mimeType: "application/zip", fileName: fileName)
        }
        controller.mailComposeDelegate = self
        present(controller, animated: true)
    }
    
    private func sendViaBrowser(_ feedback: Feedback) {
        let mailURLString = "mailto:\(Feedback.recipient)?subject=\(feedback.title)"
        guard let encodedString = mailURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: encodedString),
            UIApplication.shared.canOpenURL(url)
        else {
            showSendMailErrorAlert()
            return
        }
        UIApplication.shared.open(url, options: [:])
    }
    
    private func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        sendMailErrorAlert.addAction(okAction)
        present(sendMailErrorAlert, animated: true)
    }
    
    @objc public func getMyDetails() {
        present(GetMeViewController(), animated: true, completion: nil)
    }
}

extension HomeViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true)
    }
}

extension WebexSDK.Person {
    var initials: String {
        if let first = firstName?.first, let last = lastName?.first, !first.isWhitespace, !last.isWhitespace {
            return "\(first)\(last)"
        }
        
        // Currently Designed to work for a name structured as "First Last"
        if let displayName = displayName, !displayName.isEmpty {
            let nameInWords = displayName.split(separator: " ")
            if nameInWords.count > 1 {
                return "\(nameInWords[0].first?.description ?? "")\(nameInWords[1].first?.description ?? "")"
            } else {
                return displayName.first?.uppercased() ?? ""
            }
        }
        
        return "👨🏻‍💻"
    }
}

extension HomeViewController {
    func deviceRegistration() {
        webex.people.getMe(completionHandler: { result in
            guard let person = result.data, let personId = person.id, let emails = person.emails, let emailId = emails.first?.toString() else {
                print("Unable to register User for Push notifications with webhook handling server because of missing emailId or person details")
                return
            }
            
            let Url = String(format: "https://fierce-forest-67615.herokuapp.com/register")
            guard let serviceUrl = URL(string: Url), let token = token, let voipToken = voipToken else { return }
            let parameters: [String: Any] = [
                "voipToken": voipToken,
                "msgToken": token,
                "email": emailId,
                "personId": personId
            ]
            var request = URLRequest(url: serviceUrl)
            request.httpMethod = "POST"
            request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
            guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                return
            }
            request.httpBody = httpBody
            request.timeoutInterval = 20
            let session = URLSession.shared
            session.dataTask(with: request) { (data, response, error) in
                if let response = response {
                    print("DEVICE REGISTRATION: \(response)")
                }
            }.resume()
        })
    }
    
    func addCustomBackground() {
        let  fileName = "Background"
        let image = UIImage(named: "background-test")!
        let resizedthumbnail = image.resizedImage(for: CGSize(width: 64, height: 64))

        guard let imageData = image.pngData() else { return }
        let path = FileUtils.writeToFile(data: imageData, fileName: fileName)
        guard let imagePath = path?.absoluteString.replacingOccurrences(of: "file://", with: "") else { print("Failed to process image path"); return }

        guard let thumbnailData = resizedthumbnail?.pngData() else { return }
        let thumbnailFilePath = FileUtils.writeToFile(data: thumbnailData, fileName: "thumbnail\(fileName)")
        guard let thumbnailPath = thumbnailFilePath?.absoluteString.replacingOccurrences(of: "file://", with: "") else { print("Failed to process thumbnail path"); return }
        
        let thumbnail = LocalFile.Thumbnail(path: thumbnailPath, mime: "png", width: Int(image.size.width), height: Int(image.size.height))
        guard let localFile = LocalFile(path: imagePath, name: fileName, mime: "png", thumbnail: thumbnail) else { print("Failed to get local file"); return }
        
        webex.phone.addVirtualBackground(image: localFile, completionHandler: { result in
            switch result {
            case .success(let newItem):
                UserDefaults.standard.setValue(true, forKey: "addedCustomBg")
                print("new background item: \(newItem)")
            case .failure(let error):
                print("Failed uploading background with error: \(error)")
            @unknown default:
                print("Failed uploading background")
            }
        })
    }
}
