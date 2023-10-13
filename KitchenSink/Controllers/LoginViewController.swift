import UIKit
import WebexSDK
import SwiftUI

class LoginViewController: UIViewController {
    private var launchMessageInfo: (messageId: String, spaceId: String)?
    private var launchWebexCallId: String?
    private var launchCUCMCallId: String?
    private var isFedRAMPMode: Bool = false

    private var ciscoLogoView: UIImageView = {
        let ciscoLogo = UIImageView(frame: .zero)
        ciscoLogo.translatesAutoresizingMaskIntoConstraints = false
        ciscoLogo.contentMode = .scaleAspectFit
        ciscoLogo.image = UIImage(named: "cisco-logo")
        return ciscoLogo
    }()
    
    private var webexLogoView: UIImageView = {
        let webexLogo = UIImageView(frame: .zero)
        webexLogo.translatesAutoresizingMaskIntoConstraints = false
        webexLogo.contentMode = .scaleAspectFit
        webexLogo.image = UIImage(named: "logo")
        return webexLogo
    }()
    
    private lazy var loginButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(handleLoginAction), for: .touchUpInside)
        view.setTitle("Login", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumBlue50
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var fedrampSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = UserDefaults.standard.bool(forKey: "isFedRAMP")
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(fedrampSwitchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()

    private let fedrampLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "fedrampLabel"
        label.text = "Fedramp Mode"
        label.adjustsFontSizeToFitWidth = true
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = .white
        return label
    }()

    private lazy var fedrampStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [fedrampLabel, fedrampSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 10
        stack.distribution = .fillEqually
        stack.alignment = .center
        return stack
    }()

    private let versionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "versionLabel"
        label.adjustsFontSizeToFitWidth = true
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = .labelColor
        return label
    }()

    private lazy var swiftUIButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(openInSwiftUI), for: .touchUpInside)
        view.setTitle("SwiftUI", for: .normal)
        view.accessibilityIdentifier = "swiftUIButton"
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumPink50
        view.isHidden = true
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    @objc func fedrampSwitchValueDidChange(_ sender: UISwitch) {
        DispatchQueue.main.async {
            if sender.isOn == true {
                self.isFedRAMPMode = true
            } else {
                self.isFedRAMPMode = false
            }
        }
    }
    
    private var keyWindow: UIWindow? {
        return UIApplication.shared.windows.first { $0.isKeyWindow }
    }
    
    private lazy var loginWithJWTButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(handleLoginWithJWTAction), for: .touchUpInside)
        view.setTitle("Login as Guest", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumBlue50
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var loginWithAccessTokenButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(handleLoginWithAccessTokenAction), for: .touchUpInside)
        view.setTitle("Login with Token", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumBlue50
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setupViews()
        setupConstraints()
        animateLogo()
    }
    
    func animateLogo() {
        self.loginButton.alpha = 0.0
        self.loginButton.isHidden = false
        self.webexLogoView.center = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 3)
        UIView.animate(withDuration: 1.0) {
            self.webexLogoView.center = CGPoint(x: self.view.frame.width / 2, y: 50)
            self.loginButton.alpha = 1.0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        let bundleVersion = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        versionLabel.text = "v\(Webex.version) (\(bundleVersion))"
        if let webex = webex, webex.authenticator?.authorized == true {
            self.switchRootController()
            self.handleNotificationRoutingIfNeeded()
            return
        }
        guard let authType = UserDefaults.standard.string(forKey: "loginType") else { return }
        if authType == "jwt" {
            initWebexUsingJWT()
        } else if authType == "token" {
            initWebexUsingToken()
        } else {
            initWebexUsingOauth(completion: nil)
        }
    }
    
    func initializeWebex(showLoading: Bool = false) {
        if showLoading {
            showLoadingIndicator()
        }
        webex.enableConsoleLogger = true // Do not set this to true in production unless you want to print logs in prod
        webex.logLevel = .verbose

        // Always call webex.initialize before invoking any other method on the webex instance
        DispatchQueue.main.async {
            webex.initialize { [weak self] isLoggedIn in
                guard let self = self else { return }
                
                if let authenticator = webex.authenticator {
                    print("Value of webex.authenticator.authorized: " + (authenticator.authorized.stringValue))
                }
                
                if isLoggedIn {
                    UserDefaults.standard.setValue(self.isFedRAMPMode, forKey: "isFedRAMP")
                    self.switchRootController()
                    self.handleNotificationRoutingIfNeeded()
                } else {
                    self.dismissLoadingIndicator()
                    self.loginButton.isHidden = false
                }
            }
        }
        
    }
    
    func switchRootController() {
        DispatchQueue.main.async {
            guard let window = self.keyWindow else { return }
            window.rootViewController = UINavigationController(rootViewController: HomeViewController())
            window.makeKeyAndVisible()
        }
    }
    
    private func handleNotificationRoutingIfNeeded() {
        guard let handler = keyWindow?.rootViewController as? PushNotificationHandler else { return }
        if let messageInfo = launchMessageInfo {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { handler.handleMessageNotification(messageInfo.messageId, spaceId: messageInfo.spaceId) }
            return
        }
        if let callId = launchWebexCallId {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { handler.handleWebexCallNotification(callId) }
            return
        }
        if let callId = launchCUCMCallId {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { handler.handleCUCMCallNotification(callId) }
            return
        }
    }
    
    func initWebexUsingOauth(completion: ((_ success: Bool) -> Void)?) {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") else { return }
        guard let keys = NSDictionary(contentsOfFile: path) else { return }
        let clientId = isFedRAMPMode ? keys["fedClientId"] as? String ?? "" : keys["clientId"] as? String ?? ""
        let clientSecret = isFedRAMPMode ? keys["fedClientSecret"] as? String ?? "" : keys["clientSecret"] as? String ?? ""
        let redirectUri = isFedRAMPMode ? keys["fedRedirectUri"] as? String ?? "" : keys["redirectUri"] as? String ?? ""
        let scopes = "spark:all" // spark:all is always mandatory
        
        // See if we already have an email stored in UserDefaults else get it from user and do new Login
        if let email = EmailAddress.fromString(UserDefaults.standard.value(forKey: "userEmail") as? String) {
            // The scope parameter can be a space separated list of scopes that you want your access token to possess
            let authenticator = OAuthAuthenticator(clientId: clientId, clientSecret: clientSecret, scope: scopes, redirectUri: redirectUri, emailId: email.toString(), isFedRAMPEnvironment: isFedRAMPMode)
            webex = Webex(authenticator: authenticator)
            self.initializeWebex()
            completion?(true)
            return
        }
        
        let alert = UIAlertController(title: "Login", message: "Enter Email", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter email address"
            textField.text = ""
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.

            guard let email = EmailAddress.fromString(textField?.text) else {
                let emailErrorAlert = UIAlertController(title: "Error", message: "Not a valid email address", preferredStyle: .alert)
                emailErrorAlert.addAction(UIAlertAction.dismissAction())
                self.present(emailErrorAlert, animated: true, completion: nil)
                return
            }
            
            UserDefaults.standard.setValue(email.toString(), forKey: "userEmail")

            // The scope parameter can be a space separated list of scopes that you want your access token to possess
            let authenticator = OAuthAuthenticator(clientId: clientId, clientSecret: clientSecret, scope: scopes, redirectUri: redirectUri, emailId: email.toString(), isFedRAMPEnvironment: self.isFedRAMPMode)
            webex = Webex(authenticator: authenticator)
            self.initializeWebex()
            completion?(true)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func initWebexUsingJWT() {
        webex = Webex(authenticator: JWTAuthenticator())
        initializeWebex()
    }
    
    func initWebexUsingToken() {
        webex = Webex(authenticator: TokenAuthenticator(isFedRAMPEnvironment: self.isFedRAMPMode))
        initializeWebex()
    }
    
    @objc private func handleLoginAction() {
        
        initWebexUsingOauth { [weak self] success in
            guard success else {
                print("Failed to init webex")
                return
            }
            if let authenticator = webex.authenticator as? OAuthAuthenticator {
                self?.loginButton.alpha = 0.7
                self?.loginButton.setTitle("Loading...", for: .normal)
                self?.loginButton.isEnabled = false
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    authenticator.authorize(parentViewController: self) { [weak self] result in
                        guard result == .success else {
                            self?.loginButton.setTitle("Login", for: .normal)
                            self?.loginButton.isEnabled = true
                            print("Login failed!")
                            UserDefaults.standard.removeObject(forKey: "userEmail")
                            return
                        }
                        UserDefaults.standard.setValue("auth", forKey: "loginType")
                        self?.switchRootController()
                    }
                }
            } else {
                print("Authenticator is nil")
                return
            }
        }
    }
    
    @objc private func handleLoginWithJWTAction() {
        initWebexUsingJWT()
        loginWithJWTButton.alpha = 0.7
        loginWithJWTButton.setTitle("Loading...", for: .normal)
        loginWithJWTButton.isEnabled = false
        
        let alert = UIAlertController(title: "Guest Login", message: "Enter JWT token", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter JWT token"
            textField.text = ""
        }
        if let authenticator = webex.authenticator as? JWTAuthenticator {
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                authenticator.authorizedWith(jwt: textField?.text ?? "", completionHandler: { result in
                    switch result {
                    case .failure(let error):
                        self.loginWithJWTButton.setTitle("Login as Guest", for: .normal)
                        self.loginWithJWTButton.isEnabled = true
                        print("JWT Login failed")
                        let emailErrorAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                        emailErrorAlert.addAction(UIAlertAction.dismissAction())
                        self.present(emailErrorAlert, animated: true, completion: nil)
                        return
                    case .success(let authenticated):
                        if authenticated {
                        UserDefaults.standard.setValue("jwt", forKey: "loginType")
                        self.switchRootController()
                        } else {
                            print("JWT Login failed")
                            let emailErrorAlert = UIAlertController(title: "Error", message: "JWT Login Failed!", preferredStyle: .alert)
                            emailErrorAlert.addAction(UIAlertAction.dismissAction())
                            self.present(emailErrorAlert, animated: true, completion: nil)
                        }
                    }
                })
            }))
        } else {
            print("Authenticator is nil")
            return
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func handleLoginWithAccessTokenAction() {
        initWebexUsingToken()
        loginWithAccessTokenButton.alpha = 0.7
        loginWithAccessTokenButton.setTitle("Loading...", for: .normal)
        loginWithAccessTokenButton.isEnabled = false
        
        let alert = UIAlertController(title: "Token Login", message: "Enter Access token", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter Access token"
            textField.text = ""
        }
        if let authenticator = webex.authenticator as? TokenAuthenticator {
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                authenticator.authorizedWith(accessToken: textField?.text ?? "", expiryInSeconds: nil, completionHandler: { result in 
                    guard result == .success else {
                        self.loginWithAccessTokenButton.setTitle("Login", for: .normal)
                        self.loginWithAccessTokenButton.isEnabled = true
                        print("Login failed!")
                        return
                    }
                    
                    UserDefaults.standard.setValue("token", forKey: "loginType")
                    authenticator.onTokenExpired = {
                        // Handle when auth token has expired.
                        // When a token expires, new instances of `Webex` and `Authenticator` need to be created and used with a new token
                        let alert = UIAlertController(title: "Token Expired", message: "User logged out because token expired", preferredStyle: .alert)
                        self.present(alert, animated: true) { [self] in
                            // Request for a new token by creating new instances of Webex and TokenAuthenticator
                            self.handleLoginWithAccessTokenAction()
                        }
                    }
                    self.switchRootController()
                })
            }))
        } else {
            print("Authenticator is nil")
            return
        }
        
        self.present(alert, animated: true, completion: nil)
    }

    @objc func openInSwiftUI() {
        if #available(iOS 15.0, *) {
            let loginView = LoginView()
            let hostingController = UIHostingController(rootView: loginView)

            if #available(iOS 16.0, *) {
                hostingController.sizingOptions = .intrinsicContentSize
            }
            hostingController.modalPresentationStyle = .fullScreen
            self.present(hostingController, animated: true)
        } else {
            let errorAlert = UIAlertController(title: "Error", message: "Minimum iOS 15 required", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction.dismissAction())
            self.present(errorAlert, animated: true, completion: nil)
        }
    }
    
    func setupViews() {
        view.addSubview(fedrampStackView)
        view.addSubview(webexLogoView)
        view.addSubview(loginButton)
        view.addSubview(loginWithJWTButton)
        view.addSubview(loginWithAccessTokenButton)
        view.addSubview(ciscoLogoView)
        view.addSubview(versionLabel)
        view.addSubview(swiftUIButton)
    }
    
    func setupConstraints() {
        webexLogoView.setSize(width: 150, height: 150)
        webexLogoView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        webexLogoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).activate()

        loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        loginButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20).activate()
        loginButton.fillWidth(of: view, padded: 64)
        
        loginWithJWTButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20).activate()
        loginWithJWTButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        loginWithJWTButton.fillWidth(of: view, padded: 64)
        
        loginWithAccessTokenButton.topAnchor.constraint(equalTo: loginWithJWTButton.bottomAnchor, constant: 20).activate()
        loginWithAccessTokenButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        loginWithAccessTokenButton.fillWidth(of: view, padded: 64)

        fedrampStackView.setSize(width: 100, height: 50)
        fedrampStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).activate()
        fedrampStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).activate()

        ciscoLogoView.setSize(width: 100, height: 100)
        ciscoLogoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).activate()
        ciscoLogoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).activate()

        versionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).activate()
        versionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()

        swiftUIButton.setSize(width: 100, height: 50)
        swiftUIButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).activate()
        swiftUIButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).activate()
    }
}

extension LoginViewController: PushNotificationHandler {
    func handleMessageNotification(_ id: String, spaceId: String) {
        launchMessageInfo = (id, spaceId)
    }
    
    func handleWebexCallNotification(_ id: String) {
        launchWebexCallId = id
    }
    
    func handleCUCMCallNotification(_ id: String) {
        launchCUCMCallId = id
    }
}
