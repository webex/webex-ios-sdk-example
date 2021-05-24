import UIKit

extension UIAlertAction {
    static func dismissAction(withTitle title: String = "Cancel") -> UIAlertAction {
        return UIAlertAction(title: title, style: .cancel)
    }
}
