import SwiftUI
import AVFoundation
import WebexSDK

@available(iOS 16.0, *)
class MessageComposerViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var isSent: Bool = false
    @Published var text: String = ""
    @Published var sentText: String = ""
    @Published var images: [UIImage] = []
    @Published var mentionList: [PersonDataKS] = []
    @Published var mentions: [Mention] = []
    @Published var showError: Bool = false
    @Published var error: String = ""
    var localFiles: [LocalFile] = []

    var webexMessage = WebexMessage()
    var webexSpace = WebexSpaces()
    var webexPeople = WebexPeople()
    var webexMebembership = WebexMembership()
    
    var messageComposerUtil = MessageComposerUtil()
    
    /// Sends a message to a specific space
    func sendMessage(id: String, text: String, textMode: String, mentions:[Mention]?) {
        self.showLoading(show: true)
        let messageText = messageComposerUtil.convertTextToMessageText(text: text, textMode: textMode)
        webexMessage.postMessage(messageText: messageText, spaceId: id, mentions: mentions, localFiles: localFiles, completion: { result in
            switch result {
            case .success(let message):
                self.showLoading(show: false)
                DispatchQueue.main.async {
                    self.isSent = true
                    self.text = ""
                    self.sentText = message.text ?? ""
                    self.localFiles = []
                    self.images = []
                }
            case .failure(let err):
                self.showLoading(show: false)
                self.showError(error: err)
            @unknown default:
                break
            }
        })
    }

    /// Adds a local file to the array of local files using provided file information.
    func addLocalFile(info: [UIImagePickerController.InfoKey: Any]) {
        localFiles = messageComposerUtil.addLocalFile(info: info, currentLocalFiles: localFiles)
    }

    /// Fetches the memberships of a space asynchronously.
    func getMembershipAsync(spaceId: String, max: Int? = nil) async throws -> [Membership] {
        return try await withCheckedThrowingContinuation { continuation in
            webexMebembership.listMemberships(spaceId: spaceId, queue: DispatchQueue.global(qos: .default)){ result in
                switch result {
                case .success(let memberships):
                    continuation.resume(returning: memberships)
                case .failure(let error):
                    continuation.resume(throwing: error)
                @unknown default:
                    break
                }
            }
        }
    }
    
    /// Asynchronously fetches a space by its ID
    func getSpaceAsync(spaceId: String) async throws -> Space {
        return try await withCheckedThrowingContinuation { continuation in
            webexSpace.fetchSpace(byId: spaceId) { result in
                switch result {
                case .success(let space):
                    continuation.resume(returning: space)
                case .failure(let error):
                    continuation.resume(throwing: error)
                @unknown default:
                    break
                }
            }
        }
    }
    
    /// Asynchronously fetches the details of the current user
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

    /// Asynchronously fetches all the members of a space who can be mentioned in a message.
    func getAllMentionsListAsync(spaceId: String) async {
        showLoading(show: true)
        DispatchQueue.main.async { [weak self] in
            self?.mentionList = [PersonDataKS(id: "", personName: "All")]
        }
        Task.init(operation: {
            do {
                let space = try await getSpaceAsync(spaceId: spaceId)
                if space.type == .group {
                    let memberships = try await getMembershipAsync(spaceId: space.id ?? "")
                    let me = try await getMeAsync()
                    for membership in memberships {
                        let person = PersonData(personId: (membership.personId ?? ""), personName: membership.personDisplayName ?? "")
                        if person.personId != me.id {
                            self.showLoading(show: false)
                            DispatchQueue.main.async { [weak self] in
                                self?.mentionList.append(PersonDataKS.buildFrom(personData: person))
                            }
                        }
                    }
                } else {
                    self.showLoading(show: false)
                }
            }
            catch {
                self.showLoading(show: false)
                self.showError(error: error)
            }
        })
    }

    /// Asynchronously shows an error message on the main queue.
    func showError(error: Error) {
        DispatchQueue.main.async {
            self.showError = true
            self.error = error.localizedDescription
        }
    }

    /// Asynchronously controls the visibility of a loading indicator on the main queue.
    func showLoading(show: Bool) {
        DispatchQueue.main.async {
            self.isLoading = show
        }
    }
}
