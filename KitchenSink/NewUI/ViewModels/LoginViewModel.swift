import SwiftUI
import WebexSDK

@available(iOS 16.0, *)
enum AuthType {
    case token
    case email
    case jwt
}

@available(iOS 16.0, *)
class LoginViewModel: ObservableObject {
    @Published var link: URL?
    @Published var isLoggedIn: Bool = false
    @Published var showWebView: Bool = false
    @Published var showLoading: Bool = false
    @Published var redirectUri: String?
    @Published var code: String = ""

    init (link: URL, redirectUri: String) {
        self.link = link
        self.redirectUri = redirectUri
    }

    var webexAuthenticator = WebexAuthenticator()

    var loginType: String = ""
    var isFedRAMPMode: Bool = false
    var email: String = ""

    /// Fetches the version of the Webex SDK and the bundle version of the app.
    func getVersionInfo() -> String {
        let webexVersion = webexAuthenticator.getWebexVersion()
        UserDefaults.standard.setValue(webexVersion, forKey: "version")
        let bundleVersion = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        return "v\(webexVersion) (\(bundleVersion))"
    }

    /// Retrieves the redirect URI from the secrets stored in Secrets.plist file.
    func getRedirectUri() -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") else { return nil }
        guard let keys = NSDictionary(contentsOfFile: path) else { return nil }
        return isFedRAMPMode ? keys["fedRedirectUri"] as? String ?? "" : keys["redirectUri"] as? String ?? ""
    }

    /// Controls the display of a loading indicator
    func loadingIndicator(show: Bool) {
        DispatchQueue.main.async {
            self.showLoading = show
        }
    }

    /// Redirects to home screen after successful login.
    func switchRootController() {
        loadingIndicator(show: false)
        UserDefaults.standard.setValue(loginType, forKey: Constants.loginTypeKey)
        UserDefaults.standard.setValue(isFedRAMPMode, forKey: Constants.fedRampKey)
        UserDefaults.standard.setValue(email, forKey: Constants.emailKey)
        print("LOGGED IN SUCCESSFULLY")
        self.isLoggedIn = true
    }

// MARK: Email Authentication
    /// Initiates the login process using an email ID and sets up the OAuth authenticator.
    func doEmailLogin(email: String, authenticator: Authenticator) {
        self.email = email
        guard let authenticator = authenticator as? OAuthAuthenticator else { return }
        webex = Webex(authenticator: authenticator)
        loadingIndicator(show: true)
        guard let redirectUri = self.getRedirectUri() else { return }
        self.webexAuthenticator.getAuthorizationUrl(authenticator: authenticator, completion: { url in
            self.link = url!
            self.redirectUri = redirectUri
            self.showWebView = true
        })
    }

    /// Logs in using the authentication code.
    func loginWithAuthCode(code: String) {
        loadingIndicator(show: true)
        webexAuthenticator.loginWithAuthCode(code: code, completion: { res in
            if res {
                self.webexAuthenticator.initializeWebex(webex: webex, completion: { res in
                    if res {
                        self.loginType = Constants.loginTypeValue.email.rawValue
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
    /// Initiates the guest login process using a JWT token.
    func doGuestLogin(guestToken: String, authenticator: Authenticator) {
        guard let authenticator = authenticator as? JWTAuthenticator else { return }
        webex = Webex(authenticator: authenticator)
        loadingIndicator(show: true)
        if !guestToken.isEmpty {
            self.webexAuthenticator.loginWithJWT(authenticator: authenticator, jwt: guestToken, completion: { res in
                if res {
                    self.webexAuthenticator.initializeWebex(webex: webex, completion: { res in
                        if res {
                            self.loginType = Constants.loginTypeValue.jwt.rawValue
                            self.switchRootController()
                        } else {
                            self.loadingIndicator(show: false)
                        }
                    })
                } else {
                    self.loadingIndicator(show: false)
                }
            })
        } else {
            self.loadingIndicator(show: false)
        }
    }

// MARK: OAuth Token Authentication
    /// Initiates the login process using an OAuth token.
    func doOAuthLogin(OAuthToken: String, authenticator: Authenticator) {
        guard let authenticator = authenticator as? TokenAuthenticator else { return }
        webex = Webex(authenticator: authenticator)
        loadingIndicator(show: true)
        if !OAuthToken.isEmpty {
            self.webexAuthenticator.loginWithOAuthToken(authenticator: authenticator, token: OAuthToken, completion: { res in
                if res {
                    self.webexAuthenticator.initializeWebex(webex: webex, completion: { res in
                        if res {
                            self.loginType = Constants.loginTypeValue.token.rawValue
                            self.switchRootController()
                        } else {
                            self.loadingIndicator(show: false)
                        }
                    })
                } else {
                    self.loadingIndicator(show: false)
                }
            })
        } else {
            self.loadingIndicator(show: false)
        }
    }

    /// Fetches an `Authenticator` object based on the specified authentication type.
    func getAuthenticator(type: AuthType, email: String? = nil, isFedRAMPMode: Bool = false) -> Authenticator? {
        if type == .email {
            guard let email = email else { return nil }
            guard let authenticator = webexAuthenticator.getOAuthAuthenticator(email: email, isFedRAMP: isFedRAMPMode) else { return nil }
            webex = Webex(authenticator: authenticator)
            return authenticator
        } else if type == .jwt {
            let authenticator = webexAuthenticator.getJWTAuthenticator()
            webex = Webex(authenticator: authenticator)
            return authenticator
        } else {
            let authenticator = webexAuthenticator.getTokenAuthenticator(isFedRAMP: isFedRAMPMode)
            webex = Webex(authenticator: authenticator)
            return authenticator
        }
    }

    /// Attempts to automatically login using the provided `Authenticator` object.
    func tryAutoLogin(authenticator: Authenticator, loginType: String, email: String = "") {
        loadingIndicator(show: true)
        self.webexAuthenticator.initializeWebex(webex: webex, completion: { res in
            if res {
                print("Is Authorized: \(authenticator.authorized)")
                self.loginType = loginType
                self.email = email
                self.switchRootController()
            }
        })
    }
}
