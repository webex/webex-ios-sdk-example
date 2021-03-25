import UIKit
import WebexSDK

enum SendMessageType {
    case personId
    case personEmail
    case spaceId
}

struct PersonData {
    var personId: String
    var personName: String
}

class MessageComposerViewController: UIViewController {
    var imagePicker = UIImagePickerController()
    var id: String?
    var type: SendMessageType?
    var alertText = ""
    var localFiles: [LocalFile] = []
    var dropDown = MakeDropDown()
    var mentionList: [PersonData] = [PersonData(personId: "", personName: "All")]
    var mentions: [Mention] = []
    var hasMentions = false
    public var parentMessage: Message?
    public var isMessageBeingEdited = false
    
    init(id: String, type: SendMessageType) {
        self.id = id
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var isMarkdownEnabled = false
    
    private lazy var messageText: UITextField = {
        let textField = UITextField(frame: .zero)
        textField.tintColor = .momentumBlue50
        textField.font = .preferredFont(forTextStyle: .body)
        textField.placeholder = "Type your message"
        textField.accessibilityIdentifier = "messageInput"
        textField.text = isMessageBeingEdited ? parentMessage?.text : ""
        textField.textAlignment = .center
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .line
        textField.setHeight(50)
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return textField
    }()
    
    private lazy var markdownToggle: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = isMarkdownEnabled
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(switchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private lazy var plainTextImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "text")
        imageView.setWidth(30)
        imageView.setHeight(30)
        return imageView
    }()
    
    private lazy var markdownImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "markdown")
        imageView.setWidth(30)
        imageView.setHeight(30)
        return imageView
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [plainTextImage, markdownToggle, markdownImage])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 20
        stack.alignment = .fill
        return stack
    }()
    
    private lazy var previewImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setWidth(100)
        imageView.setHeight(100)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var sendButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(handleSendAction), for: .touchUpInside)
        view.setTitle(isMessageBeingEdited ? "Edit" : "Send Message", for: .normal)
        view.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .momentumBlue50
        view.setHeight(50)
        view.layer.cornerRadius = 25
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var attachmentButton: UIButton = {
        let view = UIButton(type: .system)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(handleAttachments), for: .touchUpInside)
        view.setImage(UIImage(named: "attachment"), for: .normal)
        view.setHeight(50)
        view.setWidth(50)
        view.layer.masksToBounds = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Message Composer"
        view.backgroundColor = .backgroundColor
        setupViews()
        setupConstraints()
        imagePicker.delegate = self
        if type == .spaceId {
            getListOfAllMentions()
        }
    }
    
    func setupViews() {
        view.addSubview(messageText)
        view.addSubview(stackView)
        
        if !isMessageBeingEdited {
            view.addSubview(previewImage)
            view.addSubview(attachmentButton)
        }
        
        view.addSubview(sendButton)
    }
    
    func setupConstraints() {
        sendButton.fillWidth(of: view, padded: 60)
        messageText.fillWidth(of: view, padded: 50)
        NSLayoutConstraint.activate([
            messageText.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: messageText.bottomAnchor, constant: 20)
        ])
        
        if !isMessageBeingEdited {
            NSLayoutConstraint.activate([
                attachmentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                attachmentButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 10),
                
                previewImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                previewImage.topAnchor.constraint(equalTo: attachmentButton.bottomAnchor, constant: 10),
                
                sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                sendButton.topAnchor.constraint(equalTo: previewImage.bottomAnchor, constant: 20)
            ])
        } else {
            NSLayoutConstraint.activate([
                sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                sendButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20)
            ])
        }
    }
    
    @objc func switchValueDidChange(_ sender: UISwitch) {
        isMarkdownEnabled = sender.isOn
    }
    
    @objc func handleSendAction(_ sender: UIButton) {
        guard let text = messageText.text, let spaceId = id else { return }
        let message: Message.Text = {
            if isMarkdownEnabled {
                return Message.Text.markdown(markdown: text, html: "<h2>text</h2> html version")
            } else {
                return Message.Text.plain(plain: text)
            }
        }()
        
        // Edit existing message
        if isMessageBeingEdited {
            guard let parentMessage = parentMessage else {
                let alertController = UIAlertController(title: "Error: no parent message to edit", message: "", preferredStyle: .alert)
                alertController.addAction(.dismissAction(withTitle: "Dismiss"))
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            webex.messages.edit(message, parent: parentMessage, mentions: mentions, queue: nil) { [weak self] in
                let alertController: UIAlertController
                switch $0 {
                case .success(let message):
                    alertController = UIAlertController(title: "Message edited", message: message.text, preferredStyle: .alert)
                case .failure(let error):
                    alertController = UIAlertController(title: "Message editing failed", message: error.localizedDescription, preferredStyle: .alert)
                @unknown default:
                    alertController = UIAlertController(title: "Message editing failed", message: "Unknown error", preferredStyle: .alert)
                }
                
                alertController.addAction(.dismissAction(withTitle: "Ok"))
                self?.localFiles = []
                DispatchQueue.main.async {
                    self?.present(alertController, animated: true)
                }
            }
            
            return
        }
        
        // Send new message
        if localFiles.isEmpty && text.isEmpty { return }
        if type == .spaceId {
            webex.messages.post(message, toSpace: spaceId, mentions: mentions, withFiles: localFiles, queue: nil) { [weak self] in
                let alertController: UIAlertController
                switch $0 {
                case .success(let message):
                    alertController = UIAlertController(title: "Message sent", message: message.text, preferredStyle: .alert)
                case .failure(let error):
                    alertController = UIAlertController(title: "Message sending failed", message: error.localizedDescription, preferredStyle: .alert)
                }
                alertController.addAction(.dismissAction(withTitle: "Ok"))
                self?.localFiles = []
                DispatchQueue.main.async {
                    self?.previewImage.isHidden = true
                    self?.messageText.text = ""
                    self?.mentions = []
                    self?.present(alertController, animated: true)
                }
            }
        } else if type == .personId {
            guard let personId = id else { return }
            webex.messages.post(message, toPerson: personId, withFiles: localFiles, queue: nil) { [weak self] in
                let alertController: UIAlertController
                switch $0 {
                case .success(let message):
                    alertController = UIAlertController(title: "Message sent", message: message.text, preferredStyle: .alert)
                case .failure(let error):
                    alertController = UIAlertController(title: "Message sending failed", message: error.localizedDescription, preferredStyle: .alert)
                }
                alertController.addAction(.dismissAction(withTitle: "Ok"))
                self?.localFiles = []
                DispatchQueue.main.async {
                    self?.previewImage.isHidden = true
                    self?.messageText.text = ""
                    self?.mentions = []
                    self?.present(alertController, animated: true)
                }
            }
        } else {
            guard let personId = id else { return }
            webex.people.get(personId: personId, queue: nil) { [weak self] result in
                if let person = result.data {
                    if let personEmail = person.emails?.first {
                        webex.messages.post(message, toPersonEmail: personEmail, withFiles: self?.localFiles, queue: nil) { [weak self] in
                            let alertController: UIAlertController
                            switch $0 {
                            case .success(let message):
                                alertController = UIAlertController(title: "Message sent", message: message.text, preferredStyle: .alert)
                            case .failure(let error):
                                alertController = UIAlertController(title: "Message sending failed", message: error.localizedDescription, preferredStyle: .alert)
                            }
                            alertController.addAction(.dismissAction(withTitle: "Ok"))
                            self?.localFiles = []
                            DispatchQueue.main.async {
                                self?.previewImage.isHidden = true
                                self?.messageText.text = ""
                                self?.mentions = []
                                self?.present(alertController, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func handleAttachments(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    private func writeToFile(data: Data, fileName: String) -> URL? {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let fileDirectory = documentDirectory?.appendingPathComponent("Files") else { return URL(string: "") }
        
        guard let path = URL(string: "\(fileDirectory)\(fileName)") else { return URL(string: "") }
        do {
            try FileManager.default.createDirectory(atPath: fileDirectory.path, withIntermediateDirectories: true, attributes: nil)
            try data.write(to: path)
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
        return path
    }
    
    func getListOfAllMentions() {
        guard let spaceId = id else { return }
        webex.spaces.get(spaceId: spaceId) {  [weak self] in
            switch $0 {
            case .success(let space):
                if space.type == .group {
                    // only group spaces support mentions
                    webex.memberships.list(spaceId: spaceId, completionHandler: { [weak self] in
                        switch $0 {
                        case .success(let memberships):
                            webex.people.getMe { [weak self] me in
                                for i in 0..<memberships.count {
                                    let person = PersonData(personId: (memberships[i].personId ?? ""), personName: memberships[i].personDisplayName ?? "")
                                    if person.personId != me.data?.id {
                                        // current user shouldn't be able to mention themselves
                                        self?.mentionList.append(person)
                                    }
                                }
                                self?.setUpDropDown()
                                self?.hasMentions = true
                            }
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                    })
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    @objc func textFieldDidChange(_ sender: UITextField) {
        if sender.text?.last == "@" && hasMentions {
            sender.text?.removeLast()
            dropDown.showDropDown(height: 150)
        }
    }
}

extension MessageComposerViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        var fileName = ""
        var fileType = ""
        
        if let url = info[UIImagePickerController.InfoKey.imageURL] as? URL {
            fileName = url.lastPathComponent
            fileType = url.pathExtension
        }
        previewImage.image = image
        previewImage.isHidden = false
        guard let data = image.pngData() else { return }
        let path = writeToFile(data: data, fileName: fileName)
        
        guard let filePath = path?.absoluteString.replacingOccurrences(of: "file://", with: "") else { return }
        
        let thumbnail = LocalFile.Thumbnail(path: filePath, mime: fileType, width: Int(image.size.width), height: Int(image.size.height))
        
        guard let localFile = LocalFile(path: filePath, name: fileName, mime: fileType, thumbnail: thumbnail) else { return }
        localFiles = []
        localFiles.append(localFile)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension MessageComposerViewController: MakeDropDownDataSourceProtocol {
    func getDataToDropDown(cell: UITableViewCell, indexPos: Int, makeDropDownIdentifier: String) {
        cell.textLabel?.text = mentionList[indexPos].personName
    }
    
    func numberOfRows(makeDropDownIdentifier: String) -> Int {
        mentionList.count
    }
    
    func selectItemInDropDown(indexPos: Int, makeDropDownIdentifier: String) {
        let startPos = self.messageText.text?.count ?? 0
        let endPos = startPos + self.mentionList[indexPos].personName.count
        let mention: Mention = indexPos == 0 ? .all(MentionPos(id: "", start: startPos, end: startPos + 3)) : .person(MentionPos(id: self.mentionList[indexPos].personId, start: startPos, end: endPos))
        mentions.append(mention)
        self.messageText.text?.append(self.mentionList[indexPos].personName)
        self.dropDown.hideDropDown()
    }
    
    func setUpDropDown() {
        dropDown.makeDropDownIdentifier = "MENTIONS"
        dropDown.cellReusableIdentifier = "mentionCell"
        dropDown.makeDropDownDataSourceProtocol = self
        dropDown.setUpDropDown(viewPositionReference: (messageText.frame), offset: 2)
        dropDown.setRowHeight(height: 30)
        dropDown.width = self.messageText.frame.width
        self.view.addSubview(dropDown)
    }
}
