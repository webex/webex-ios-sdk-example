import UIKit
import WebexSDK

class SetupViewController: UIViewController, UITextFieldDelegate {
    // MARK: Properties
    private let kCellId = "VirtualBackgroundCell"
    private var backgroundItems: [Phone.VirtualBackground] = []
    private var isPreviewing = true
    private var isBackgroundConnectionEnabled = UserDefaults.standard.bool(forKey: "backgroundConnection")
    private var isFrontCamera = true
    private lazy var selectedLoggingMode = webex.logLevel
    private var isComposite = UserDefaults.standard.bool(forKey: "compositeMode")
    private var imagePicker = UIImagePickerController()
    private var isNewMultiStreamApproach = UserDefaults.standard.bool(forKey: "isMultiStreamEnabled")
    private var isVideoRes1080p = UserDefaults.standard.bool(forKey: "VideoRes1080p")

    // MARK: Views and Constraints
    private lazy var virtualBgcollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 50, height: 50)
        layout.minimumLineSpacing = 20
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.setHeight(80)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray
        view.dataSource = self
        view.delegate = self
        view.register(VirtualBackgroundViewCell.self, forCellWithReuseIdentifier: kCellId)
        view.isScrollEnabled = true
        view.isHidden = true
        return view
    }()
    
    private var videoView: MediaRenderView = {
        let view = MediaRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Preview
    private lazy var previewSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = isPreviewing
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(previewSwitchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let previewLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "previewLabel"
        label.text = "Camera"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    private lazy var previewStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [previewLabel, previewSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()
    
    @objc func previewSwitchValueDidChange(_ sender: UISwitch) {
        DispatchQueue.main.async {
            if sender.isOn == true {
                webex.phone.startPreview(view: self.videoView)
            } else {
                webex.phone.stopPreview()
            }
        }
    }
    
    // EnableBackgroundConnection
    private lazy var enableBackgroundConnectionSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = isBackgroundConnectionEnabled
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(enableBackgroundConnectionSwitchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let enableBackgroundConnectionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "bgConnectionLabel"
        label.text = "Background Connection"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    private lazy var enableBackgroundConnectionStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [enableBackgroundConnectionLabel, enableBackgroundConnectionSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()
    
    @objc func enableBackgroundConnectionSwitchValueDidChange(_ sender: UISwitch) {
        DispatchQueue.main.async {
            if sender.isOn == true {
                UserDefaults.standard.setValue(true, forKey: "backgroundConnection")
                webex.phone.enableBackgroundConnection = true
            } else {
                UserDefaults.standard.setValue(false, forKey: "backgroundConnection")
                webex.phone.enableBackgroundConnection = false
            }
        }
    }
    
    // Set log mode
    private let loggingModeTF: UITextField = {
        let tf = UITextField()
        tf.accessibilityIdentifier = "LoggingModeTextField"
        tf.placeholder = "Logging mode"
        tf.borderStyle = .roundedRect
        tf.tintColor = .clear
        tf.text = "\(webex.logLevel)"
        return tf
    }()
    
    private let loggingModeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "LoggingModeLabel"
        label.text = "Logging Mode"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()

    private lazy var loggingModeStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [loggingModeLabel, loggingModeTF])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()

    private let loggingModePickerView = UIPickerView()
    private let loggingModes = [LogLevel.all, LogLevel.debug, LogLevel.error, LogLevel.info, LogLevel.no, LogLevel.verbose, LogLevel.warning]
    
    // Switch Camera
    private lazy var flipCameraSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = isFrontCamera
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(flipCameraSwitchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let flipCameraLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "switchCameraLabel"
        label.text = "Front Camera"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    private lazy var flipCameraStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [flipCameraLabel, flipCameraSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()
    
    @objc func flipCameraSwitchValueDidChange(_ sender: UISwitch) {
        DispatchQueue.main.async {
            if sender.isOn == true {
                webex.phone.defaultFacingMode = .user
                self.flipCameraLabel.text = "Front Camera"
            } else {
                webex.phone.defaultFacingMode = .environment
                self.flipCameraLabel.text = "Back Camera"
            }
        }
    }
    
    // MultiStream Aproach
    private lazy var multiStreamSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = isNewMultiStreamApproach
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(multiStreamSwitchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let multiStreamApproachLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "multiStreamStreamModeLabel"
        label.text = "Old Multi stream Approach"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    private lazy var multiStreamApproachStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [multiStreamApproachLabel, multiStreamSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()
    
    @objc func multiStreamSwitchValueDidChange(_ sender: UISwitch) {
        DispatchQueue.main.async {
            if sender.isOn == true {
                UserDefaults.standard.setValue(true, forKey: "isMultiStreamEnabled")
                self.multiStreamApproachLabel.text = "New Multi stream Approach"
            } else {
                UserDefaults.standard.setValue(false, forKey: "isMultiStreamEnabled")
                self.multiStreamApproachLabel.text = "Old Multi stream Approach"
            }
        }
    }
    
    // 1080p Video
    private lazy var videoResSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = isVideoRes1080p
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(videoResSwitchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let videoResLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "VideoRes"
        label.text = "Enable 1080p Video"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    private lazy var videoResStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [videoResLabel, videoResSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()
    
    @objc func videoResSwitchValueDidChange(_ sender: UISwitch) {
        DispatchQueue.main.async {
            if sender.isOn == true {
                UserDefaults.standard.setValue(true, forKey: "VideoRes1080p")
            } else {
                UserDefaults.standard.setValue(false, forKey: "VideoRes1080p")
            }
        }
    }
    // Video Stream Mode
    private lazy var videoStreamModeSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = isComposite
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(videoStreamModeSwitchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let videoStreamModeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "videoStreamModeLabel"
        label.text = "Composite Mode"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
        
    private lazy var videoStreamModeStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [videoStreamModeLabel, videoStreamModeSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()
    
    @objc func videoStreamModeSwitchValueDidChange(_ sender: UISwitch) {
        DispatchQueue.main.async {
            if sender.isOn == true {
                UserDefaults.standard.setValue(true, forKey: "compositeMode")
                webex.phone.videoStreamMode = .composited
                self.videoStreamModeLabel.text = "Composite Mode"
            } else {
                UserDefaults.standard.setValue(false, forKey: "compositeMode")
                webex.phone.videoStreamMode = .auxiliary
                self.videoStreamModeLabel.text = "Auxiliary Mode"
            }
        }
    }
    
    // Call Mode
    private lazy var callModeSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = UserDefaults.standard.bool(forKey: "hasVideo")
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(callModeSwitchValueDidChange(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let callModeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "callModeLabel"
        label.text = "Start call with video"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    private lazy var callModeStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [callModeLabel, callModeSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()
    
    @objc func callModeSwitchValueDidChange(_ sender: UISwitch) {
        if sender.isOn == true {
            UserDefaults.standard.set(true, forKey: "hasVideo")
        } else {
            UserDefaults.standard.set(false, forKey: "hasVideo")
        }
    }
    
    // Heading
    private let virtualBackgroundLimitLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "virtualBackgroundLimitLabel"
        label.text = "Virtual Background Limit: "
        label.font.withSize(35)
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .black
        return label
    }()
    
    private let virtualBackgroundLimitField: UITextField = {
        let field = UITextField(frame: .zero)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.accessibilityIdentifier = "virtualBackgroundLimitField"
        field.keyboardType = .numberPad
        field.borderStyle = .roundedRect
        return field
    }()
    
    private lazy var virtualBackgroundLimitStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [virtualBackgroundLimitLabel, virtualBackgroundLimitField])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fill
        return stack
    }()
    
    private lazy var virtualBackgroundButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "virtual-bg"), style: .done, target: self, action: #selector(virtualBgAction(_:)))
        button.tag = 0
        return button
    }()
    
    // MARK: Lifecycle Methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        virtualBackgroundLimitField.delegate = self
        updateVirtualBackgrounds()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let index = loggingModes.index(of: selectedLoggingMode) {
            loggingModePickerView.selectRow(index, inComponent: 0, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.view.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false
        self.navigationItem.setRightBarButton(virtualBackgroundButton, animated: true)
        imagePicker.delegate = self
        setupViews()
        setupConstraints()
        webex.phone.startPreview(view: videoView)
        videoStreamModeLabel.text = isComposite ? "Composite Mode" : "Auxiliary Mode"
        multiStreamApproachLabel.text = isNewMultiStreamApproach ? "New Multi stream Approach" : "Old Multi stream Approach"
    }
    
    func setupViews() {
        view.addSubview(videoView)
        view.addSubview(previewStackView)
        view.addSubview(enableBackgroundConnectionStackView)
        view.addSubview(loggingModeStackView)
        view.addSubview(flipCameraStackView)
        view.addSubview(videoStreamModeStackView)
        view.addSubview(multiStreamApproachStackView)
        view.addSubview(videoResStackView)
        view.addSubview(callModeStackView)
        view.addSubview(virtualBgcollectionView)
        view.addSubview(virtualBackgroundLimitLabel)
        view.addSubview(virtualBackgroundLimitField)
        view.addSubview(virtualBackgroundLimitStackView)
        view.backgroundColor = .white
        
        loggingModePickerView.delegate = self
        loggingModePickerView.dataSource = self
        loggingModeTF.inputView = loggingModePickerView
        loggingModeTF.inputAccessoryView = pickerViewToolBar(inputView: loggingModeTF)
    }
    
    func setupConstraints() {
        enableBackgroundConnectionStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        enableBackgroundConnectionStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40).activate()
        enableBackgroundConnectionStackView.fillWidth(of: view, padded: 32)
        
        loggingModeStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        loggingModeStackView.topAnchor.constraint(equalTo: enableBackgroundConnectionStackView.topAnchor, constant: -40).activate()
        loggingModeStackView.fillWidth(of: view, padded: 32)
        
        callModeStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        callModeStackView.topAnchor.constraint(equalTo: loggingModeStackView.topAnchor, constant: -40).activate()
        callModeStackView.fillWidth(of: view, padded: 32)
        
        previewStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        previewStackView.topAnchor.constraint(equalTo: callModeStackView.topAnchor, constant: -40).activate()
        previewStackView.fillWidth(of: view, padded: 32)
        
        flipCameraStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        flipCameraStackView.topAnchor.constraint(equalTo: previewStackView.topAnchor, constant: -40).activate()
        flipCameraStackView.fillWidth(of: view, padded: 32)
        
        videoStreamModeStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        videoStreamModeStackView.topAnchor.constraint(equalTo: flipCameraStackView.topAnchor, constant: -40).activate()
        videoStreamModeStackView.fillWidth(of: view, padded: 32)
        
        multiStreamApproachStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        multiStreamApproachStackView.topAnchor.constraint(equalTo: videoStreamModeStackView.topAnchor, constant: -40).activate()
        multiStreamApproachStackView.fillWidth(of: view, padded: 32)
        
        videoResStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        videoResStackView.topAnchor.constraint(equalTo: multiStreamApproachStackView.topAnchor, constant: -40).activate()
        videoResStackView.fillWidth(of: view, padded: 32)
        
        virtualBackgroundLimitStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        virtualBackgroundLimitStackView.topAnchor.constraint(equalTo: videoResSwitch.topAnchor, constant: -40).activate()
        virtualBackgroundLimitStackView.fillWidth(of: view, padded: 32)
        
        videoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).activate()
        videoView.bottomAnchor.constraint(equalTo: virtualBackgroundLimitStackView.topAnchor, constant: -20).activate()
        videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor).activate()
        videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor).activate()
        
        virtualBgcollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).activate()
        virtualBgcollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).activate()
        virtualBgcollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).activate()
    }
    
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
    
    private func slideInStateView(slideInMsg: String) {
        let alert = UIAlertController(title: nil, message: slideInMsg, preferredStyle: .alert)
        self.present(alert, animated: true)
        let duration: Double = 2
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
            alert.dismiss(animated: true)
        }
    }
    
    @objc private func virtualBgAction(_ sender: UIButton) {
        if !isPreviewing && sender.tag == 0 {
            let alert = UIAlertController(title: "Camera is off", message: "Please enable camera for selecting virtual background", preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            self.present(alert, animated: true)
        } else if sender.tag == 0 {
            let item = self.navigationItem.rightBarButtonItem
            item?.image = UIImage(named: "attachment")
            item?.tag = 1
            virtualBgcollectionView.reloadData()
            virtualBgcollectionView.isHidden = false
        } else {
            if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
                imagePicker.sourceType = .photoLibrary
                imagePicker.allowsEditing = false
                present(imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    private func updateVirtualBackgrounds() {
        virtualBackgroundLimitField.text = String(webex.phone.virtualBackgroundLimit)
        webex.phone.fetchVirtualBackgrounds(completionHandler: { result in
            switch result {
            case .success(let backgrounds):
                self.backgroundItems = backgrounds
                self.virtualBgcollectionView.reloadData()
            case .failure(let error):
                print("Error: \(error)")
            @unknown default:
                print("Error")
            }
        })
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        webex.phone.virtualBackgroundLimit = Int(textField.text.valueOrEmpty) ?? 3
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        virtualBackgroundLimitField.resignFirstResponder()
    }
}

extension SetupViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return backgroundItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellId, for: indexPath) as? VirtualBackgroundViewCell else { return UICollectionViewCell() }
        cell.setupCell(with: backgroundItems[indexPath.item], buttonActionHandler: { [weak self] in self?.deleteItem(item: self?.backgroundItems[indexPath.item]) })
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            webex.phone.applyVirtualBackground(background: self.backgroundItems[indexPath.row], mode: .preview, completionHandler: { result in
                switch result {
                case .success(_):
                    DispatchQueue.main.async {
                        self.slideInStateView(slideInMsg: "Successfully updated background")
                        let item = self.navigationItem.rightBarButtonItem
                        item?.image = UIImage(named: "virtual-bg")
                        item?.tag = 0
                        self.virtualBgcollectionView.isHidden = true
                        self.updateVirtualBackgrounds()
                    }
                case .failure(let error):
                    self.slideInStateView(slideInMsg: "Failed updating background with error: \(error)")
                @unknown default:
                    self.slideInStateView(slideInMsg: "Failed updating background")
                }
            })
        }
    }
    
    func deleteItem(item: Phone.VirtualBackground?) {
        guard let item = item else {
            print("Virtual background item is nil")
            return
        }
        webex.phone.removeVirtualBackground(background: item, completionHandler: { result in
            switch result {
            case .success(_):
                self.slideInStateView(slideInMsg: "Successfully deleted background")
                self.updateVirtualBackgrounds()
            case .failure(let error):
                self.slideInStateView(slideInMsg: "Failed deleting background with error: \(error)")
            @unknown default:
                self.slideInStateView(slideInMsg: "Failed updating background")
            }
        })
    }
}

extension SetupViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
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
        
        let resizedthumbnail = image.resizedImage(for: CGSize(width: 64, height: 64))

        guard let imageData = image.pngData() else { return }
        let path = FileUtils.writeToFile(data: imageData, fileName: fileName)
        guard let imagePath = path?.absoluteString.replacingOccurrences(of: "file://", with: "") else { print("Failed to process image path"); return }

        guard let thumbnailData = resizedthumbnail?.pngData() else { return }
        let thumbnailFilePath = FileUtils.writeToFile(data: thumbnailData, fileName: "thumbnail\(fileName)")
        guard let thumbnailPath = thumbnailFilePath?.absoluteString.replacingOccurrences(of: "file://", with: "") else { print("Failed to process thumbnail path"); return }
        
        let thumbnail = LocalFile.Thumbnail(path: thumbnailPath, mime: fileType, width: 64, height: 64)
        guard let localFile = LocalFile(path: imagePath, name: fileName, mime: fileType, thumbnail: thumbnail) else { print("Failed to get local file"); return }
        
        webex.phone.addVirtualBackground(image: localFile, completionHandler: { result in
            picker.dismiss(animated: true, completion: nil)
            switch result {
            case .success(let newItem):
                print("new background item: \(newItem)")
                DispatchQueue.main.async {
                    self.slideInStateView(slideInMsg: "Successfully uploaded background")
                    self.updateVirtualBackgrounds()
                }
            case .failure(let error):
                self.slideInStateView(slideInMsg: "Failed uploading background with error: \(error)")
            @unknown default:
                self.slideInStateView(slideInMsg: "Failed uploading background")
            }
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension SetupViewController: UIPickerViewDataSource {
    // MARK: UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case loggingModePickerView:
            return loggingModes.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case loggingModePickerView:
            return "\(loggingModes[row])"
        default:
            return ""
        }
    }
}

extension SetupViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == loggingModePickerView {
            selectedLoggingMode = loggingModes[row]
            webex.logLevel = selectedLoggingMode
            loggingModeTF.text = "\(selectedLoggingMode)"
        }
    }
}
