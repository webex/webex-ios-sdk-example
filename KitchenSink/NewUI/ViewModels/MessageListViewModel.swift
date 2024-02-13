import Foundation
import WebexSDK

@available(iOS 16.0, *)
class MessageListViewModel: ObservableObject {

    @Published var messages: [MessageKS] = []
    @Published var markedAsRead: Bool = false
    @Published var showfileSheet: Bool = false
    @Published var fileURL: URL?
    @Published var showProgress: Bool = false
    @Published var progress: Double = 0
    @Published var size: Double = 100
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var error: String = ""
    @Published var replySent: Bool = false

    var webexMessage = WebexMessage()
    
    init() {
        syncMessages()
    }

    /// Fetches a list of messages in a specific space
    func listMessages(spaceId: String, before: Before? = nil) {
        loadingIndicator(show: true)
        webexMessage.listMessages(spaceId: spaceId, before: before, queue: .global(qos: .default), completion: { result in
            switch result {
            case .success(let msgsKS):
                self.loadingIndicator(show: false)
                    for msgKS in msgsKS {
                        if msgKS.message.files?.count ?? 0 > 0 {
                            DispatchQueue.global(qos: .background).async {
                                self.downloadThumbnail(message: msgKS)
                            }
                        }
                    }
                DispatchQueue.main.async {
                    self.messages = msgsKS
                }
            case .failure(let err):
                self.loadingIndicator(show: false)
                print(err)
                self.showError(error: err)
            @unknown default:
                break
            }
        })
    }

    /// Synchronizes the list of messages by handling various message events i.e. received, deleted, updated
    func syncMessages() {
        webex.messages.onEvent = { messageEvent in
            switch messageEvent {
            case .messageDeleted(let messageId):
                guard let index = self.messages.firstIndex(where: { $0.messageId == messageId }) else { return }
                DispatchQueue.main.async {
                    self.messages.remove(at: index)
                }
            case .messageReceived(let message):
                if self.messages.count > 0 {
                    if message.spaceId == self.messages[0].message.spaceId {
                        let messageKS = MessageKS.buildFrom(message: message)
                        DispatchQueue.main.async {
                            self.messages.append(messageKS)
                        }
                        if message.files?.count ?? 0 > 0 {
                            self.downloadThumbnail(message: messageKS)
                        }
                    }
                }
            case .messageUpdated(let messageId, let type):
                guard let index = self.messages.firstIndex(where: { $0.messageId == messageId }) else { return }

                switch type {
                case .fileThumbnail(_):
                    break
                case .message(let message):
                    self.messages[index] = MessageKS.buildFrom(message: message)
                @unknown default:
                    break
                }
            case .messagesUpdated(let msgs):
                self.listMessages(spaceId: msgs[0].spaceId ?? "")
            @unknown default:
                break
            }
        }
    }

    /// Downloads the thumbnail for a specific message
    func downloadThumbnail(message: MessageKS) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let thumbnailDirectory = documentDirectory?.appendingPathComponent("Thumbnails") else { return }
        do {
            try FileManager.default.createDirectory(atPath: thumbnailDirectory.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }

        guard let remoteFiles = message.message.files else { return }
        webexMessage.downloadThumbnail(remoteFiles: remoteFiles, thumbnailDirectory: thumbnailDirectory, messages: self.messages, completion: { result in
            switch result {
            case .success(let message):
                guard let index = self.messages.firstIndex(where: { $0.messageId == message.messageId }) else { return }
                DispatchQueue.main.async {
                    self.messages[index] = message
                }
            case .failure(let err):
                self.showError(error: err)
            @unknown default:
                break
            }
        })
    }

    /// Downloads the remote file.
    func downloadFile(remoteFile: RemoteFile) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        var docString = documentDirectory?.absoluteString ?? ""
        docString = docString.replacingOccurrences(of: "file://", with: "")
        webexMessage.downloadFile(remoteFile: remoteFile, docString: docString, progress: { progress in
            DispatchQueue.main.async {
                self.showProgress = true
                self.progress = progress
                self.size = Double(remoteFile.size ?? 100)
            }
        }, completion: { result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self.progress = 0
                    self.size = 100
                    self.showProgress = false
                    self.showfileSheet = true
                    self.fileURL = url
                }
            case .failure(let err):
                self.showError(error: err)
            @unknown default:
                break
            }
        })
    }

    /// Marks a specific message as read
    func markMessageAsRead(message: MessageKS) {
        self.loadingIndicator(show: true)
        webexMessage.markAsRead(spaceId: message.message.spaceId ?? "", messageId: message.messageId, completion: { result in
            switch result {
            case .success():
                self.loadingIndicator(show: false)
                self.markedAsRead = true
            case .failure(let err):
                self.loadingIndicator(show: false)
                print(err)
                self.showError(error: err)
            @unknown default:
                break
            }
        })
    }

    /// Edits the text of a specific message
    func editMessage(text: String, message: MessageKS) {
        self.loadingIndicator(show: true)
        var textMode = "Plain"
        if message.message.textAsObject?.html != nil {
            textMode = "HTML"
        } else if message.message.textAsObject?.markdown != nil {
            textMode = "Markdown"
        }
        let messageText = MessageComposerUtil().convertTextToMessageText(text: text, textMode: textMode)
        webexMessage.edit(messageText: messageText, message: message.message, completion: { result in
            switch result {
            case .success(_):
                self.loadingIndicator(show: false)
                print("message edited")
            case .failure(let err):
                self.loadingIndicator(show: false)
                print(err)
                self.showError(error: err)
            @unknown default:
                break
            }
        })
    }

    /// Deletes a specific message
    func deleteMessage(message: MessageKS) {
        webexMessage.delete(messageId: message.messageId, completion: { result in
            switch result {
            case .success():
                print("message deleted")
            case .failure(let err):
                self.showError(error: err)
            @unknown default:
                break
            }
        })
    }

    /// Sends reply to the parent message.
    func sendReply(parent: MessageKS, text: String) {
        self.loadingIndicator(show: true)
        var parentMessage: Message?
        if parent.isReply {
            guard let parentMessageIndex = messages.firstIndex(where: { $0.messageId == parent.message.parentId }) else {
                print("parent message index not found")
                return
            }
            parentMessage = self.messages[parentMessageIndex].message
        } else {
            parentMessage = parent.message
        }

        let messageText = MessageComposerUtil().convertTextToMessageText(text: text, textMode: "Plain")
        webexMessage.postMessage(messageText: messageText, spaceId: parent.message.spaceId ?? "", parent: parentMessage, completion: {
            result in
            switch result {
            case .success(_):
                self.loadingIndicator(show: false)
                DispatchQueue.main.async {
                    self.replySent = true
                }
            case .failure(let err):
                self.loadingIndicator(show: false)
                self.showError(error: err)
            @unknown default:
                break
            }
        })
    }

    /// Asynchronously controls the visibility of a loading indicator on the main queue.
    func loadingIndicator(show: Bool) {
        DispatchQueue.main.async {
            self.isLoading = show
        }
    }

    /// Asynchronously displays an error message on the main queue.
    func showError(error: Error) {
        DispatchQueue.main.async {
            self.showError = true
            self.error = error.localizedDescription
        }
    }
}
