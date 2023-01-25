import UIKit

extension UIViewController {
    func showLoadingIndicator(_ text: String = "") {
        DispatchQueue.main.async {
            if !(UIApplication.shared.topViewController() is LoadingViewController) {
                UIApplication.shared.topViewController()?.present(LoadingViewController(text: text), animated: true)
            }
        }
    }
    
    func dismissLoadingIndicator() {
        DispatchQueue.main.async {
            if UIApplication.shared.topViewController() is LoadingViewController {
                UIApplication.shared.topViewController()?.dismiss(animated: true)
            }
        }
    }
}
