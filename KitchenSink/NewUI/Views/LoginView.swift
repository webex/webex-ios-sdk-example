import SwiftUI

@available(iOS 16.0, *)
struct LoginView: View {

    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var model = LoginViewModel(link: URL(string: "https://google.com")!, redirectUri: "")

    @State var showingEmailAlert = false
    @State var showingOAuthAlert = false
    @State var showingGuestAlert = false
    @State var showWebView = false
    @State var isFedRAMPEnabled = UserDefaults.standard.bool(forKey: Constants.fedRampKey)
    @State var loginValue = ""
    @State var loginUrl = ""
    @State var versionText = ""

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer(minLength: UIScreen.main.bounds.width/2 + 80)
                    KSButton(text: "FedRAMP \n Mode", didTap: isFedRAMPEnabled, action: toggleFedRampMode)
                        .accessibilityIdentifier("fedrampModeButton")
                        .frame(height: 100)
                        .onAppear(perform: tryAutoLogin)
                    Spacer()
                }
                if colorScheme == .light {
                    Image(uiImage: UIImage(named: "Kitchensink-light")!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 300)
                } else {
                    Image(uiImage: UIImage(named: "Kitchensink-dark")!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 300)
                }

                KSButton(text: "Email ID", didTap: showingEmailAlert, action: loginWithEmail)
                    .alert(isPresented: $showingEmailAlert, title: "Login With Email", textFieldValue: $loginValue, action: doEmailLoginAction)
                    .accessibilityIdentifier("emailLoginButton")
                    .padding()
                    .sheet(isPresented: $model.showWebView) {
                        WebView(viewModel: model)
                            .onDisappear(perform: doLoginAction)
                    }
                KSButton(text: "Guest Token", didTap: showingGuestAlert, action: loginWithGuestToken)
                    .alert(isPresented: $showingGuestAlert, title: "Login With Guest Token", textFieldValue: $loginValue, action: doGuestLoginAction)
                    .accessibilityIdentifier("guestLoginButton")
                    .padding()
                KSButton(text: "OAuth Token", didTap: showingOAuthAlert, action: loginWithOAuthToken)
                    .alert(isPresented: $showingOAuthAlert, title: "Login With OAuth Token", textFieldValue: $loginValue, action: doOAuthLoginAction)
                    .accessibilityIdentifier("oAuthTokenLoginButton")
                    .padding()
                Spacer()
                Text(versionText)
                    .onAppear(perform: getVersionLabelText)
                    .accessibilityIdentifier("versionLabel")

            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            if model.showLoading {
                ActivityIndicatorView()
            }
        }
        .fullScreenCover(isPresented: $model.isLoggedIn) {
            MainTabView()
        }
    }

    /// Toggles the state of the email alert, which triggers its display or dismissal.
    func loginWithEmail() {
        showingEmailAlert.toggle()
    }

    /// Toggles the state of the guest alert, which triggers its display or dismissal.
    func loginWithGuestToken() {
        showingGuestAlert.toggle()
    }

    /// Toggles the state of the OAuth alert, which triggers its display or dismissal.
    func loginWithOAuthToken() {
        showingOAuthAlert.toggle()
    }

    /// Toggles the state of FedRAMP mode.
    func toggleFedRampMode() {
        isFedRAMPEnabled.toggle()
    }

    /// Initiates a login action with an authorization code using the model.
    func doLoginAction() {
        model.loginWithAuthCode(code: model.code)
    }

    /// Initiates an email login action with the given email and FedRAMP mode state using the model.
    func doEmailLoginAction() {
        guard let authenticator = model.getAuthenticator(type: .email, email: loginValue, isFedRAMPMode: isFedRAMPEnabled) else { return }
        model.doEmailLogin(email: loginValue, authenticator: authenticator)
    }

    /// Initiates a guest login action with the given guest token using the model.
    func doGuestLoginAction() {
        guard let authenticator = model.getAuthenticator(type: .jwt) else { return }
        model.doGuestLogin(guestToken: loginValue, authenticator: authenticator)
    }

    /// Initiates an OAuth login action with the given OAuth token and FedRAMP mode state using the model.
    func doOAuthLoginAction() {
        guard let authenticator = model.getAuthenticator(type: .token, isFedRAMPMode: isFedRAMPEnabled) else { return }
        model.doOAuthLogin(OAuthToken: loginValue, authenticator: authenticator)
    }

    /// Fetches and updates the version information text using the model.
    func getVersionLabelText() {
        versionText = model.getVersionInfo()
    }

    /// Initiates an auto login action based on the saved authentication type
    func tryAutoLogin() {
        var authType: AuthType = .token
        guard let type = UserDefaults.standard.string(forKey: Constants.loginTypeKey) else { return }
        if type == Constants.loginTypeValue.email.rawValue {
            authType = .email
        } else if type == Constants.loginTypeValue.jwt.rawValue {
            authType = .jwt
        } else {
            authType = .token
        }
        let email = UserDefaults.standard.string(forKey: Constants.emailKey)
        guard let authenticator = model.getAuthenticator(type: authType, email: email, isFedRAMPMode: isFedRAMPEnabled) else { return }
        model.tryAutoLogin(authenticator: authenticator, loginType: type, email: email ?? "")
    }
}

@available(iOS 16.0, *)
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .previewDevice("iPhone 14 Pro Max")
    }
}

@available(iOS 16.0, *)
public extension View {
    /// Presents an alert with a text field and an OK button
    func alert(isPresented: Binding<Bool>,
               title: String,
               dismissButton: Alert.Button? = nil,
               textFieldValue: Binding<String>,
               action: @escaping () -> Void) -> some View {
        ZStack {
            alert(title, isPresented: isPresented) {
                TextField("Enter the value", text: textFieldValue)
                Button("OK", action: action)
            }
        }
    }
}
