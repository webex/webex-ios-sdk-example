import SwiftUI
import MessageUI

@available(iOS 16.0, *)
struct SettingsView: View {
    @State private var multiStream: Bool = true
    @State private var isAlertPresented = false
    @State private var showingWaitingScreen = false
    @State private var isTokenCopied = false
    @State private var sendFeedbackDialogPresented = false
    @State private var isShowingMailView = false
    @State private var loggingModesExpanded: Bool = false
    @State private var mailSentFailAlert = false
    @State private var loggingModes: [String] = ["no", "error", "warning", "info", "debug", "verbose", "all"]
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isPhoneServicesOn = false
    @State private var showSetupView = false
    @State private var isSpeechEnhancementEnabled: Bool = true

    @Environment(\.dismiss) var dismiss

    @ObservedObject var model: SettingsViewModel
    @ObservedObject var phoneServicesViewModel = UCLoginServicesViewModel()

    var body: some View {
    NavigationView {
        VStack {
            AsyncImage(url: URL(string: model.profile.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
            }
            .frame(width: 80, height: 80)
            .cornerRadius(40)
            .overlay(Circle()
                .stroke(.green, lineWidth: 2))
            .padding(.top, 30)
            
            Text(model.profile.name ?? "")
                .font(.title)
                .padding(.leading, 15)
                .accessibilityIdentifier("profileName")
            Text(model.profile.status ?? "")
                .font(.headline)
                .padding(.leading, 15)
                .foregroundColor(.secondary)
                .padding(.bottom, 30)
            
            List {
                HStack {
                    Toggle("Phone Services:    \(phoneServicesViewModel.uCServerConnectionStatus)", isOn: $isPhoneServicesOn)
                        .onChange(of: isPhoneServicesOn) { newValue in
                            phoneServicesViewModel.togglePhoneServices(isOn: newValue)
                        }
                        .onReceive(phoneServicesViewModel.$phoneServiceConnected) { newValue in
                            if newValue != isPhoneServicesOn {
                                isPhoneServicesOn = newValue
                            }
                        }
                        .accessibilityIdentifier("phoneServicesToggle")
                }.onTapGesture {
                    phoneServicesViewModel.togglePhoneServices(isOn: !isPhoneServicesOn)
                }
                
                HStack {
                    Toggle("Start Call With Video ", isOn: $model.isStartCallWithVideoOn)
                        .accessibilityIdentifier("startCallWithVideo")
                }.onTapGesture {
                    model.updateStartCallWithVideoOn()
                }

                HStack {
                    Toggle("Use Legacy Noise Removal", isOn: $model.useLegacyNoiseRemoval)
                        .accessibilityIdentifier("isSpeechEnhancementEnabled")
                }.onTapGesture {
                    model.updateUseLegacyNoiseRemoval()
                }

                HStack {
                    Toggle("Enable Speech Enhancement", isOn: $model.enableSpeechEnhancement)
                        .accessibilityIdentifier("isSpeechEnhancementEnabled")
                }.onTapGesture {
                    model.updateSpeechEnhancementEnabled()
                }

                HStack {
                    Toggle("Auxiliary Mode", isOn: $model.isAuxiliaryMode)
                        .accessibilityIdentifier("auxiliaryMode")
                }.onTapGesture {
                    model.updateIsAuxiliaryMode()
                }
                
                HStack {
                    Toggle("Enable 1080p Video", isOn: $model.enable1080pVideo)
                        .accessibilityIdentifier("isEnable1080pVideo")
                }.onTapGesture {
                    model.updateIsEnable1080pVideo()
                }
                
                HStack {
                    Toggle("Background Connection", isOn: $model.enableBackgroundConnection)
                        .accessibilityIdentifier("backgroundConnection")
                }.onTapGesture {
                    model.updateBackgroundConnection()
                }
                
                Text("Incoming Call")
                    .onTapGesture {
                        showingWaitingScreen = true
                    }
                Text("Access Tokens")
                    .onTapGesture {
                        getAccessToken()
                    }
                NavigationLink(destination: CameraSettingView(cameraSettingVM: CameraSettingViewModel())) {
                    Text("Camera Settings")
                        .accessibilityIdentifier("cameraSettings")
                }
                
                Section("Phone") {
                    Text("Video")
                        .onTapGesture {

                        }
                    Toggle("New Multi Stream", isOn: $multiStream)
                        .onChange(of: multiStream) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "isMultiStreamEnabled")
                        }
                        .accessibilityIdentifier("isMultiStreamEnabled")
                    Text("Virtual Background")
                        .onTapGesture {

                        }
                }

                DisclosureGroup("Logging Mode", isExpanded: $loggingModesExpanded) {
                    ForEach(0..<loggingModes.count, id: \.self) { mode in
                        Text(loggingModes[mode])
                            .onTapGesture {
                                withAnimation {
                                    loggingModesExpanded = false
                                }
                                model.enableLogging(level: loggingModes[mode])
                            }
                    }
                }
                
                Text("Send Feedback")
                    .foregroundColor(.orange)
                    .onTapGesture {
                        self.sendFeedbackDialogPresented = true
                    }
                
                Text("Logout")
                    .foregroundColor(.red)
                    .onTapGesture {
                        model.signOut()
                        dismiss()
                        callAppDelegateMethod()
                    }.accessibilityIdentifier("logout")
            }
            Text(model.version)
                .multilineTextAlignment(.center)
                .font(.caption)
                .padding(.leading, 15)
                .foregroundColor(.secondary)
        }
       }// nav
        .alert("Error", isPresented: $model.showError) {
            Button("Ok") { }
                .accessibilityIdentifier("errorOkButton")
        } message: {
            Text(model.error)
        }
        .alert("Could Not Send Email", isPresented: $mailSentFailAlert) {
            Button("Ok") {}
        } message: {
            Text("Your device could not send e-mail.  Please check e-mail configuration and try again.")
        }
        .confirmationDialog("Choose Topic", isPresented: $sendFeedbackDialogPresented, titleVisibility: .visible) {
            Button("Bug Report") {
                configureMailMessage()
                model.mailVM.feedback = Feedback.reportBug
                model.mailVM.isShowing.toggle()
            }
            Button("Feature Request") {
                configureMailMessage()
                model.mailVM.feedback = Feedback.featureRequest
                model.mailVM.isShowing.toggle()
            }
        }
        .alert(alertTitle, isPresented: $isAlertPresented) {
            Button("Dismiss") { }
            if !alertTitle.contains("failure") {
                Button("Copy") {
                    UIPasteboard.general.string = alertMessage
                    self.isTokenCopied.toggle()
                }
            }
        } message: {
            Text(self.alertMessage)
        }
        .alert("", isPresented: $isTokenCopied) {
            Button("Ok") {}
        } message: {
            Text("Token Copied")
        }
        .sheet(isPresented: $model.mailVM.isShowing) {
            MailView(viewModel: model.mailVM)
        }
        .sheet(isPresented: $showingWaitingScreen) {
            WaitingCallView()
        }
        .onAppear(perform: {
            model.updateVersion()
            model.updateToggles()
            phoneServicesViewModel.setUCLoginDelegateAndStartUCServices()
        })
        .overlay {
            if model.isLoading {
                ActivityIndicatorView()
            }
        }
    }
    /// Fetches the access token using the model and updates the UI.
    /// Retrieves the access token from the model
    private func getAccessToken() {
        model.getAccessToken { (title, message) in
            alertTitle = title
            alertMessage = message
            isAlertPresented = true
        }
    }
    
    /// Configures the mail message to be sent
    private func configureMailMessage() {
        MFMailComposeViewController.canSendMail() ?  sendFeedbackDialogPresented.toggle() : mailSentFailAlert.toggle()
    }
    
    private func callAppDelegateMethod() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("The AppDelegate is not accessible or of the wrong type.")
            return
        }
        appDelegate.navigateToLoginViewController()
    }
}

@available(iOS 16.0, *)
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(model: SettingsViewModel(profile: ProfileKS(imageUrl: "", name: "", status: ""), messagingVM: MessagingHomeViewModel(), mailVM: MailViewModel()), phoneServicesViewModel: UCLoginServicesViewModel())
            .previewDevice("iPhone 14 Pro Max")
    }
}
