import UIKit
extension UIAlertController {
    // Special helper to prevent crashes on iPad for actionSheets
    class func actionSheetWith(title: String?, message: String?, sourceView: UIView) -> UIAlertController {
        let actionController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        if actionController.responds(to: #selector(getter: popoverPresentationController)) {
            actionController.popoverPresentationController?.sourceView = sourceView
            actionController.popoverPresentationController?.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            actionController.popoverPresentationController?.permittedArrowDirections = []
        }
        return actionController
    }
}
