import WebexSDK
import SwiftUI
protocol WebexKSProtocol: AnyObject
{
    func setUCLoginDelegate(delegate: WebexUCLoginDelegateKS)
    func startUCServices()
    func isUCLoggedIn() -> Bool
    func getUCServerConnectionStatus() -> UCLoginServerConnectionStatusKS
    func setCallServiceCredential(username: String, password: String)
    func connectPhoneServices(completionHandler: @escaping (Result<Void>) -> Void)
    func disconnectPhoneServices(completionHandler: @escaping (Result<Void>) -> Void)
    func retryUCSSOLogin()
    func getUCSSOLoginView(parentViewController: UIViewController, ssoUrl: String, completionHandler: @escaping (_ success: Bool?) -> Void)
}

class WebexKS: WebexKSProtocol
{
    weak var webexUCLoginDelegateKS: WebexUCLoginDelegateKS?
    
    func setUCLoginDelegate(delegate webexUCLoginDelegateKS: WebexUCLoginDelegateKS)
    {
        self.webexUCLoginDelegateKS = webexUCLoginDelegateKS
        webex.ucLoginDelegate = self
    }
    
    func isUCLoggedIn() -> Bool
    {
        return webex.isUCLoggedIn()
    }
    
    func startUCServices()
    {
        webex.startUCServices()
    }
    
    func getUCSSOLoginView(parentViewController: UIViewController, ssoUrl: String, completionHandler: @escaping (_ success: Bool?) -> Void) {
        webex.getUCSSOLoginView(parentViewController: parentViewController, ssoUrl: ssoUrl, completionHandler: completionHandler)
    }
    
    func getUCServerConnectionStatus() -> UCLoginServerConnectionStatusKS
    {
        return UCLoginServerConnectionStatusKS(status: webex.getUCServerConnectionStatus())
    }
    
    func setCallServiceCredential(username: String, password: String)
    {
        webex.setCallServiceCredential(username: username, password: password)
    }

    func connectPhoneServices(completionHandler: @escaping (WebexSDK.Result<Void>) -> Void) {
        webex.phone.connectPhoneServices(completionHandler: completionHandler)
    }
    
    func disconnectPhoneServices(completionHandler: @escaping (WebexSDK.Result<Void>) -> Void) {
        webex.phone.disconnectPhoneServices(completionHandler: completionHandler)
    }
    
    func retryUCSSOLogin()
    {
        webex.retryUCSSOLogin()
    }
}


// A delegate for all the Call service login related event callbacks.
///
protocol WebexUCLoginDelegateKS: AnyObject {
    
    /// This will notify app when SSO authentication of CUCM domain/server is required, this gives SSO URL to launch the WebView to start authentication process
    /// This  is applicable for [Phone.CallingType.CUCM] only
    ///
    /// - parameter url: Authentication url for SSO domain/server
    func loadUCSSOView(to url: String)
    
    /// This will notify app when non SSO authentication of CUCM is required to pass in username and password
    ///
    func showUCNonSSOLoginView()
    
    /// This will notify app when SSO authentication failed, to retry SSO use webex.retryUCSSOLogin() API
    ///
    func onUCSSOLoginFailed(failureReason: UCSSOFailureReasonKS)

    /// This will notify when user is successfully logged in on Calling service
    ///
    func onUCLoggedIn()
    
    /// This will notify app whenever when server url/domain, username and password is required for authentication.
    /// On this application needs to display the option to enter required details..
    ///
    /// - parameter failureReason: Reason for the login failure
    func onUCLoginFailed(failureReason: UCLoginFailureReasonKS)
    
    /// This will notify app whenever with Calling service  connection state changes.
    ///
    /// - parameter status: It will have the current connection status of Calling service. The status will be the enum value - [UCLoginServerConnectionStatus]
    /// - parameter failureReason: It will have the phone registration failed reason. The status will be the enum value - [PhoneServiceRegistrationFailureReason]

    func onUCServerConnectionStateChanged(status: UCLoginServerConnectionStatusKS, failureReason: PhoneServiceRegistrationFailureReasonKS)
}

extension WebexKS: WebexUCLoginDelegate
{
    func onUCSSOLoginFailed(failureReason: UCSSOFailureReason) {
        webexUCLoginDelegateKS?.onUCSSOLoginFailed(failureReason: UCSSOFailureReasonKS(reason: failureReason))
    }
    
    func onUCLoginFailed(failureReason: UCLoginFailureReason) {
        print("UC login failed \(failureReason)")
        webexUCLoginDelegateKS?.onUCLoginFailed(failureReason: UCLoginFailureReasonKS(reason: failureReason))
    }
    
    func onUCServerConnectionStateChanged(status: UCLoginServerConnectionStatus, failureReason: PhoneServiceRegistrationFailureReason) {
        webexUCLoginDelegateKS?.onUCServerConnectionStateChanged(status: UCLoginServerConnectionStatusKS(status: status), failureReason: PhoneServiceRegistrationFailureReasonKS(reason: failureReason))
    }
    
    func loadUCSSOView(to url: String) {
        webexUCLoginDelegateKS?.loadUCSSOView(to: url)
    }
    
    func showUCNonSSOLoginView() {
        webexUCLoginDelegateKS?.showUCNonSSOLoginView()
    }
        
    func onUCLoggedIn() {
        webexUCLoginDelegateKS?.onUCLoggedIn()
    }
}

class WebexManager {
    // Shared instance of the WebexManager
    static let shared = WebexManager()

    func checkAndAssignWebexInstance()
    {
        if webex == nil {
            guard let authType = UserDefaults.standard.string(forKey: Constants.loginTypeKey) else { return }
            if authType == Constants.loginTypeValue.jwt.rawValue {
                initWebexUsingJWT()
            } else if authType == Constants.loginTypeValue.token.rawValue{
                initWebexUsingToken()
            } else {
                initWebexUsingOauth()
            }
        }
    }
    
    func initializeWebex(completionHandler: @escaping (Bool) -> Void) {
        if let webex = webex, webex.authenticator?.authorized == true {
            completionHandler(true)
            return
        }
        if webex != nil {
            webex.enableConsoleLogger = true // Do not set this to true in production unless you want to print logs in prod
            
            webex.authDelegate = AppDelegate.shared
            webex.logLevel = .verbose
            DispatchQueue.main.async {
                webex.initialize { success in
                    print("webex.initialize: " + "\(success)")
                    completionHandler(success)
                }
            }
        }
        else {
            print("webex is nil")
            completionHandler(false)
            return
        }
    }

    func initWebexUsingOauth() {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") else { return }
        guard let keys = NSDictionary(contentsOfFile: path) else { return }
        let clientId = keys["clientId"] as? String ?? ""
        let clientSecret = keys["clientSecret"] as? String ?? ""
        let redirectUri = keys["redirectUri"] as? String ?? ""
        let scopes = "spark:all" // spark:all is always mandatory
        
        // See if we already have an email stored in UserDefaults else get it from user and do new Login
        if let email = EmailAddress.fromString(UserDefaults.standard.value(forKey: Constants.emailKey) as? String) {
            // The scope parameter can be a space separated list of scopes that you want your access token to possess
            let authenticator = OAuthAuthenticator(clientId: clientId, clientSecret: clientSecret, scope: scopes, redirectUri: redirectUri, emailId: email.toString())
            webex = Webex(authenticator: authenticator)
            return
        } 
    }

    func initWebexUsingJWT() {
        webex = Webex(authenticator: JWTAuthenticator())
    }

    func initWebexUsingToken() {
        webex = Webex(authenticator: TokenAuthenticator())
    }
    
    func isCurrentScreenIsCallScreen() -> Bool
    {
        if UIApplication.shared.topViewController() is CallViewController {
            return true
        }
        if #available(iOS 16.0, *) {
            if let topController = UIApplication.shared.topViewController(),
               let _ = topController as? UIHostingController<CallingScreenView>
            {
                return true
            }
        }
        
        return false
    }
}
