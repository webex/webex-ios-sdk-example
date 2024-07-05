import SwiftUI
import WebKit

@available(iOS 16.0, *)
struct WebView: UIViewRepresentable {
    var viewModel: LoginViewModel

    let webView = WKWebView()

    func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
        self.webView.navigationDelegate = context.coordinator
        if #available(iOS 16.4, *) {
            self.webView.isInspectable = true
        }
        self.webView.accessibilityIdentifier = "webView"
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

@available(iOS 16.0, *)
struct WebFileView: UIViewRepresentable {

    var url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

@available(iOS 16.0, *)
struct WebView_Previews: PreviewProvider {
    static var previews: some View {

        WebView(viewModel: LoginViewModel(link: URL(string: "https://google.com")!, redirectUri: "https://google.com"))
    }
}
