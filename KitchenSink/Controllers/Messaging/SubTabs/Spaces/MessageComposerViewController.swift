import UIKit
import WebexSDK
import AVKit
enum SendMessageType {
    case personId
    case personEmail
    case spaceId
}

struct PersonData {
    var personId: String
    var personName: String
}

enum MessageType:String {
    case plain, html, markdown
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
    private let attachmentCell = "attachmentCell"
    private var msgType = MessageType.plain

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
        textField.returnKeyType = .done
        return textField
    }()
    
    private let messageTypePicker = UIPickerView()
    private let messageType = [MessageType.plain, MessageType.html, MessageType.markdown]

    
    private lazy var messageTypeText: UITextField = {
        let tf = UITextField()
        tf.accessibilityIdentifier = "messageTypeValue"
        tf.placeholder = "Type"
        tf.borderStyle = .roundedRect
        tf.tintColor = .clear
        tf.text = "\(msgType.rawValue)"
        return tf
    }()
    
    private let messageTypeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "messageTypeLabel"
        label.text = "Message Type"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [messageTypeLabel, messageTypeText])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
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
    
    private lazy var attachmentCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 120, height: 125)
        layout.minimumLineSpacing = 20
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.setHeight(125)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.dataSource = self
        view.register(UICollectionViewCell.self, forCellWithReuseIdentifier: attachmentCell)
        view.isScrollEnabled = true
        view.isHidden = true
        return view
    }()
    
    private func pickerViewToolBar(inputView: UITextField) -> UIToolbar {
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()

        let closeButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: inputView, action: #selector(inputView.resignFirstResponder))

        toolBar.setItems([closeButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        return toolBar
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Message Composer"
        view.backgroundColor = .backgroundColor
        setupViews()
        setupConstraints()
        imagePicker.delegate = self
        messageText.delegate = self
        if type == .spaceId {
            getListOfAllMentions()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let index = messageType.firstIndex(of: msgType) {
            messageTypePicker.selectRow(index, inComponent: 0, animated: true)
        }
    }
    
    func setupViews() {
        view.addSubview(messageText)
        view.addSubview(stackView)
        
        if !isMessageBeingEdited {
            view.addSubview(attachmentCollectionView)
            view.addSubview(attachmentButton)
        }
        
        view.addSubview(sendButton)
        
        messageTypePicker.delegate = self
        messageTypePicker.dataSource = self
        messageTypeText.inputView = messageTypePicker
        messageTypeText.inputAccessoryView = pickerViewToolBar(inputView: messageTypeText)
    }
    
    func setupConstraints() {
        attachmentCollectionView.fillWidth(of: view, padded: 20)
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
                
                attachmentCollectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                attachmentCollectionView.topAnchor.constraint(equalTo: attachmentButton.bottomAnchor, constant: 10),
                
                sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                sendButton.topAnchor.constraint(equalTo: attachmentCollectionView.bottomAnchor, constant: 20)
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
            switch(msgType){
            case MessageType.html:
                return Message.Text.html(html: text)
            case MessageType.markdown:
                return Message.Text.markdown(markdown: text)
            default:
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
                    self?.attachmentCollectionView.isHidden = true
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
                    self?.attachmentCollectionView.isHidden = true
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
                                self?.attachmentCollectionView.isHidden = true
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
            imagePicker.mediaTypes = ["public.movie", "public.image"]
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
func thumbnailForVideo(url: URL) -> UIImage? {
    let asset = AVAsset(url: url)
    let assetImageGenerator = AVAssetImageGenerator(asset: asset)
    assetImageGenerator.appliesPreferredTrackTransform = true

    var time = asset.duration
    time.value = min(time.value, 2)

    do {
        let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
        return UIImage(cgImage: imageRef)
    } catch {
        print("failed to create thumbnail")
        return nil
    }
}

extension MessageComposerViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        var thumbnailImage: UIImage?
        var fileURL: URL?
        if info[.mediaType] as? String ?? "" == "public.movie" {
            if let url = info[.mediaURL] as? URL {
                fileURL = url
                thumbnailImage = thumbnailForVideo(url: url)
            }
        } else {
            thumbnailImage = info[.originalImage] as? UIImage
            if let url = info[UIImagePickerController.InfoKey.imageURL] as? URL {
                fileURL = url
            }
        }
       
        guard let image = thumbnailImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
            
        attachmentCollectionView.isHidden = false
        
        guard let url = fileURL else {
            return
        }
        
        let fileName = url.lastPathComponent
        let fileType = url.pathExtension
        
        do {
            let data = try Data(contentsOf: url)
            let path = writeToFile(data: data, fileName: fileName)
            guard let filePath = path?.absoluteString.replacingOccurrences(of: "file://", with: "") else { return }
            
            guard let thumbnailData = image.pngData() else { return }
            let thumbnailPath = writeToFile(data: thumbnailData, fileName: "thumnail"+fileName)
            
            guard let thumbnailFilePath = thumbnailPath?.absoluteString.replacingOccurrences(of: "file://", with: "") else { return }
            
            let thumbnail = LocalFile.Thumbnail(path: thumbnailFilePath, mime: fileType, width: Int(image.size.width), height: Int(image.size.height))
            
            let duplicate = localFiles.contains { // checking if already attached
                let url1 = URL(fileURLWithPath: $0.path)
                let url2 = URL(fileURLWithPath: filePath)
                
                if let data1 = try? Data(contentsOf: url1), let data2 = try? Data(contentsOf: url2) {
                    return data1 == data2
                } else {
                    return false
                }
            }
            
            picker.dismiss(animated: true, completion: nil)
            
            if duplicate { // if already attached returning
                return
            }
            
            guard let localFile = LocalFile(path: filePath, name: fileName, mime: fileType, thumbnail: thumbnail) else { return }
            
            localFiles.append(localFile)
            reloadattachmentCollectionView()
        }
        catch let error {
            print(error.localizedDescription)
            return
        }
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

extension MessageComposerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return localFiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: attachmentCell, for: indexPath)
        let imageview = UIImageView(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
        imageview.contentMode = .scaleToFill
        let img = UIImage(contentsOfFile: localFiles[indexPath.row].thumbnail?.path ?? localFiles[indexPath.row].path)
        imageview.image = img
        cell.contentView.addSubview(imageview)
        let deleteButton = UIButton(type: .system)
        deleteButton.frame = CGRect(x: 100, y: 0, width: 20, height: 20)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setBackgroundImage(UIImage(named: "delete"), for: .normal)
        deleteButton.backgroundColor = .momentumRed50
        deleteButton.layer.cornerRadius = 10
        deleteButton.addTarget(self, action: #selector(deleteAttachment(_:)), for: .touchUpInside)
        deleteButton.tag = indexPath.row
        cell.contentView.addSubview(deleteButton)
        return cell
    }
    
    @objc func deleteAttachment(_ sender: UIButton) {
        localFiles.remove(at: sender.tag)
        reloadattachmentCollectionView()
    }
    
    func reloadattachmentCollectionView() {
        DispatchQueue.main.async { [weak self] in
            self?.attachmentCollectionView.reloadData()
        }
    }
}

extension MessageComposerViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case messageTypePicker:
            return messageType.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case messageTypePicker:
            return "\(messageType[row].rawValue)"
        default:
            return ""
        }
    }
}

extension MessageComposerViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == messageTypePicker {
            msgType = messageType[row]
            messageTypeText.text = "\(msgType.rawValue)"
        }
    }
}

extension MessageComposerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
