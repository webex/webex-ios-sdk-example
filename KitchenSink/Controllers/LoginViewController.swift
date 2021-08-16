import UIKit
import WebexSDK

class LoginViewController: UIViewController {
    private var launchMessageInfo: (messageId: String, spaceId: String)?
    private var launchWebexCallId: String?
    private var launchCUCMCallId: String?
    
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
        guard let authType = UserDefaults.standard.string(forKey: "loginType") else { return }
        if authType == "jwt" {
            initWebexUsingJWT()
        } else {
            initWebexUsingOauth(completion: nil)
        }
    }
    
    func initializeWebex() {
        webex.enableConsoleLogger = true // Do not set this to true in production unless you want to print logs in prod
        webex.logLevel = .verbose

        // Always call webex.initialize before invoking any other method on the webex instance
        webex.initialize { [weak self] isLoggedIn in
            guard let self = self else { return }
            
            if let authenticator = webex.authenticator {
                print("Value of webex.authenticator.authorized: " + (authenticator.authorized.stringValue))
            }
            
            if isLoggedIn {
                self.switchRootController()
                self.handleNotificationRoutingIfNeeded()
            } else {
                self.loginButton.isHidden = false
            }
        }
    }
    
    func switchRootController() {
        guard let window = keyWindow else { return }
        window.rootViewController = UINavigationController(rootViewController: HomeViewController())
        window.makeKeyAndVisible()
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
        let clientId = keys["clientId"] as? String ?? ""
        let clientSecret = keys["clientSecret"] as? String ?? ""
        let redirectUri = keys["redirectUri"] as? String ?? ""
        
        // See if we already have an email stored in UserDefaults else get it from user and do new Login
        if let email = EmailAddress.fromString(UserDefaults.standard.value(forKey: "userEmail") as? String) {
            let authenticator = OAuthAuthenticator(clientId: clientId, clientSecret: clientSecret, redirectUri: redirectUri, emailId: email.toString())
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

            let authenticator = OAuthAuthenticator(clientId: clientId, clientSecret: clientSecret, redirectUri: redirectUri, emailId: email.toString())
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
    
    @objc private func handleLoginAction() {
        initWebexUsingOauth { [self] success in
            guard success else {
                print("Failed to init webex")
                return
            }
            if let authenticator = webex.authenticator as? OAuthAuthenticator {
                loginButton.alpha = 0.7
                loginButton.setTitle("Loading...", for: .normal)
                loginButton.isEnabled = false
                authenticator.authorize(parentViewController: self) { result in
                    guard result == .success else {
                        self.loginButton.setTitle("Login", for: .normal)
                        self.loginButton.isEnabled = true
                        print("Login failed!")
                        UserDefaults.standard.removeObject(forKey: "userEmail")
                        return
                    }
                    UserDefaults.standard.setValue("auth", forKey: "loginType")
                    self.switchRootController()
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
    
    func setupViews() {
        view.addSubview(webexLogoView)
        view.addSubview(loginButton)
        view.addSubview(loginWithJWTButton)
        view.addSubview(ciscoLogoView)
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
        
        ciscoLogoView.setSize(width: 100, height: 100)
        ciscoLogoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12).activate()
        ciscoLogoView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
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
