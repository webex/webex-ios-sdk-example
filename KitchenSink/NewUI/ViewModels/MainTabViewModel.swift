import Foundation
import UIKit
import WebexSDK
@available(iOS 16.0, *)
class MainTabViewModel: ObservableObject {

    var webexPeople = WebexPeople()
    var webexPhone = WebexPhone()

    // Asynchronously fetches the details of the current user
    func getMeAsync() async throws -> Person {
        return try await withCheckedThrowingContinuation { continuation in
            webexPeople.getMe { result in
                switch result {
                case .success(let person):
                    UserDefaults.standard.set(person.id, forKey: Constants.selfId)
                    continuation.resume(returning: person)
                case .failure(let error):
                    continuation.resume(throwing: error)
                @unknown default:
                    break
                }
            }
        }
    }

    // Registers the user for push notifications with webhook
    func deviceRegistration() async {
        Task.init(operation: {
            do {
                let person = try await getMeAsync()
                guard let personId = person.encodedId else {
                    print("Unable to register User for Push notifications with webhook handling server because of missing emailId or person details")
                    return
                }
                guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") else { return }
                guard let keys = NSDictionary(contentsOfFile: path) else { return }
                guard let token = token, let voipToken = voipToken else { return }

                if let urlString = keys["registrationUrl"] as? String  {
                    guard let serviceUrl = URL(string: urlString) else { print("Invalid URL"); return }

                    let parameters: [String: Any] = [
                        "voipToken": voipToken,
                        "deviceToken": token,
                        "pushProvider": "APNS",
                        "userId": personId,
                        "prod": false
                    ]
                    var request = URLRequest(url: serviceUrl)
                    request.httpMethod = "POST"
                    request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
                    guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                        return
                    }
                    request.httpBody = httpBody
                    request.timeoutInterval = 20
                    let session = URLSession.shared
                    session.dataTask(with: request) { (data, response, error) in
                        if let response = response {
                            print("DEVICE REGISTRATION: \(response)")
                        }
                    }.resume()
                }
                else {
                    let bundleId = keys["bundleId"] as? String ?? ""

                    await webexPhone.setPushTokens(bundleId: bundleId, deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "", deviceToken: token, voipToken: voipToken, appId: nil)
                    return
                }
            }
            catch {
                print(error)
            }
        })
    }
}
