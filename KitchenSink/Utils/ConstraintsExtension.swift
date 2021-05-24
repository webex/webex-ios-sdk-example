import UIKit

extension NSLayoutConstraint {
    func activate() {
        isActive = true
    }
    
    func deactivate() {
        isActive = false
    }
}
