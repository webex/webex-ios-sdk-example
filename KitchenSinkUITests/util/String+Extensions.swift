import Foundation

extension String {
    static func random() -> String {
        let length = Int.random(in: 4...9)
        let characters = Character.lowercaseLetters()
        let characterCount = characters.count
        var newString = ""
        
        (Array(1..<length)).forEach { _ in
            newString += String(characters[Int.random(in: 0..<characterCount)])
        }
        
        return newString
    }
}
