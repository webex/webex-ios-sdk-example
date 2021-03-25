import Foundation
import WebexSDK

enum EncryptionError: Error {
    case componentCountMismatch
    case dataConversionFailed
    case stringConversionFailed
    case tagDataMismatch
}

class EncryptionUtils {
    /// This is a sample method to decrypt CUCM payload content. The content is JWE encrypted using AES256GCM encryption algorithm.
    /// More info on JWE - https://tools.ietf.org/html/rfc7516
    ///
    /// - parameter payload : JWE format string. (<header>.<encrypted key>.<init vector>.<cipher text>.<tag>)
    /// - parameter key : 256 bit symmetric key that was used to encrypt the content
    /// - returns : Decryted message
    static func decrpytCUCMPayload(_ payload: String, key: String) throws -> String {
        let components = payload.components(separatedBy: ".")
        guard components.count == 5 else { throw EncryptionError.componentCountMismatch }
        let header = components[0]
        let initVector = components[2]
        let cipherText = components[3]
        let tag = components[4]
        
        guard let headerData = header.data(using: .ascii), let keyData = key.data(using: .utf8), let initVectorData = decodeBase64URL(initVector), let cipherTextData = decodeBase64URL(cipherText), let tagData = decodeBase64URL(tag) else { throw EncryptionError.dataConversionFailed }
        
        let (messageData, extractedTagData) = try CC.GCM.crypt(.decrypt, algorithm: .aes, data: cipherTextData, key: keyData, iv: initVectorData, aData: headerData, tagLength: 16)
        guard extractedTagData == tagData else { throw EncryptionError.tagDataMismatch }
        guard let message = String(data: messageData, encoding: .utf8) else { throw EncryptionError.stringConversionFailed }
        return message
    }
    
    static func decodeBase64URL(_ string: String) -> Data? {
        let remainder = string.count % 4
        let ending = remainder > 0 ? String(repeating: "=", count: 4 - remainder) : ""
        let base64 = string.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/") + ending
        return Data(base64Encoded: base64)
    }
    
    static func decodeBase64String(_ base64String: String) -> String? {
        guard let base64Data = Data(base64Encoded: base64String),
              let string = String(data: base64Data, encoding: .utf8)
        else {
            print("Base64Decoding failed. String: \(base64String)")
            return nil
        }
        return string
    }
}

class PushPayloadParseUtils {
    typealias MessageNotificationInfo = (messageId: String, spaceId: String)
    
    static func parseMessagePayload(_ dict: [String: Any]) -> MessageNotificationInfo? {
        guard let dataDict = dict["data"] as? [String: Any],
              let messageIdBase64 = dataDict["id"] as? String,
              let messageId = parseIdFromBase64Encoded(messageIdBase64),
              let roomIdBase64 = dataDict["roomId"] as? String,
              let roomId = parseIdFromBase64Encoded(roomIdBase64)
        else {
            print("Push notification info parse error")
            return nil
        }
        return (messageId, roomId)
    }
    
    static func parseWebexCallPayload(_ dict: [String: Any]) -> String? {
        guard let dataDict = dict["data"] as? [String: Any],
              let callIdBase64 = dataDict["callId"] as? String,
              let callId = parseIdFromBase64Encoded(callIdBase64)
        else {
            print("Push notification info parse error")
            return nil
        }
        return callId
    }
    
    static func parseCUCMCallPayload(_ dict: [String: Any]) -> String? {
        guard let payload = dict["data"] as? String else {
            print("Push notification info parse error")
            return nil
        }

        // This is a sample 256 bit symmetric key used for example purpose.
        let key = "@McQfTjWnZr4u7x!A%D*G-KaNdRgUkXp"
        do {
            let decryptedContent = try EncryptionUtils.decrpytCUCMPayload(payload, key: key)
            guard let contentData = decryptedContent.data(using: .utf8),
                  let jsonDict = try JSONSerialization.jsonObject(with: contentData, options: []) as? [String: Any],
                  let pushId = jsonDict["pushid"] as? String
            else { throw EncryptionError.dataConversionFailed }
            return pushId
        } catch {
            print("Parsing CUCM call payload failed: \(error.localizedDescription)")
        }
        return nil
    }
    
    static func parseIdFromBase64Encoded(_ encodedString: String) -> String? {
        guard let decodedString = EncryptionUtils.decodeBase64String(encodedString),
              let url = URL(string: decodedString),
              let id = url.pathComponents.last
        else {
            print("Parsing ID from base64EncodedString failed. String: \(encodedString)!")
            return nil
        }
        return id
    }
}
