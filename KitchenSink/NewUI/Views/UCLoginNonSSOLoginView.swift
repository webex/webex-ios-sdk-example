import SwiftUI

@available(iOS 16.0, *)
struct UCLoginNonSSOLoginView: View {
    @ObservedObject var viewModel: UCLoginServicesViewModel
    var body: some View {
            VStack {
                // Username TextField
                Text("UC Services Non SSO Login").font(.title)
                
                TextField("Username", text: $viewModel.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .accessibilityIdentifier("nonSSOUsername")

                // Password SecureField
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .accessibilityIdentifier("nonSSOPassword")

                // Login Button
                Button(action: {
                    viewModel.loginNonSSO()
                }) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
                .disabled(viewModel.username.isEmpty || viewModel.password.isEmpty) // Disable button if fields are empty
                .accessibilityIdentifier("nonSSOlogin")
                
                Spacer() // Pushes all content to the top
            }
            .padding()
    }
}

@available(iOS 16.0, *)
struct PhoneServicesView_Previews: PreviewProvider {
    static var previews: some View {
        UCLoginNonSSOLoginView(viewModel: UCLoginServicesViewModel())
            .previewDevice("iPhone 14 Pro Max")
    }
}
