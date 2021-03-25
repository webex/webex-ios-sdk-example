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
        webex.authenticator?.refreshToken(completionHandler: { newAccessToken in
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
    
    @objc private func handleShowWebhooksAction() {
        self.navigationController?.pushViewController(WebhooksViewController(), animated: true)
    }
    
    @objc private func handleShowSetupAction() {
        self.navigationController?.pushViewController(SetupViewController(), animated: true)
    }

    func setupViews() {
        view.addSubview(getAccessTokenButton)
        view.addSubview(refreshAccessTokenButton)
        view.addSubview(showWebhooksButton)
        view.addSubview(showSetupButton)
    }
    
    func setupConstraints() {
        getAccessTokenButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        getAccessTokenButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80).activate()
        getAccessTokenButton.fillWidth(of: view, padded: 64)
        
        refreshAccessTokenButton.topAnchor.constraint(equalTo: getAccessTokenButton.bottomAnchor, constant: 20).activate()
        refreshAccessTokenButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        refreshAccessTokenButton.fillWidth(of: view, padded: 64)
        
        showWebhooksButton.topAnchor.constraint(equalTo: refreshAccessTokenButton.bottomAnchor, constant: 20).activate()
        showWebhooksButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        showWebhooksButton.fillWidth(of: view, padded: 64)
        
        showSetupButton.topAnchor.constraint(equalTo: showWebhooksButton.bottomAnchor, constant: 20).activate()
        showSetupButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        showSetupButton.fillWidth(of: view, padded: 64)
    }
}
