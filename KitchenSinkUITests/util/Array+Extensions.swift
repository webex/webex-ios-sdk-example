import Foundation

extension Array where Element: Comparable {
    func element(at index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    func isAscending() -> Bool {
        return zip(self, self.dropFirst()).allSatisfy(<=)
    }

    func isDescending() -> Bool {
        return zip(self, self.dropFirst()).allSatisfy(>=)
    }
}
