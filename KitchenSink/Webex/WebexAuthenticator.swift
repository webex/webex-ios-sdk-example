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
    func loginWithOAuthTocken(authenticator: TokenAuthenticator, token: String, completion: @escaping (Bool) -> Void)
}

class WebexAuthenticator {
    var authenticator: OAuthAuthenticator?
    
    func getWebexVersion() -> String {
        return Webex.version
    }

    func initializeWebex(webex: Webex, completion: @escaping (Bool) -> Void) {
        webex.initialize(completionHandler: completion)
    }
}

// MARK: OAuthAuthenticator
extension WebexAuthenticator : OAuthAuthenticationProtocol {
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

    func getAuthorizationUrl(authenticator: OAuthAuthenticator, completion: @escaping ((URL?) -> Void)) {
        authenticator.getAuthorizationUrl(completionHandler: { result, url in
            if result == .success {
                completion(url)
            }
        })
    }

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

    func loginWithOAuthTocken(authenticator: TokenAuthenticator, token: String, completion: @escaping (Bool) -> Void) {
        authenticator.authorizedWith(accessToken: token, expiryInSeconds: 100, completionHandler: { res in
            if res == .success {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
}
