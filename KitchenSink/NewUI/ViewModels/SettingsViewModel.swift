import SwiftUI
import Foundation

@available(iOS 16.0, *)
struct ProfileKS {
    var imageUrl: String?
    var name: String?
    var status: String?
}

@available(iOS 16.0, *)
class SettingsViewModel: ObservableObject {
    @Published var profile: ProfileKS
    @Published var version: String = ""
    @Published var isLoading = false

    var webexAuthenticator = WebexAuthenticator()
    var messagingViewModel: MessagingHomeViewModel

    /// Initializes the view model with the given profile and the reference to the messaging view model.
    init(profile: ProfileKS, messagingVM: MessagingHomeViewModel) {
        self.profile = profile
        self.messagingViewModel = messagingVM
    }

    /// Fetches and updates the version of the Webex SDK and the build version of the application.
    func updateVersion() {
        let bundleVersion = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        if let versionString = UserDefaults.standard.value(forKey: "version") {
            self.version = "v\(versionString) (\(bundleVersion))"
        } else {
            let versionString = webexAuthenticator.getWebexVersion()
            self.version = "v\(versionString) (\(bundleVersion))"
        }
    }

    /// Signs out the user from Webex and resets the relevant user defaults.
    func signOut() {
        messagingViewModel.showLoading = true
        webexAuthenticator.signOut(completion: {
            DispatchQueue.main.async { [weak self] in
                UserDefaults.standard.removeObject(forKey: Constants.loginTypeKey)
                UserDefaults.standard.removeObject(forKey: Constants.emailKey)
                UserDefaults.standard.removeObject(forKey: Constants.fedRampKey)

                self?.messagingViewModel.showLoading = false
                self?.messagingViewModel.isLoggedOut = true
            }
        })
    }

    /// Enables logging in the Webex SDK with the given log level.
    func enableLogging(level: String) {
        webexAuthenticator.enableLogging(level: level)
    }

    /// Fetches the access token from the Webex SDK
    func getAccessToken(completion: @escaping (String, String) -> Void) {
        self.isLoading = true
        webexAuthenticator.getAcessToken { (title, message) in
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                completion(title, message)
            }
        }
    }
}
