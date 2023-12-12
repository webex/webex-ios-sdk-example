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
    private var isUCServicesStarted = false
    private var isSSOLogin = false
    
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
            webex.authenticator?.deauthorize(completionHandler: {
                DispatchQueue.main.async { [weak self] in
                    guard let appDelegate = (UIApplication.shared.delegate as? AppDelegate) else { fatalError() }
                    self?.navigationController?.dismiss(animated: true)
                    UserDefaults.standard.removeObject(forKey: "loginType")
                    UserDefaults.standard.removeObject(forKey: "userEmail")
                    UserDefaults.standard.removeObject(forKey: "isFedRAMP")
                    appDelegate.navigateToLoginViewController()
                }
            })
        })
    ]

    private let versionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "versionLabel"
        label.adjustsFontSizeToFitWidth = true
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = .labelColor
        return label
    }()
    
    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        let capability = webex.people.getProductCapability()
        print("Product Capability: \(capability.isMeetingSupported)")
        view.backgroundColor = .backgroundColor

        title = "Kitchen Sink"
        navigationController?.navigationBar.prefersLargeTitles = true
        let bundleVersion = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        versionLabel.text = "v\(Webex.version) (\(bundleVersion))"
        setupViews()
        setupConstraints()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            self.deviceRegistration()
        })
        if !UserDefaults.standard.bool(forKey: "addedCustomBg") {
            addCustomBackground()
        }
        setIncomingCallListener()
        
        if webex.phone.getCallingType() == .WebexCalling || webex.phone.getCallingType() == .WebexForBroadworks {
            connectWxCButton.isHidden = false
            disconnectWxCButton.isHidden = false
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
        webex.startUCServices()
        isUCServicesStarted = true
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
                    UserDefaults.standard.set(user.id, forKey: "selfId")
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
    
    private lazy var connectWxCButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitleColor(.lightText, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitle("Connect", for: .normal)
        button.backgroundColor = .momentumBlue50
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 10
        button.isHidden = true
        button.addTarget(self, action: #selector(connectPhoneService), for: .touchUpInside)
        return button
    }()
    
    private lazy var disconnectWxCButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitleColor(.lightText, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitle("Disconnect", for: .normal)
        button.backgroundColor = .momentumRed50
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 10
        button.isHidden = true
        button.addTarget(self, action: #selector(disconnectPhoneService), for: .touchUpInside)
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
        view.addSubview(connectWxCButton)
        view.addSubview(disconnectWxCButton)
        view.addSubview(versionLabel)
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
            
            connectWxCButton.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 20),
            connectWxCButton.centerYAnchor.constraint(equalTo: currentUserButton.centerYAnchor),
            connectWxCButton.widthAnchor.constraint(equalToConstant: 100),
            connectWxCButton.heightAnchor.constraint(equalToConstant: 40),
            
            disconnectWxCButton.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor, constant: -20),
            disconnectWxCButton.centerYAnchor.constraint(equalTo: currentUserButton.centerYAnchor),
            disconnectWxCButton.widthAnchor.constraint(equalToConstant: 100),
            disconnectWxCButton.heightAnchor.constraint(equalToConstant: 40),
            
            ucConnectionStatusLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            ucConnectionStatusLabel.topAnchor.constraint(equalTo: currentUserButton.bottomAnchor, constant: 20),

            versionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            versionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}

// MARK: UC Login
extension HomeViewController {
    func setPreferencesForUCLogin() {
        let isUCLoggedIn = webex.isUCLoggedIn()
        if isUCServicesStarted && isSSOLogin && !isUCLoggedIn
        {
            webex.retryUCSSOLogin()
        }
        else if isUCLoggedIn {
            let alert = UIAlertController(title: "UC Services", message: "Already logged in", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true )
        } else {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "UC Login", message: "Enter UC Domain or Server Address to proceed", preferredStyle: .alert)
                var ucDomainTF: UITextField?
                var serverAddressTF: UITextField?
                alert.addTextField { textField in
                    textField.placeholder = "Enter UC Domain"
                    ucDomainTF = textField
                }
                alert.addTextField { textField in
                    textField.placeholder = "Enter Server Address"
                    serverAddressTF = textField
                }
                alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { [weak self] _ in
                    let ucDomain = ucDomainTF?.text ?? ""
                    let serverAddress = serverAddressTF?.text ?? ""
                    webex.ucLoginDelegate = self
                    webex.setUCDomainServerUrl(ucDomain: ucDomain, serverUrl: serverAddress)
                }))
                self.present(alert, animated: true)
            }
        }
    }
    
    func nonSSOLogin() {
        let alert = UIAlertController(title: "UC Login", message: "Enter username and password to proceed", preferredStyle: .alert)
        var usernameTF: UITextField?
        var passwordTF: UITextField?

        alert.addTextField { textField in
            textField.placeholder = "Enter your username"
            usernameTF = textField
        }
        alert.addTextField { textField in
            textField.placeholder = "Enter password"
            passwordTF = textField
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Login", style: UIAlertAction.Style.default, handler: { _ in
            
            let username = usernameTF?.text ?? ""
            let password = passwordTF?.text ?? ""
            if username.isEmpty || password.isEmpty {
                alert.title = "Invalid credentials. Try again"
                return
            }
            webex.setCallServiceCredential(username: username, password: password)
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
        webexUCLoginDelegate?.loadUCSSOView(to: url)
    }
    
    public func ucServerConnectionSuccess(status: UCLoginServerConnectionStatus, failureReason: PhoneServiceRegistrationFailureReason? = nil ) {
        ucConnectionStatusLabel.isHidden = true
        if let failureReason = failureReason, failureReason != .None {
            ucConnectionStatusLabel.textColor = .momentumRed50
            ucConnectionStatusLabel.text = "Phone Services: \(status). \n Reason: \(failureReason)"
            if failureReason == .RegisteredElsewhere {
                DispatchQueue.main.async {
                    self.handleForceRegisterPhoneServicesPopup()
                }
            }
        } else {
            ucConnectionStatusLabel.textColor = .momentumGreen50
            ucConnectionStatusLabel.text = "Phone Services: \(status)"
        }
        ucConnectionStatusLabel.isHidden = false
    }
    
    func handleForceRegisterPhoneServicesPopup() {
        let alert = UIAlertController.actionSheetWith(title: "Force Register Phone Services", message: "This will log you out of phone services from your other iOS devices and force register on this device", sourceView: self.view)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in webex.forceRegisterPhoneServices()
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}

// MARK: Webex Delegate
extension HomeViewController: WebexUCLoginDelegate {
    func onUCSSOLoginFailed(failureReason: UCSSOFailureReason) {
        print("UC SSOLoginFailed \(failureReason)")
        webex.retryUCSSOLogin()
    }
    
    func onUCLoginFailed(failureReason: UCLoginFailureReason) {
        print("UC login failed \(failureReason)")
    }
    
    func onUCServerConnectionStateChanged(status: UCLoginServerConnectionStatus, failureReason: PhoneServiceRegistrationFailureReason) {
        ucServerConnectionSuccess(status: status, failureReason: failureReason)
    }
    
    func loadUCSSOView(to url: String) {
        isSSOLogin = true
        webex.getUCSSOLoginView(parentViewController: self, ssoUrl: url, completionHandler: successUCLogin(success:))
    }
    
    func showUCNonSSOLoginView() {
        DispatchQueue.main.async {
            self.nonSSOLogin()
        }
    }
        
    func onUCLoggedIn() {
        successUCLogin(success: true)
    }
        
    func onUcSSONavigate(to url: String) {
        print("on uc sso navigate to")
    }
    
    @objc func connectPhoneService() {
        webex.phone.connectPhoneServices(completionHandler: { result in
            switch result {
                case .success:
                    print("Request completed successfully")
                case .failure:
                print("Error connecting \(result.error.debugDescription)")
            }
        })
    }
    
    @objc func disconnectPhoneService() {
        webex.phone.disconnectPhoneServices(completionHandler: { result in
            switch result {
                case .success:
                    print("Request completed successfully")
                case .failure:
                print("Error disconnecting \(result.error.debugDescription)")
            }
        })
    }
}

// MARK: Feedback
extension HomeViewController {
    func manageFeedback() {
        let alert = UIAlertController.actionSheetWith(title: "Choose Topic", message: nil, sourceView: self.view)
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
               guard let person = result.data, let personId = person.encodedId else {
                   print("Unable to register User for Push notifications with webhook handling server because of missing emailId or person details")
                   return
               }
               guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") else { return }
               guard let keys = NSDictionary(contentsOfFile: path) else { return }
               guard let token = token, let voipToken = voipToken else { return }

               if let urlString = keys["registerationUrl"] as? String  {
                   guard let serviceUrl = URL(string: urlString) else { print("Invalid URL"); return }

                   let parameters: [String: Any] = [
                       "voipToken": voipToken,
                       "deviceToken": token,
                       "pushProvider": "APNS",
                       "userId": personId,
                       "prod": false
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
               }
               else {
                   let bundleId = keys["bundleId"] as? String ?? ""

                   webex.phone.setPushTokens(bundleId: bundleId, deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "", deviceToken: token, voipToken: voipToken, appId: nil)
                   return
               }
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

extension HomeViewController {  // waiting call related code
    func setIncomingCallListener() {
        webex.phone.onIncoming = { call in
            if call.isWebexCallingOrWebexForBroadworks {
                if CallObjectStorage.shared.getAllActiveCalls().count > 0
                {
                    voipUUID = UUID()
                    AppDelegate.shared.callKitManager?.reportIncomingCallFor(uuid: voipUUID!, sender: call.title ?? "") {
                    AppDelegate.shared.callKitManager?.updateCall(call: call, voipUUID: voipUUID)
                        return
                    }
                }
                print("webex.phone.onIncoming calll \(String(describing: call.callId))")
                AppDelegate.shared.callKitManager?.updateCall(call: call)
                return
            }
            print("onIncoming Call object :  + \(call.callId ?? "")  ,  correlationId : \(call.correlationId ?? "") , externalTrackingId:  + \(call.externalTrackingId ?? "")")
            CallObjectStorage.self.shared.addCallObject(call: call)
            call.onScheduleChanged = { c in
                self.getUpdatedSchedule(call: c)
                self.notifyIncomingCallListChanged(true)
            }
            self.getUpdatedSchedule(call: call)
            self.webexCallStatesProcess(call: call)
            self.notifyIncomingCallListChanged(true)
        }
        webex.calendarMeetings.onEvent = { event in // remove meeting if cancelled
                    switch event {
                    case .created(let meeting):
                    print(meeting)
                    case .updated(let meeting):
                    print(meeting)
                    case .removed(let meetingId):
                    incomingCallData = incomingCallData.filter { $0.meetingId != meetingId }
                    self.notifyIncomingCallListChanged(false)
                    @unknown default:
                        break
                    }
        }
    }
    
    func notifyIncomingCallListChanged(_ ring: Bool) {
        NotificationCenter.default.post(name: Notification.Name("IncomingCallListChanged"), object: nil, userInfo: ["ring": ring])
    }
    
    func getUpdatedSchedule(call: Call) {
        guard let callSchedule = call.schedules else {
            // Case : One to one call ( Only utilizes the title, Space, callId and isScheduledCall)
            let newCall = Meeting(organizer: call.title ?? "", start: Date(), end: Date(), meetingId: "", link: "", subject: "", isScheduledCall: false, space: Space(id: call.spaceId ?? "", title: call.title ?? ""), currentCallId: call.callId ?? "")
            // Flag to check if meeting is already scheduled (To enter change in the schedule)
            var isExistingScheduleModified = false
            for (rowNumber, var _) in incomingCallData.enumerated() where newCall.currentCallId == incomingCallData[rowNumber].currentCallId {
                // Use meeting Id to check if it already exists
                incomingCallData.remove(at: rowNumber)
                incomingCallData.append(newCall)
                isExistingScheduleModified = true
                break
            }
            if !isExistingScheduleModified {
                // Append new Scheduled Meeting
                incomingCallData.append(newCall)
            }
            self.notifyIncomingCallListChanged(true)
            return
        }

        // Case 2 : Scheduled Meeting
        for item in callSchedule {
            let newMeetingId = Meeting(organizer: item.organzier ?? "", start: item.start, end: item.end, meetingId: item.meetingId ?? "", link: item.link ?? "", subject: item.subject ?? "", isScheduledCall: true, space: Space(id: call.spaceId ?? "", title: call.title ?? ""), currentCallId: call.callId ?? "")
            // Flag to check if meeting is already scheduled (To enter change in the schedule)
            var isExistingScheduleModified = false
            for (rowNumber, var _) in incomingCallData.enumerated() where (newMeetingId.currentCallId == incomingCallData[rowNumber].currentCallId || newMeetingId.meetingId == incomingCallData[rowNumber].meetingId) {
                // Use meeting Id to check if it already exists
                incomingCallData.remove(at: rowNumber)
                incomingCallData.append(newMeetingId)
                isExistingScheduleModified = true
                break
            }
            if !isExistingScheduleModified {
                // Append new Scheduled Meeting
                incomingCallData.append(Meeting(organizer: item.organzier ?? "", start: item.start, end: item.end, meetingId: item.meetingId ?? "", link: item.link ?? "", subject: item.subject ?? "", isScheduledCall: true, space: Space(id: call.spaceId ?? "", title: call.title ?? ""), currentCallId: call.callId ?? ""))
                break
            }
        }
    }
    
    func webexCallStatesProcess(call: Call) {
        call.onFailed = { [self] reason in
            print(reason)
            incomingCallData = incomingCallData.filter { $0.currentCallId != call.callId }
            self.notifyIncomingCallListChanged(false)
        }
        
        call.onDisconnected = { [self] reason in
            switch reason {
            case .callEnded:
                CallObjectStorage.self.shared.removeCallObject(callId: call.callId ?? "")
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
            incomingCallData = incomingCallData.filter { $0.currentCallId != call.callId }
            self.notifyIncomingCallListChanged(false)
        }
    }
}
