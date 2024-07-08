import Foundation
import WebexSDK

protocol OAuthAuthenticationProtocol: AnyObject {
    func getOAuthAuthenticator(email: String, isFedRAMP: Bool) -> OAuthAuthenticator?
    func getAuthorizationUrl(authenticator: OAuthAuthenticator, completion: @escaping ((URL?) -> Void))
    func loginWithAuthCode(code: String, completion: @escaping (Bool) -> Void)
}

protocol JWTAuthenticationProtocol: AnyObject {
    func getJWTAuthenticator() -> JWTAuthenticator
    func loginWithJWT(authenticator: JWTAuthenticator, jwt: String, completion: @escaping (Bool) -> Void)
}

protocol TokenAuthenticationProtocol: AnyObject {
    func getTokenAuthenticator(isFedRAMP: Bool) -> TokenAuthenticator
    func loginWithOAuthToken(authenticator: TokenAuthenticator, token: String, completion: @escaping (Bool) -> Void)
}

class WebexAuthenticator {
    var authenticator: OAuthAuthenticator?
    
    /// Retrieves the version of the Webex SDK.
    func getWebexVersion() -> String {
        return Webex.version
    }

    /// Initializes a Webex instance.
    func initializeWebex(webex: Webex, completion: @escaping (Bool) -> Void) {
        webex.initialize(completionHandler: completion)
    }
    
    /// Retrieves the access token.
    func getAcessToken(completion: @escaping (String, String) -> Void) {
        webex.authenticator?.accessToken(completionHandler: { result in
            switch result {
            case .success(let accessToken):
                completion("Success: Access Token", accessToken)
            case .failure(let error):
                completion("Failure: No Access Token", error.localizedDescription)
            @unknown default:
                break
            }
        })
    }
}

// MARK: OAuthAuthenticator
extension WebexAuthenticator : OAuthAuthenticationProtocol {
    
    /// Creates and returns an OAuthAuthenticator instance.
    func getOAuthAuthenticator(email: String, isFedRAMP: Bool) -> OAuthAuthenticator? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") else { return nil }
        guard let keys = NSDictionary(contentsOfFile: path) else { return nil }
        let clientId = isFedRAMP ? keys["fedClientId"] as? String ?? "" : keys["clientId"] as? String ?? ""
        let clientSecret = isFedRAMP ? keys["fedClientSecret"] as? String ?? "" : keys["clientSecret"] as? String ?? ""
        let redirectUri = isFedRAMP ? keys["fedRedirectUri"] as? String ?? "" : keys["redirectUri"] as? String ?? ""
        let scopes = "spark:all" // spark:all is always mandatory
        // The scope parameter can be a space separated list of scopes that you want your access token to possess

        let authenticator = OAuthAuthenticator(clientId: clientId, clientSecret: clientSecret, scope: scopes, redirectUri: redirectUri, emailId: email, isFedRAMPEnvironment: isFedRAMP)
        webex = Webex(authenticator: authenticator)
        self.authenticator = authenticator
        return authenticator
    }

    /// Retrieves the authorization URL.
    func getAuthorizationUrl(authenticator: OAuthAuthenticator, completion: @escaping ((URL?) -> Void)) {
        authenticator.getAuthorizationUrl(completionHandler: { result, url in
            if result == .success {
                completion(url)
            } else {
                completion(nil)
            }
        })
    }
    
    /// Login the user using an authorization code.
    func loginWithAuthCode(code: String, completion: @escaping (Bool) -> Void) {
        authenticator?.authorize(oauthCode: code, completionHandler: { res in
            if res == .success {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
}

// MARK: JWTAuthenticator
extension WebexAuthenticator: JWTAuthenticationProtocol {
    func getJWTAuthenticator() -> JWTAuthenticator {
        let authenticator = JWTAuthenticator()
        webex = Webex(authenticator: authenticator)
        return authenticator
    }

    func loginWithJWT(authenticator: JWTAuthenticator, jwt: String, completion: @escaping (Bool) -> Void) {
        authenticator.authorizedWith(jwt: jwt, completionHandler: { res in
            completion(res.data ?? false)
        })
    }
}

// MARK: TokenAuthenticator
extension WebexAuthenticator: TokenAuthenticationProtocol {
    func getTokenAuthenticator(isFedRAMP: Bool) -> TokenAuthenticator {
        let authenticator = TokenAuthenticator(isFedRAMPEnvironment: isFedRAMP)
        webex = Webex(authenticator: authenticator)
        return authenticator
    }

    func loginWithOAuthToken(authenticator: TokenAuthenticator, token: String, completion: @escaping (Bool) -> Void) {
        authenticator.authorizedWith(accessToken: token, expiryInSeconds: nil, completionHandler: { res in
            if res == .success {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
}

extension WebexAuthenticator {
    /// Signs the user out of the application.
    func signOut(completion: @escaping (() -> Void)) {
        webex.authenticator?.deauthorize(completionHandler: completion)
    }

    /// Enables logging based on the provided level.
    func enableLogging(level: String) {
        var logLevel: LogLevel = .verbose
        if level == "no" {
            webex.logLevel = .no
            webex.enableConsoleLogger = false
            return
        }
        else if level == "info" {
            logLevel = .info
        }
        else if level == "debug" {
            logLevel = .debug
        }
        else if level == "warning" {
            logLevel = .warning
        }
        else if level == "verbose" {
            logLevel = .verbose
        }
        else if level == "all" {
            logLevel = .all
        }
        else if level == "error" {
            logLevel = .error
        }
        webex.enableConsoleLogger = true // Do not set this to true in production unless you want to print logs in prod
        webex.logLevel = logLevel
    }
}
