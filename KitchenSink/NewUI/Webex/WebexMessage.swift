import WebexSDK

class WebexMessage {
    /// Posts a new message to the specified space.
    func postMessage(messageText: Message.Text, spaceId: String, mentions: [Mention]? = nil, localFiles: [LocalFile]? = nil, parent: Message? = nil, completion: @escaping (Result<Message>) -> Void) {
        webex.messages.post(messageText, toSpace: spaceId, mentions: mentions, withFiles: localFiles, parent: parent, queue: nil, completionHandler: completion)
    }

    /// Lists all the messages in the specified space.
    func listMessages(spaceId: String, before: Before? = nil, queue: DispatchQueue?, completion: @escaping (Result<[MessageKS]>) -> Void) {
        webex.messages.list(spaceId: spaceId, before: before, queue: queue, completionHandler: { result in
            switch result {
            case .success(let msgs):
                let messages: [MessageKS] = msgs.map{ MessageKS.buildFrom(message: $0) }
                completion(.success(messages))
            case .failure(let err):
                completion(.failure(err))
            @unknown default:
                break
            }
        })
    }

    /// Edits an existing message.
    func edit(messageText: Message.Text, message: Message, completion: @escaping (Result<MessageKS>) -> Void) {
        webex.messages.edit(messageText, parent: message, completionHandler: { result in
            switch result {
            case .success(let msg):
                completion(.success(MessageKS.buildFrom(message: msg)))
            case .failure(let err):
                completion(.failure(err))
            @unknown default:
                break
            }
        })
    }

    /// Deletes a specified message by its identifier.
    func delete(messageId: String, completion: @escaping (Result<Void>) -> Void) {
        webex.messages.delete(messageId: messageId, completionHandler: { result in
            switch result {
            case .success():
                completion(.success(()))
            case .failure(let err):
                completion(.failure(err))
            @unknown default:
                break
            }
        })
    }

    /// Marks a specified message as read.
    func markAsRead(spaceId: String, messageId: String, completion: @escaping (Result<Void>) -> Void) {
        webex.messages.markAsRead(spaceId: spaceId, messageId: messageId, completionHandler: { result in
            switch result {
            case .success():
                completion(.success(()))
            case .failure(let err):
                completion(.failure(err))
            @unknown default:
                break
            }
        })
    }

    /// Downloads the thumbnail for the specified remote files.
    func downloadThumbnail(remoteFiles: [RemoteFile], thumbnailDirectory: URL, messages: [MessageKS], completion: @escaping (Result<MessageKS>) -> Void) {
        guard let index = messages.firstIndex(where: { $0.messageId == remoteFiles[0].messageId }) else { return }
        var thumbnails: [UIImage] = []
        var newMessage = messages[index]
        for remoteFile in remoteFiles {
            webex.messages.downloadThumbnail(for: remoteFile, to: thumbnailDirectory, completionHandler: { result in
                switch result {
                case .success(let result):
                    guard let result = result else { return }
                    let resultString = result.absoluteString
                    let imageUrl = resultString.replacingOccurrences(of: "file://", with: "")
                    thumbnails.append(UIImage(contentsOfFile: imageUrl) ?? UIImage())
                case .failure(let error):
                    completion(.failure(error))
                @unknown default:
                    break
                }
            })
        }
        if thumbnails.count > 0 {
            for thumbnail in thumbnails {
                newMessage.thumbnail.append(thumbnail)
            }
            completion(.success(newMessage))
        }
    }

    /// Downloads a file from a remote location.
    func downloadFile(remoteFile: RemoteFile, docString: String, progress: ((Double) -> Void)?, completion: @escaping (Result<URL>) -> Void) {
        webex.messages.downloadFile(remoteFile, to: URL(string: docString), progressHandler: progress, completionHandler: { fileUrl in
            switch fileUrl {
            case .success(let fileUrl):
                guard let fileUrl = fileUrl else { return }
                completion(.success(fileUrl))
            case .failure(let error):
                completion(.failure(error))
            @unknown default:
                break
            }
        })
    }
}
