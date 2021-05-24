import UIKit
import WebexSDK

protocol PushNotificationHandler {
    func handleMessageNotification(_ id: String, spaceId: String)
    func handleWebexCallNotification(_ id: String)
    func handleCUCMCallNotification(_ id: String)
}

extension PushNotificationHandler {
    func getPushedMessage(from id: String, spaceId: String, completion: @escaping (Message?) -> Void) {
        webex.messages.get(messageId: id) { result in
            switch result {
            case let .success(message): completion(message)
            case .failure:
                webex.messages.list(spaceId: spaceId, max: 100) { result in
                    switch result {
                    case let .success(messages):
                        guard let message = messages.first(where: { $0.id == id }) else {
                            print("Message with \(id) not found in the list retreived")
                            completion(nil)
                            return
                        }
                        completion(message)
                    case let .failure(error):
                        print("Failed to retreive message with \(id) : \(error.localizedDescription)")
                        completion(nil)
                    }
                }
            }
        }
    }
}

extension UINavigationController: PushNotificationHandler {
    func handleMessageNotification(_ id: String, spaceId: String) {
        getPushedMessage(from: id, spaceId: spaceId) { [weak self] message in
            guard let message = message else {
                self?.showAlert(title: "Oops!", message: "Failed to retreive message!")
                return
            }
            self?.showAlert(title: "Message from \(message.personEmail ?? "")", message: message.text ?? "nil", attributedString: message.text?.htmlToAttributedString)
        }
    }
    
    func handleWebexCallNotification(_ id: String) {
        let webexCallId = webex.phone.getCallIdFromNotificationId(notificationId: id, notificationType: .Webex)
        showIncomingCallScreen(callId: webexCallId)
    }
    
    func handleCUCMCallNotification(_ id: String) {
        let cucmCallId = webex.phone.getCallIdFromNotificationId(notificationId: id, notificationType: .CUCM)
        showIncomingCallScreen(callId: cucmCallId)
    }
    
    private func showIncomingCallScreen(callId: String) {
        if let presentedController = self.presentedViewController {
            presentedController.dismiss(animated: false) { self.pushViewController(IncomingCallViewController(incomingCallId: callId), animated: true) }
            return
        }
        pushViewController(IncomingCallViewController(incomingCallId: callId), animated: true)
    }
    
    private func showAlert(title: String, message: String, attributedString: NSAttributedString? = nil) {
        let alert = UIAlertController(title: title, message: attributedString == nil ? message : "", preferredStyle: .alert)
        if let attributedString = attributedString {
            alert.setValue(attributedString, forKey: "attributedMessage")
        }
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel))
        if let presentedController = self.presentedViewController {
            presentedController.present(alert, animated: true)
            return
        }
        present(alert, animated: true)
    }
}
