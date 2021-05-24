import XCTest

extension NSPredicate {
    convenience init(labelContainsText text: String) {
        self.init(format: "label CONTAINS[c] %@", text)
    }
}
