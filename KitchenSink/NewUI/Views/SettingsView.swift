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

    @Environment(\.dismiss) var dismiss

    @ObservedObject var model: SettingsViewModel
    @ObservedObject var mailVM: MailViewModel

    var body: some View {
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
            Text(model.profile.status ?? "")
                .font(.headline)
                .padding(.leading, 15)
                .foregroundColor(.secondary)
                .padding(.bottom, 30)

            List {
                Text("Incoming Call")
                    .onTapGesture {
                        showingWaitingScreen = true
                    }
                Text("Access Tokens")
                    .onTapGesture {
                            getAccessToken()
                        }
                Section("Phone") {
                    Text("Video")
                        .onTapGesture {

                        }
                    Toggle("New Multi Streeam", isOn: $multiStream)
                        .onTapGesture {

                        }
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
                        dismiss()
                        model.signOut()
                    }
            }
            Text(model.version)
                .multilineTextAlignment(.center)
                .font(.caption)
                .padding(.leading, 15)
                .foregroundColor(.secondary)
        }
        .alert("Could Not Send Email", isPresented: $mailSentFailAlert) {
            Button("Ok") {}
        } message: {
            Text("Your device could not send e-mail.  Please check e-mail configuration and try again.")
        }
        .confirmationDialog("Choose Topic", isPresented: $sendFeedbackDialogPresented, titleVisibility: .visible) {
            Button("Bug Report") {
                configureMailMessage()
                mailVM.feedback = Feedback.reportBug
                mailVM.isShowing.toggle()
            }
            Button("Feature Request") {
                configureMailMessage()
                mailVM.feedback = Feedback.featureRequest
                mailVM.isShowing.toggle()
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
        .sheet(isPresented: $isShowingMailView) {
            MailView(viewModel: mailVM)
        }
        .sheet(isPresented: $showingWaitingScreen) {
            WaitingCallView()
        }
        .onAppear(perform: model.updateVersion)
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
}

@available(iOS 16.0, *)
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(model: SettingsViewModel(profile: ProfileKS(imageUrl: "", name: "", status: ""), messagingVM: MessagingHomeViewModel()), mailVM: MailViewModel())
            .previewDevice("iPhone 14 Pro Max")
    }
}
