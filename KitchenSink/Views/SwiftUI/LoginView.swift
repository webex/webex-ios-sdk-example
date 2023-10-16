import SwiftUI

@available(iOS 15.0, *)
struct LoginView: View {

    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var model = LoginViewModel(link: URL(string: "https://google.com")!, redirectUri: "")

    @State var showingEmailAlert = false
    @State var showingOAuthAlert = false
    @State var showingGuestAlert = false
    @State var showWebView = false
    @State var isFedRAMPEnabled = UserDefaults.standard.bool(forKey: "isFedRAMP")
    @State var loginValue = ""
    @State var loginUrl = ""
    @State var versionText = ""

    var loginVC = LoginVC()

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer(minLength: UIScreen.main.bounds.width/2 + 80)
                    KSButton(text: "FedRAMP \n Mode", didTap: isFedRAMPEnabled, action: toggleFedRampMode)
                        .accessibilityIdentifier("fedrampModeButton")
                        .frame(height: 100)
                        .onAppear(perform: doAutoLogin)
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
                    .popover(isPresented: $model.showWebView) {
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
    }

    func loginWithEmail() {
        showingEmailAlert.toggle()
    }

    func loginWithGuestToken() {
        showingGuestAlert.toggle()
    }

    func loginWithOAuthToken() {
        showingOAuthAlert.toggle()
    }

    func toggleFedRampMode() {
        isFedRAMPEnabled.toggle()
    }

    func doLoginAction() {
        loginVC.loginWithAuthCode(code: model.code)
    }

    func doEmailLoginAction() {
        loginVC.doEmailLogin(email: loginValue, isFedRAMPEnabled: isFedRAMPEnabled, model: model)
    }

    func doGuestLoginAction() {
        loginVC.doGuestLogin(guestToken: loginValue)
    }

    func doOAuthLoginAction() {
        loginVC.doOAuthLogin(OAuthToken: loginValue, isFedRAMPEnabled: isFedRAMPEnabled)
    }

    func getVersionLabelText() {
        versionText = loginVC.getVersionInfo()
    }

    func doAutoLogin() {
        guard let authType = UserDefaults.standard.string(forKey: "loginType") else { return }
        if authType == "jwt" {
            loginVC.doGuestLogin(guestToken: "")
        } else if authType == "token" {
            loginVC.doOAuthLogin(OAuthToken: "", isFedRAMPEnabled: isFedRAMPEnabled)
        } else {
            guard let email = UserDefaults.standard.value(forKey: "userEmail") as? String else { return }
            loginVC.doEmailLogin(email: email, isFedRAMPEnabled: isFedRAMPEnabled, model: model)
        }
    }
}

@available(iOS 15.0, *)
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .previewDevice("iPhone 14 Pro Max")
    }
}

@available(iOS 15.0, *)
public extension View {
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
