import SwiftUI

@available(iOS 16.0, *)
class UCLoginServicesViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var phoneServiceConnected: Bool = false
    @Published var showUCLoginServicesNonSSOScreen =  false
    @Published var uCServerConnectionStatus =  "Idle"
    
    let webexKS: WebexKSProtocol = WebexKS()
    let phoneKS: PhoneProtocol = WebexPhone()

    func isWebexOrCucmCalling() -> Bool
    {
        return phoneKS.isWebexOrCucmCalling()
    }

    // LoginNonSSO() is called when user enters username and password and taps on login button
    func loginNonSSO() {
        webexKS.setCallServiceCredential(username: username, password: password)
        DispatchQueue.main.async { [weak self] in
            self?.showUCLoginServicesNonSSOScreen = false
        }
    }
    
    // Sets UCLoginDelegate and starts UC services
    func setUCLoginDelegateAndStartUCServices()
    {
        webexKS.setUCLoginDelegate(delegate: self)
        webexKS.startUCServices()
        getCurrentConnectionStatus()
    }
    
    // Gets current connection status
    func getCurrentConnectionStatus()
    {
        DispatchQueue.main.async { [weak self] in
            self?.uCServerConnectionStatus = "\(self?.webexKS.getUCServerConnectionStatus() ?? .Idle)"
            self?.phoneServiceConnected = self?.webexKS.getUCServerConnectionStatus() == .Connected
        }
    }
    
    // Toggles phone services on/off
    func togglePhoneServices(isOn: Bool)
    {
        isOn ? connectPhoneServices() : disconnectPhoneServices()
    }
    
    // Connects phone services
    func connectPhoneServices() {
        if phoneServiceConnected {
            return
        }
        webexKS.connectPhoneServices(completionHandler: { result in
            switch result {
                case .success:
                    print("Request completed successfully")
                    self.getCurrentConnectionStatus()
                case .failure:
                print("Error connecting \(result.error.debugDescription)")
            @unknown default:
                print("default")
            }
        })
    }
    
    // Disconnects phone services
    func disconnectPhoneServices() {
        if !phoneServiceConnected {
            return
        }
        webexKS.disconnectPhoneServices(completionHandler: { result in
            switch result {
                case .success:
                    self.getCurrentConnectionStatus()
                    print("Request completed successfully")
                case .failure:
                print("Error disconnecting \(result.error.debugDescription)")
            @unknown default:
                print("default")
            }
        })
    }
}

@available(iOS 16.0, *)
extension UCLoginServicesViewModel: WebexUCLoginDelegateKS {
    func loadUCSSOView(to url: String) {
        webexKS.getUCSSOLoginView(parentViewController: UIApplication.shared.topViewController()!, ssoUrl: url) { success in
            
        }
    }
    
    func showUCNonSSOLoginView() {
        DispatchQueue.main.async { [weak self] in
            self?.showUCLoginServicesNonSSOScreen = true
        }
    }
    
    func onUCSSOLoginFailed(failureReason: UCSSOFailureReasonKS) {
        webexKS.retryUCSSOLogin()
    }
    
    func onUCLoggedIn() {
        getCurrentConnectionStatus()
    }
    
    func onUCLoginFailed(failureReason: UCLoginFailureReasonKS) {
        print("onUCLoginFailed : \(failureReason)")
    }
    
    func onUCServerConnectionStateChanged(status: UCLoginServerConnectionStatusKS, failureReason: PhoneServiceRegistrationFailureReasonKS) {
        print("")
        getCurrentConnectionStatus()
    }
}
