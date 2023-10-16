import UIKit
import WebexSDK

protocol ClosedCaptionsMenuViewDelegate: AnyObject
{
    func setSpokenLanguage(languageItem: LanguageItem)
    func setTranslationLanguage(languageItem: LanguageItem)
    func closedCaptionToggled(isOn: Bool)
}

class ClosedCaptionsMenuView: UIView {
    // MARK: - Properties
    var info: ClosedCaptionsInfo
    weak var delegate: ClosedCaptionsMenuViewDelegate?
    var isSpokenController = false
    var call: Call
    private lazy var closedCaptionToggleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enable: "
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.accessibilityIdentifier = "closedCaptionToggleLabel"
        return label
    }()
    
    private lazy var closedCaptionToggleSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.addTarget(self, action: #selector(closedCaptionToggleValueDidChanged(_:)), for: .valueChanged)
        switchControl.isOn = call.isClosedCaptionEnabled
        switchControl.accessibilityIdentifier = "closedCaptionToggleSwitch"
        return switchControl
    }()
    
    private lazy var spokenLanguageButton: ButtonWithRightArrow = {
        
        let button = ButtonWithRightArrow(leftText: "Spoken Language: ", rightText: info.currentSpokenLanguage.languageTitleInEnglish)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(spokenLanguageButtonTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "spokenLanguageButton"
        return button
    }()
    
    private lazy var translationLanguageButton: ButtonWithRightArrow = {
        let button = ButtonWithRightArrow(leftText: "Translation Language: ", rightText: info.currentTranslationLanguage.languageTitleInEnglish)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(translationLanguageButtonTapped(_:)), for: .touchUpInside)
        button.accessibilityIdentifier = "translationLanguageButton"
        return button
    }()
    
    private lazy var showCaptionsButton: ButtonWithRightArrow = {
        let button = ButtonWithRightArrow(leftText: "Show Captions ", rightText: "")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(showCaptionsButtonTapped(_:)), for: .touchUpInside)
        button.accessibilityIdentifier = "showCaptionsButton"
        return button
    }()
    
    init(call: Call) {
        self.call = call
        self.info = call.getClosedCaptionsInfo()
        super.init(frame: .zero)
        setupSubviews()
        backgroundColor = .backgroundColor
        self.call.onClosedCaptionsInfoChanged = { info in
            self.info = info
            self.spokenLanguageButton.isEnabled = info.canChangeSpokenLanguage
            self.spokenLanguageButton.updateText(leftText: "Spoken Language: ", rightText: info.currentSpokenLanguage.languageTitleInEnglish)
            self.translationLanguageButton.updateText(leftText: "Translation Language: ", rightText: info.currentTranslationLanguage.languageTitleInEnglish)
        }
        self.spokenLanguageButton.isHidden = !call.isClosedCaptionEnabled
        self.translationLanguageButton.isHidden = !call.isClosedCaptionEnabled
        self.showCaptionsButton.isHidden = !call.isClosedCaptionEnabled
        self.spokenLanguageButton.isEnabled = info.canChangeSpokenLanguage
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func closedCaptionToggleValueDidChanged(_ sender: UISwitch) {
        let isOn = sender.isOn
        call.toggleClosedCaption(enable: isOn) { isOn in
            DispatchQueue.main.async { [weak self] in
                sender.isOn = isOn
                self?.delegate?.closedCaptionToggled(isOn: isOn)
                self?.spokenLanguageButton.isHidden = !isOn
                self?.translationLanguageButton.isHidden = !isOn
                self?.showCaptionsButton.isHidden = !isOn
                self?.spokenLanguageButton.isEnabled = self?.info.canChangeSpokenLanguage ?? false
            }
        }
    }
    
    @objc func spokenLanguageButtonTapped(_ sender: UIButton)
    {
        let vc = LanguageSelectionViewController(items: info.spokenLanguages)
        vc.delegate = self
        isSpokenController = true
        UIApplication.shared.topViewController()?.present(vc, animated: true)
    }
    
    @objc func translationLanguageButtonTapped(_ sender: UIButton)
    {
        isSpokenController = false
        let vc = LanguageSelectionViewController(items: info.translationLanguages)
        vc.delegate = self
        UIApplication.shared.topViewController()?.present(vc, animated: true)
    }
    
    @objc func showCaptionsButtonTapped(_ sender: UIButton)
    {
        let vc = ClosedCaptionsViewController(call: call)
        UIApplication.shared.topViewController()?.present(vc, animated: true)
    }
    
    // MARK: - Setup
    private func setupSubviews() {
        addSubview(closedCaptionToggleLabel)
        addSubview(closedCaptionToggleSwitch)
        addSubview(spokenLanguageButton)
        addSubview(translationLanguageButton)
        addSubview(showCaptionsButton)
        
        NSLayoutConstraint.activate([
            closedCaptionToggleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            closedCaptionToggleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            
            closedCaptionToggleSwitch.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            closedCaptionToggleSwitch.leftAnchor.constraint(equalTo: closedCaptionToggleLabel.rightAnchor, constant: 16),
            
            spokenLanguageButton.topAnchor.constraint(equalTo: closedCaptionToggleSwitch.bottomAnchor, constant: 16),
            spokenLanguageButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            spokenLanguageButton.widthAnchor.constraint(equalTo: widthAnchor),
            
            translationLanguageButton.topAnchor.constraint(equalTo: spokenLanguageButton.bottomAnchor, constant: 16),
            translationLanguageButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            translationLanguageButton.widthAnchor.constraint(equalTo: widthAnchor),

            showCaptionsButton.topAnchor.constraint(equalTo: translationLanguageButton.bottomAnchor, constant: 16),
            showCaptionsButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            showCaptionsButton.widthAnchor.constraint(equalTo: widthAnchor)

        ])
    }
}

extension ClosedCaptionsMenuView: LanguageSelectionViewControllerDelegate
{
    func languageSelected(language: WebexSDK.LanguageItem) {
        if isSpokenController {
            delegate?.setSpokenLanguage(languageItem: language)
        }else{
            delegate?.setTranslationLanguage(languageItem: language)
        }
    }
}

class ButtonWithRightArrow: UIButton {
    
    private lazy var leftLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.accessibilityIdentifier = "leftLabel"
        return label
    }()
    
    private lazy var rightLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.accessibilityIdentifier = "rightLabel"
        return label
    }()
    
    private lazy var arrowImageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        if #available(iOS 13.0, *) {
            view.image = UIImage(systemName: "chevron.right")
        }
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        view.accessibilityIdentifier = "arrowImageView"
        return view
    }()
    
    init(leftText: String, rightText: String) {
        super.init(frame: .zero)
        self.backgroundColor = .backgroundColor
        setupSubviews()
        leftLabel.text = leftText
        rightLabel.text = rightText
    }
    
    // MARK: - Setup
    private func setupSubviews() {
        addSubview(leftLabel)
        addSubview(rightLabel)
        addSubview(arrowImageView)
        NSLayoutConstraint.activate([
            leftLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            leftLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            rightLabel.leadingAnchor.constraint(equalTo: leftLabel.trailingAnchor, constant: 8),
            rightLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrowImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            arrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 20), // Adjust the width as needed
            arrowImageView.heightAnchor.constraint(equalTo: arrowImageView.widthAnchor),
        ])
    }
    
    func updateText(leftText: String, rightText: String) {
        leftLabel.text = leftText
        rightLabel.text = rightText
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
