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
    @Published var isStartCallWithVideoOn = false
    @Published var enableBackgroundConnection = false
    @Published var isAuxiliaryMode = false
    @Published var enable1080pVideo = false
    @Published var videoStreamModeLabel = ""
    
    var webexAuthenticator = WebexAuthenticator()
    var messagingViewModel: MessagingHomeViewModel
    var mailVM: MailViewModel
    var webexPhone: PhoneProtocol  = WebexPhone()

    /// Initializes the view model with the given profile and the reference to the messaging view model.
    init(profile: ProfileKS, messagingVM: MessagingHomeViewModel, mailVM: MailViewModel) {
        self.profile = profile
        self.messagingViewModel = messagingVM
        self.mailVM = mailVM
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
    
    func updateToggles()
    {
        isStartCallWithVideoOn = UserDefaults.standard.bool(forKey: "hasVideo")
        isAuxiliaryMode = UserDefaults.standard.bool(forKey: "compositeMode")
        enable1080pVideo = UserDefaults.standard.bool(forKey: "VideoRes1080p")
        enable1080pVideo = UserDefaults.standard.bool(forKey: "VideoRes1080p")
        enableBackgroundConnection = UserDefaults.standard.bool(forKey: "backgroundConnection")
    }
    
    func updateStartCallWithVideoOn() {
        isStartCallWithVideoOn.toggle()
        UserDefaults.standard.set(isStartCallWithVideoOn, forKey: "hasVideo")
    }
    
    func updateIsAuxiliaryMode() {
        isAuxiliaryMode.toggle()
        UserDefaults.standard.setValue(isAuxiliaryMode, forKey: "compositeMode")
        DispatchQueue.main.async {
            self.videoStreamModeLabel = self.isAuxiliaryMode ? "Auxiliary Mode" : "Composite Mode"
        }
        
        if isAuxiliaryMode {
            webexPhone.videoStreamMode = .auxiliary
        } else {
            webexPhone.videoStreamMode = .composited
        }
    }
    
    func updateIsEnable1080pVideo() {
        enable1080pVideo.toggle()
        UserDefaults.standard.setValue(enable1080pVideo, forKey: "VideoRes1080p")
    }
    
    func updateBackgroundConnection() {
        enableBackgroundConnection.toggle()
        UserDefaults.standard.setValue(enableBackgroundConnection, forKey: "backgroundConnection")
        
        if enableBackgroundConnection {
            webexPhone.enableBackgroundConnection = true
        } else {
            webexPhone.enableBackgroundConnection = false
        }
    }
}
