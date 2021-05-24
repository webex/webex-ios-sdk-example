import UIKit
import WebexSDK
import WebKit

final class SpaceMessagesTableViewController: BasicTableViewController<Message, MessageTableViewCell> {
    private let spaceId: String
    public var selfPersonId: String?
    
    init(spaceId: String) {
        self.spaceId = spaceId
        super.init(placeholderText: "No Messages in Space")
        tableView.accessibilityIdentifier = "SpaceMessagesTableView"
        title = "Messages"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "slider-horizontal-3"), style: .plain, target: self, action: #selector(showFilterMessagesByMention))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        webex.messages.onEvent = { messageEvent in
            switch messageEvent {
            case .messageDeleted(let messageId):
                print("\(messageId) was deleted")
                self.refreshList()
            case .messageReceived(let message):
                print("Received message with id: \(message.id ?? "")")
                self.refreshList()
            case .messageUpdated(let messageId, let type):
                print("Message with id: \(messageId) had an update of type \(type)")
                self.refreshList()
            @unknown default:
                self.refreshList()
            }
        }
    }
    
    override func refreshList() {
        webex.messages.list(spaceId: spaceId, queue: DispatchQueue.global(qos: .default)) { [weak self] in
            self?.listItems = $0.data?.reversed() ?? []
        }
    }
}

extension SpaceMessagesTableViewController {
    // MARK: Private Methods
    private func markMessageAsRead(_ message: Message) {
        guard let spaceId = message.spaceId,
              let messageId = message.id else { return }
        
        webex.messages.markAsRead(spaceId: spaceId, messageId: messageId, queue: DispatchQueue.global(qos: .default)) { result in
            let message: String = {
                switch result {
                case .success:
                    return "Message marked read."
                case .failure:
                    return "Failed to mark message read."
                }
            }()
            let alert = UIAlertController(title: "Result", message: message, preferredStyle: .alert)
            alert.addAction(.dismissAction())
            DispatchQueue.main.async { [weak self] in
                self?.present(alert, animated: true)
            }
        }
    }
    
    private func getMessage(_ messageId: String) {
        webex.messages.get(messageId: messageId, queue: DispatchQueue.global(qos: .default)) { result in
            let messageBody: String = {
                switch result {
                case .success(let message):
                    return "Retrieved message with id: \(message.id ?? "--")"
                case .failure(let error):
                    return "Failed to get message with error: \(error)"
                }
            }()
            let alertController = UIAlertController(title: "Get Message", message: messageBody, preferredStyle: .alert)
            alertController.addAction(.dismissAction())
            DispatchQueue.main.async { [weak self] in
                self?.present(alertController, animated: true)
            }
        }
    }
    
    private func showDeleteMessageConfirmationAlert(messageId: String) {
        let alertController = UIAlertController(title: "Please Confirm", message: "This action will delete the Message", preferredStyle: .alert)
        alertController.addAction(UIAlertAction.dismissAction())
        alertController.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            alertController.dismiss(animated: true) {
                webex.messages.delete(messageId: messageId, queue: DispatchQueue.global(qos: .default)) { [weak self] result in
                    self?.refreshList()
                    let (title, message) = { () -> (String, String) in
                        switch result {
                        case .success:
                            return ("Success", "Message has been deleted")
                        case .failure(let error):
                            return ("Failure", "Message deletion failure \n \(error)")
                        }
                    }()
                    let successController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    successController.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
                    DispatchQueue.main.async {
                        self?.present(successController, animated: true)
                    }
                }
            }
        })
        
        present(alertController, animated: true)
    }
    
    @objc private func showFilterMessagesByMention() {
        let actionSheet = UIAlertController(title: "Filter by Mention", message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(.dismissAction())
        
        actionSheet.addAction(UIAlertAction(title: "All", style: .default) { [weak self] _ in
            webex.messages.list(spaceId: self?.spaceId ?? "", mentionedPeople: [], queue: .global(qos: .background)) { result in
                self?.listItems = result.data ?? []
            }
        })
        
        actionSheet.addAction(UIAlertAction(title: "Person", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let vc = SpaceMembershipViewController(spaceId: self.spaceId)
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        })
        
        present(actionSheet, animated: true)
    }
    
    private func downloadFile(_ message: Message, contentIndex: Int) {
        guard let remoteFile = message.files?[contentIndex] else { return }
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        var docString = documentDirectory?.absoluteString ?? ""
        docString = docString.replacingOccurrences(of: "file://", with: "")
        let actionSheet = UIAlertController(title: "Download Progress", message: "", preferredStyle: .actionSheet)
        present(actionSheet, animated: true, completion: nil)
        webex.messages.downloadFile(remoteFile, to: URL(string: docString), progressHandler: { progress in
            DispatchQueue.main.async {
                if let fileSize = remoteFile.size {
                    actionSheet.message = "\(progress)B / \(fileSize)B"
                } else {
                    actionSheet.message = "\(progress)B"
                }
            }
        }, completionHandler: { [weak self] fileUrl in
            switch fileUrl {
            case .failure(let error):
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Error downloading file", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(.dismissAction(withTitle: "Ok"))
                    self?.present(alert, animated: true)
                }
            case .success(let fileUrl):
                guard let fileUrl = fileUrl else { return }
                DispatchQueue.main.async {
                    self?.dismiss(animated: true, completion: {
                        self?.navigationController?.pushViewController(AttachmentPreviewViewController(previewUrl: fileUrl), animated: true)
                    })
                }
            }
        })
    }
    
    private func downloadThumbnail(_ message: Message, contentIndex: Int) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let thumbnailDirectory = documentDirectory?.appendingPathComponent("Thumbnails") else { return }
        do {
            try FileManager.default.createDirectory(atPath: thumbnailDirectory.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
        guard let remoteFile = message.files?[contentIndex] else { return }
        
        webex.messages.downloadThumbnail(for: remoteFile, to: thumbnailDirectory, completionHandler: { result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Error downloading thumbnail", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(.dismissAction(withTitle: "Ok"))
                    self.present(alert, animated: true)
                }
            case .success(let result):
                guard let result = result else { return }
                let resultString = result.absoluteString
                let imageUrl = resultString.replacingOccurrences(of: "file://", with: "")
                let image = UIImage(contentsOfFile: imageUrl) ?? UIImage()
                DispatchQueue.main.async {
                    let showAlert = UIAlertController(title: "Thumbnail", message: nil, preferredStyle: .alert)
                    let imageView = UIImageView(frame: CGRect(x: 10, y: 50, width: 250, height: 250))
                    imageView.image = image
                    imageView.contentMode = .scaleAspectFit
                    guard let showAlertView = showAlert.view else { return }
                    showAlertView.addSubview(imageView)
                    let height = NSLayoutConstraint(item: showAlertView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 350)
                    let width = NSLayoutConstraint(item: showAlertView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 260)
                    showAlert.view.addConstraint(height)
                    showAlert.view.addConstraint(width)
                    showAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    }))
                    self.present(showAlert, animated: true, completion: nil)
                }
            }
        })
    }
}

extension SpaceMessagesTableViewController {
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let alertController = UIAlertController(title: "Message Actions", message: nil, preferredStyle: .actionSheet)
        let message = listItems[indexPath.row]
        if let messageId = message.id {
            alertController.addAction(UIAlertAction(title: "Fetch Message by Id", style: .default) { [weak self] _ in
                self?.getMessage(messageId)
            })
            
            // Only authors of the message can edit a message
            if let selfPersonId = selfPersonId, let spaceId = message.spaceId, message.personId == selfPersonId {
                alertController.addAction(UIAlertAction(title: "Edit Message", style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    let editMessageVC = MessageComposerViewController(id: spaceId, type: SendMessageType.spaceId)
                    editMessageVC.isMessageBeingEdited = true
                    editMessageVC.parentMessage = message
                    self.navigationController?.pushViewController(editMessageVC, animated: true)
                })
            }
            
            // Only authors of the message should be able to delete a message
            if let selfPersonId = selfPersonId, message.personId == selfPersonId, let messageId = message.id {
                alertController.addAction(UIAlertAction(title: "Delete Message", style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    self.showDeleteMessageConfirmationAlert(messageId: messageId)
                })
            }
            
            alertController.addAction(UIAlertAction(title: "Mark Message as read", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.markMessageAsRead(self.listItems[indexPath.row])
            })
            
            alertController.addAction(UIAlertAction(title: "Fetch Messages Before This MessageId", style: .default) { [weak self] _ in
                guard let self = self else { return }
                webex.messages.list(spaceId: self.spaceId, before: .message(messageId), queue: DispatchQueue.global(qos: .default)) { [weak self] in
                    self?.listItems = $0.data ?? []
                }
            })
            
            if let files = message.files {
                for (contentIndex, file) in files.enumerated() {
                    if let fileName = file.displayName { alertController.addAction(UIAlertAction(title: "Download Thumbnail \(fileName)", style: .default) { [weak self] _ in
                        guard let self = self else { return }
                        self.downloadThumbnail(self.listItems[indexPath.row], contentIndex: contentIndex)
                    })}
                }
            }
        }
        
        if let createdDate = message.created {
            alertController.addAction(UIAlertAction(title: "Fetch Messages Before This Date", style: .default) { [weak self] _ in
                guard let self = self else { return }
                webex.messages.list(spaceId: self.spaceId, before: .date(createdDate), queue: DispatchQueue.global(qos: .default)) { [weak self] in
                    self?.listItems = $0.data ?? []
                }
            })
        }
        
        alertController.addAction(.dismissAction())
        present(alertController, animated: true)
    }
}

extension SpaceMessagesTableViewController {
    // MARK: UITableViewDatasource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MessageTableViewCell.reuseIdentifier, for: indexPath) as? MessageTableViewCell else {
            return UITableViewCell()
        }
        let message = listItems[indexPath.row]
        
        var fileTitles: [String] = []
        if let fileArr = message.files {
            fileTitles = fileArr.map { $0.displayName ?? "" }
        }
        
        cell.update(senderName: message.personId, sendDate: message.created?.description, messagebody: message.text?.htmlToAttributedString, filesName: fileTitles, isReply: message.isReply, buttonActionHandler: { index in self.downloadFile(message, contentIndex: index) })
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let message = listItems[indexPath.row]

            if self.selfPersonId != message.personId {
                let alert = UIAlertController(title: "Error", message: "Cannot delete messages that aren't sent by you", preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Ok"))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            if let messageId = message.id {
                showDeleteMessageConfirmationAlert(messageId: messageId)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.rowHeight
    }
}

extension SpaceMessagesTableViewController: SpaceMembershipViewControllerDelegate {
    // MARK: SpaceMembershipViewControllerDelegate
    func spaceMembershipViewControllerDidSelectMembership(membership: Membership) {
        navigationController?.popViewController(animated: true)
        webex.messages.list(spaceId: spaceId, mentionedPeople: [], queue: .global(qos: .default)) { [weak self] result in
            self?.listItems = result.data ?? []
        }
    }
}
