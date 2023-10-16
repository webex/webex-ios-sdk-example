import SwiftUI
import WebKit

@available(iOS 13.0, *)
class LoginViewModel: ObservableObject {
    @Published var link: URL?
    @Published var showWebView: Bool = false
    @Published var showLoading: Bool = false
    @Published var redirectUri: String?
    @Published var code: String = ""

    init (link: URL, redirectUri: String) {
        self.link = link
        self.redirectUri = redirectUri
    }
} 

@available(iOS 13.0, *)
struct WebView: UIViewRepresentable {
    var viewModel: LoginViewModel

    let webView = WKWebView()

    func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
        self.webView.navigationDelegate = context.coordinator
        if let url = viewModel.link {
            self.webView.load(URLRequest(url: url))
        }
        return self.webView
    }

    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<WebView>) {
        return
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        private var viewModel: LoginViewModel

        init(_ viewModel: LoginViewModel) {
            self.viewModel = viewModel
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
            if let url = navigationAction.request.url, OAuthUrlUtil.url(url, matchesRedirectUri: viewModel.redirectUri!) {
                decisionHandler(.cancel)
                let code = OAuthUrlUtil.parseOauthCodeFrom(redirectUrl: url)
                viewModel.showWebView = false
                viewModel.code = code!
            } else {
                decisionHandler(.allow)
            }
        }
    }

    func makeCoordinator() -> WebView.Coordinator {
        Coordinator(viewModel)
    }
}

@available(iOS 13.0, *)
struct WebView_Previews: PreviewProvider {
    static var previews: some View {

        WebView(viewModel: LoginViewModel(link: URL(string: "https://google.com")!, redirectUri: "https://www.devtechie.com/"))
    }
}
