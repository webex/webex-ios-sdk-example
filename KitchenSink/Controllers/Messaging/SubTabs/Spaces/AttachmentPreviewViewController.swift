import UIKit
import WebKit

class AttachmentPreviewViewController: UIViewController {
    private let previewUrl: URL
    
    private let webView: WKWebView = {
        let webView = WKWebView()
        webView.isUserInteractionEnabled = true
        webView.scrollView.isScrollEnabled = false
        return webView
    }()
    
    init(previewUrl: URL) {
        self.previewUrl = previewUrl
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Preview"
        webView.loadFileURL(previewUrl, allowingReadAccessTo: previewUrl)
        webView.frame.size = self.view.frame.size
        self.view.addSubview(webView)
    }
}
