import UIKit
import WebexSDK

class ExtrasViewController: UIViewController {
    private lazy var getAccessTokenButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(handleGetAccessTokenAction), for: .touchUpInside)
        view.setTitle("Show Access Token", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumBlue50
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var refreshAccessTokenButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(handleRefreshAccessTokenAction), for: .touchUpInside)
        view.setTitle("Refresh Access Token", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumBlue50
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var getJWTAccessTokenExpirationButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(handleGetJWTAccessTokenExpirationAction), for: .touchUpInside)
        view.setTitle("Get GuestIssuer access token expiration", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.titleLabel?.numberOfLines = 0 // Dynamic number of lines
        view.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumBlue50
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var showWebhooksButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(handleShowWebhooksAction), for: .touchUpInside)
        view.setTitle("Webhooks", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumBlue50
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var showSetupButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(handleShowSetupAction), for: .touchUpInside)
        view.setTitle("Setup", for: .normal)
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
    }
    
    @objc private func handleGetAccessTokenAction() {
        webex.authenticator?.accessToken(completionHandler: { accessToken in
            if let accessToken = accessToken {
                let alert = UIAlertController(title: "Access Token", message: accessToken, preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Dismiss"))
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                let alert = UIAlertController(title: "No AccessToken yet", message: nil, preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Dismiss"))
                
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            }
        })
    }
    
    @objc private func handleRefreshAccessTokenAction() {
        // Only works for JWTAuthenticator
        guard let authenticator = webex.authenticator as? JWTAuthenticator else {
            // This shouldn't happen as button itself is hidden
            return
        }
        authenticator.refreshToken(completionHandler: { newAccessToken in
            if let newAccessToken = newAccessToken {
                let alert = UIAlertController(title: "New access Token", message: newAccessToken, preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Dismiss"))
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                let alert = UIAlertController(title: "No AccessToken yet", message: nil, preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Dismiss"))
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            }
        })
    }
    
    @objc private func handleShowIsAuthorizedAction() {
        let alert = UIAlertController(title: "Is Authorized?", message: webex.authenticator?.authorized.stringValue, preferredStyle: .alert)
        alert.addAction(.dismissAction(withTitle: "Dismiss"))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc private func handleGetJWTAccessTokenExpirationAction() {
        // Only works for JWTAuthenticator
        guard let authenticator = webex.authenticator as? JWTAuthenticator else {
            // This shouldn't happen as button itself is hidden
            return
        }
        
        let alert = UIAlertController(title: "Guest Issuer access token expires at", message: authenticator.expiration?.description, preferredStyle: .alert)
        alert.addAction(.dismissAction(withTitle: "Dismiss"))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc private func handleShowWebhooksAction() {
        self.navigationController?.pushViewController(WebhooksViewController(), animated: true)
    }
    
    @objc private func handleShowSetupAction() {
        self.navigationController?.pushViewController(SetupViewController(), animated: true)
    }

    func setupViews() {
        view.addSubview(getAccessTokenButton)
 
        if let authenticator = webex.authenticator, authenticator is JWTAuthenticator {
            view.addSubview(refreshAccessTokenButton)
            view.addSubview(getJWTAccessTokenExpirationButton)
        }
        
        view.addSubview(showWebhooksButton)
        view.addSubview(showSetupButton)
    }
    
    func setupConstraints() {
        getAccessTokenButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        getAccessTokenButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80).activate()
        getAccessTokenButton.fillWidth(of: view, padded: 64)
                
        if let authenticator = webex.authenticator, authenticator is JWTAuthenticator {
            
            refreshAccessTokenButton.topAnchor.constraint(equalTo: getAccessTokenButton.bottomAnchor, constant: 20).activate()
            refreshAccessTokenButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
            refreshAccessTokenButton.fillWidth(of: view, padded: 64)
            
            getJWTAccessTokenExpirationButton.topAnchor.constraint(equalTo: refreshAccessTokenButton.bottomAnchor, constant: 20).activate()
            getJWTAccessTokenExpirationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
            getJWTAccessTokenExpirationButton.fillWidth(of: view, padded: 64)
            
            showWebhooksButton.topAnchor.constraint(equalTo: getJWTAccessTokenExpirationButton.bottomAnchor, constant: 20).activate()
        } else {
            showWebhooksButton.topAnchor.constraint(equalTo: getAccessTokenButton.bottomAnchor, constant: 20).activate()
        }
        
        showWebhooksButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        showWebhooksButton.fillWidth(of: view, padded: 64)
        
        showSetupButton.topAnchor.constraint(equalTo: showWebhooksButton.bottomAnchor, constant: 20).activate()
        showSetupButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        showSetupButton.fillWidth(of: view, padded: 64)
    }
}
