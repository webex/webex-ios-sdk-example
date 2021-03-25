extension Character {
    static func lowercaseLetters() -> [Character] {
        let aScalars = "a".unicodeScalars
        let aCode = aScalars[aScalars.startIndex].value
        return (0..<26).compactMap { i in
            guard let scalar = UnicodeScalar(aCode + UInt32(i)) else { return nil }
            return Character(scalar)
        }
    }
}
