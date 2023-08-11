import UIKit
import WebexSDK

class DialCallViewController: UIViewController, DialPadViewDelegate, UITextFieldDelegate {
    var addedCall: Bool
    var oldCallId: String?
    var call: Call?
    var isPhoneNumber = false
    private var callButtonDialpadBottomConstraint: NSLayoutConstraint?
    private var callButtonTextFieldBottomConstraint: NSLayoutConstraint?
    
    init(addedCall: Bool = false, oldCallId: String = "", call: Call? = nil) {
        self.addedCall = addedCall
        self.oldCallId = oldCallId
        self.call = call
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        setupViews()
        setupConstraints()
    }
    
    // MARK: Views
    private lazy var keyboardToggleButton: UIButton = {
        let button = UIButton(frame: .zero)
        if #available(iOS 12.0, *) {
            switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                button.setImage(UIImage(named: "keyboard"), for: .normal)
                button.setImage(UIImage(named: "dialpad"), for: .selected)
            case .dark:
                button.setImage(UIImage(named: "keyboard-white"), for: .normal)
                button.setImage(UIImage(named: "dialpad-white"), for: .selected)
            @unknown default:
                fatalError()
            }
        } else {
            button.setImage(UIImage(named: "keyboard"), for: .normal)
            button.setImage(UIImage(named: "dialpad"), for: .selected)
        }

        button.setSize(width: 44, height: 44)
        button.addTarget(self, action: #selector(self.handleDialpadToggleAction(_:)), for: .touchUpInside)
        button.accessibilityIdentifier = "keyboardToggleButton"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var dialPad: DialPadView = {
        let dialPadView = DialPadView(frame: .zero)
        dialPadView.delegate = self
        dialPadView.translatesAutoresizingMaskIntoConstraints = false
        return dialPadView
    }()
    
    private lazy var textField: UITextField = {
        let textField = UITextField(frame: .zero)
        textField.keyboardType = .emailAddress
        textField.tintColor = .momentumBlue50
        textField.textAlignment = .center
        textField.font = .preferredFont(forTextStyle: .title1)
        textField.clearButtonMode = .always
        textField.delegate = self
        textField.placeholder = "Tap to dial"
        textField.accessibilityIdentifier = "callInput"
        textField.text = ""
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var dialPhoneNumberSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = false
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(dialPhoneNumberValueDidChanged(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private lazy var dialPhoneNumberLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title1)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = "Dial Phone number ?"
        label.accessibilityIdentifier = "dialPhoneNumberLabel"
        return label
    }()
    
    private lazy var callButton: CallButton = {
        let button = CallButton(style: .cta, size: .medium, type: .connectCall)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(self.handleCallAction(_:)), for: .touchUpInside)
        button.accessibilityIdentifier = "dialButton"
        return button
    }()
    
    @objc func dialPhoneNumberValueDidChanged(_ sender: UISwitch) {
        self.isPhoneNumber = sender.isOn
    }
    
    // MARK: DialPad Delegates
    func dialPadView(_ dialPadView: DialPadView, didSelect key: String) {
        let currentText = textField.text ?? ""
        textField.text = currentText + key
    }
    
    // MARK: TextField Delegates
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return keyboardToggleButton.isSelected
    }
    
    // MARK: Private Methods
    private func manageKeyboardModeSwitch(isKeyboardMode: Bool) {
        _ = isKeyboardMode ? textField.becomeFirstResponder() : textField.resignFirstResponder()
        dialPad.isHidden = isKeyboardMode
        let constraintToDeactivate = isKeyboardMode ? callButtonDialpadBottomConstraint : callButtonTextFieldBottomConstraint
        let constraintToActivate = isKeyboardMode ? callButtonTextFieldBottomConstraint : callButtonDialpadBottomConstraint
        constraintToDeactivate?.deactivate()
        constraintToActivate?.activate()
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: { self.view.layoutIfNeeded() })
    }
    
    // MARK: Actions
    @objc func handleDialpadToggleAction(_ button: UIButton) {
        button.isSelected.toggle()
        manageKeyboardModeSwitch(isKeyboardMode: button.isSelected)
    }
    
    private func setupViews() {
        view.addSubview(textField)
        view.addSubview(keyboardToggleButton)
        view.addSubview(dialPad)
        view.addSubview(callButton)
        view.addSubview(dialPhoneNumberSwitch)
        view.addSubview(dialPhoneNumberLabel)
    }
    
    private func setupConstraints() {
        dialPhoneNumberLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 24).activate()
        dialPhoneNumberLabel.bottomAnchor.constraint(equalTo: textField.topAnchor, constant: -8).activate()

        dialPhoneNumberSwitch.leadingAnchor.constraint(equalTo: dialPhoneNumberLabel.trailingAnchor, constant: 16).activate()
        dialPhoneNumberSwitch.bottomAnchor.constraint(equalTo: textField.topAnchor, constant: -8).activate()
        
        textField.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 24).activate()
        textField.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor, constant: -64).activate()
        textField.bottomAnchor.constraint(equalTo: dialPad.topAnchor, constant: -68).activate()
        
        keyboardToggleButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor).activate()
        keyboardToggleButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 12).activate()
        
        dialPad.widthAnchor.constraint(equalTo: view.readableContentGuide.widthAnchor, multiplier: 0.74).activate()
        dialPad.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        dialPad.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -140).activate()
        
        callButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).activate()
        callButton.widthAnchor.constraint(equalTo: dialPad.widthAnchor, multiplier: 0.28).activate()
        callButton.heightAnchor.constraint(equalTo: callButton.widthAnchor).activate()
        
        callButtonDialpadBottomConstraint = callButton.topAnchor.constraint(equalTo: dialPad.bottomAnchor, constant: 30)
        callButtonTextFieldBottomConstraint = callButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 60)
        
        callButtonDialpadBottomConstraint?.activate()
    }
    
    // MARK: Actions
    @objc private func handleCallAction(_ sender: UIButton) {
        let space = Space(id: textField.text ?? "", title: textField.text ?? "")
        if addedCall {
            guard let oldCallId = oldCallId else { return }
            guard let call = call else {
                let alert = UIAlertController(title: "Error", message: "Call not found", preferredStyle: .alert)
                alert.addAction(.dismissAction(withTitle: "Ok"))
                self.present(alert, animated: true)
                return
            }
            call.startAssociatedCall(dialNumber: space.id ?? "", associationType: .Transfer, isAudioCall: true, completionHandler: { [weak self] result in
                switch result {
                case .success(let call):
                    guard let call = call else {
                        let alert = UIAlertController(title: "Error", message: "Call is empty", preferredStyle: .alert)
                        alert.addAction(.dismissAction(withTitle: "Ok"))
                        self?.present(alert, animated: true)
                        return
                    }
                    CallObjectStorage.self.shared.addCallObject(call: call)
                    
                    // CallViewController is already open
                    DispatchQueue.main.async {
                        if let callVC = self?.presentingViewController as? CallViewController {
                            print("Associated calll old: \(oldCallId), new: \(String(describing: call.callId))")
                            callVC.currentCallId = call.callId
                            callVC.addedCall = true
                            callVC.oldCallId = oldCallId
                            callVC.call = call
                            callVC.viewDidLoad()
                            self?.dismiss(animated: true)
                        }
                    }
                case .failure(let error):
                    let alert = UIAlertController(title: "Error", message: "\(error)", preferredStyle: .alert)
                    alert.addAction(.dismissAction(withTitle: "Ok"))
                    self?.present(alert, animated: true)
                }
            })
        } else {
            present(CallViewController(space: space, addedCall: addedCall, isPhoneNumber: isPhoneNumber), animated: true)
        }
    }
}

extension DialCallViewController: NavigationItemSetupProtocol {
    var rightBarButtonItems: [UIBarButtonItem]? {
        return nil
    }
}
