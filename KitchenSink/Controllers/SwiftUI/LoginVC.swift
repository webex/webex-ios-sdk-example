import Foundation

@available(iOS 13.0, *)
class LoginVC: NSObject {
    var loginVM = LoginViewModel(link: URL(string: "https://google.com")!, redirectUri: "")
    var webexAuthenticator = WebexAuthenticator()

    var loginType: String = ""
    var isFedRAMPMode: Bool = false
    var email: String = ""

    func getVersionInfo() -> String {
        let webexVersion = webexAuthenticator.getWebexVersion()
        let bundleVersion = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        return "v\(webexVersion) (\(bundleVersion))"
    }

    func getRedirectUri() -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") else { return nil }
        guard let keys = NSDictionary(contentsOfFile: path) else { return nil }
        return isFedRAMPMode ? keys["fedRedirectUri"] as? String ?? "" : keys["redirectUri"] as? String ?? ""
    }

    func loadingIndicator(show: Bool) {
        self.loginVM.showLoading = show
    }

    func switchRootController() {
        self.loginVM.showLoading = false
        UserDefaults.standard.setValue(loginType, forKey: "loginType")
        UserDefaults.standard.setValue(isFedRAMPMode, forKey: "isFedRAMP")
        UserDefaults.standard.setValue(email, forKey: "userEmail")
        print("LOGGED IN SUCCESSFULLY")
    }

// MARK: Email Authentication
    func doEmailLogin(email: String, isFedRAMPEnabled: Bool, model: LoginViewModel) {
        self.isFedRAMPMode = isFedRAMPEnabled
        self.loginType = "auth"
        self.email = email
        self.loginVM = model
        loadingIndicator(show: true)

        guard let authenticator = webexAuthenticator.getOAuthAuthenticator(email: email, isFedRAMP: isFedRAMPMode) else {
            print("Authentication Failed")
            return
        }
        self.webexAuthenticator.initializeWebex(webex: webex, completion: { res in
            if res {
                self.switchRootController()
            } else {
                guard let redirectUri = self.getRedirectUri() else { return }
                self.webexAuthenticator.getAuthorizationUrl(authenticator: authenticator, completion: { url in
                    self.loginVM.link = url!
                    self.loginVM.redirectUri = redirectUri
                    self.loginVM.showWebView = true
                })
            }
        })
    }

    func loginWithAuthCode(code: String) {
        self.loginVM.showLoading = true
        webexAuthenticator.loginWithAuthCode(code: code, completion: { res in
            if res {
                self.webexAuthenticator.initializeWebex(webex: webex, completion: { res in
                    if res {
                        self.switchRootController()
                    } else {
                        self.loadingIndicator(show: false)
                    }
                })
            } else {
                self.loadingIndicator(show: false)
            }
        })
    }

// MARK: Guest Authentication
    func doGuestLogin(guestToken: String) {
        self.loginType = "jwt"
        loadingIndicator(show: true)
        let authenticator = webexAuthenticator.getJWTAuthenticator()
        self.webexAuthenticator.initializeWebex(webex: webex, completion: { res in
            if res {
                self.switchRootController()
            } else {
                self.webexAuthenticator.loginWithJWT(authenticator: authenticator, jwt: guestToken, completion: { res in
                    if res {
                        self.webexAuthenticator.initializeWebex(webex: webex, completion: { res in
                            if res {
                                self.switchRootController()
                            } else {
                                self.loadingIndicator(show: false)
                            }
                        })
                    } else {
                        self.loadingIndicator(show: false)
                    }
                })
            }
        })
    }

// MARK: OAuth Token Authentication
    func doOAuthLogin(OAuthToken: String, isFedRAMPEnabled: Bool) {
        self.isFedRAMPMode = isFedRAMPEnabled
        self.loginType = "token"
        loadingIndicator(show: true)

        let authenticator = webexAuthenticator.getTokenAuthenticator(isFedRAMP: isFedRAMPMode)
        self.webexAuthenticator.initializeWebex(webex: webex, completion: { res in
            if res {
                self.switchRootController()
            } else {
                self.webexAuthenticator.loginWithOAuthTocken(authenticator: authenticator, token: OAuthToken, completion: { res in
                    if res {
                        self.webexAuthenticator.initializeWebex(webex: webex, completion: { res in
                            if res {
                                self.switchRootController()
                            } else {
                                self.loadingIndicator(show: false)
                            }
                        })
                    } else {
                        self.loadingIndicator(show: false)
                    }
                })
            }
        })
    }
}
