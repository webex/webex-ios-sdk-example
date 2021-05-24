import UIKit

extension UILabel {
    static func placeholderLabel(withText text: String?) -> UILabel {
        let label = UILabel(frame: .zero)
        label.text = text
        label.textColor = .grayColor
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title2)
        return label
    }
}
