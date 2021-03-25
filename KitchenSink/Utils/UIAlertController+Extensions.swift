import UIKit

extension UIAlertController {
    static func createWithTextField(title: String?, message: String?, style: UIAlertController.Style, textFieldHandler: ((UITextField) -> Void)? = nil, cancelAction: UIAlertAction = .dismissAction()) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        alertController.addTextField(configurationHandler: textFieldHandler)
        alertController.addAction(cancelAction)
        return alertController
    }
}
