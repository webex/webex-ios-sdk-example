import Foundation
import WebexSDK

public struct TranscriptionKS: Identifiable, Hashable {
    public let id: UUID // Unique identifier
    public let personName: String
    public let personId: String
    public let content: String
    public let timestamp: String

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.personId)
        hasher.combine(personName)
        hasher.combine(timestamp)
        hasher.combine(content)
    }
    
    public static func == (lhs: TranscriptionKS, rhs: TranscriptionKS) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Transcription: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.personId)
        hasher.combine(personName)
        hasher.combine(timestamp)
        hasher.combine(content)
    }
    
    public static func == (lhs: Transcription, rhs: Transcription) -> Bool {
        return lhs.personName == rhs.personName
    }
}

extension LanguageItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(languageTitle)
    }
    
    public static func == (lhs: LanguageItem, rhs: LanguageItem) -> Bool {
        return lhs.languageTitle == rhs.languageTitle
    }
}

public struct CaptionItemKS: Identifiable {
    public var id: UUID
    
    public var contactId: String
    public var displayName: String
    public var timeStamp: String
    public var content: String
    public var languageCode: String
    public var isFinal: Bool
    
    public init(contactId: String, displayName: String, timeStamp: String, content: String, languageCode: String, isFinal: Bool) {
        self.id = UUID()
        self.contactId = contactId
        self.displayName = displayName
        self.timeStamp = timeStamp
        self.content = content
        self.languageCode = languageCode
        self.isFinal = isFinal
    }
    
    public init(from captionItem: CaptionItem) {
        self.id = UUID()
        self.contactId = captionItem.contactId
        self.displayName = captionItem.displayName
        self.timeStamp = captionItem.timeStamp
        self.content = captionItem.content
        self.languageCode = captionItem.languageCode
        self.isFinal = captionItem.isFinal
    }
}
