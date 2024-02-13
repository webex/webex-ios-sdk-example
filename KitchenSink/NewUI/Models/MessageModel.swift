import Foundation
import WebexSDK

/// A structure representing a message.
struct MessageKS {
    var messageId: String
    var sender: String
    var text: String
    var isCurrentUser: Bool
    var isReply: Bool
    var parentMessageId: String
    var timeStamp: String
    var thumbnail: [UIImage]
    var message: Message

    ///constructs a `MessageKS` instance from a `WebexSDK.Message` object.
    static func buildFrom(message: Message) -> Self {
        let defaultMessageKS = MessageKS(messageId: "", sender: "", text: "", isCurrentUser: false, isReply: false, parentMessageId: "", timeStamp: "", thumbnail: [], message: message)
        guard let selfId = UserDefaults.standard.value(forKey: Constants.selfId) as? String else { return defaultMessageKS }
        guard let personId = message.personId else { return defaultMessageKS }
        let isSelfUser = selfId == personId ? true : false

        return MessageKS(messageId: message.id ?? "", sender: message.personDisplayName ?? "", text: message.text ?? "", isCurrentUser: isSelfUser, isReply: message.isReply, parentMessageId: message.parentId ?? "", timeStamp: getLocalDate(serverDate: message.created), thumbnail: [], message: message)
    }
}
