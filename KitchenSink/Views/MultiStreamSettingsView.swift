import UIKit
import WebexSDK

protocol MultiStreamSettingsViewDelegate: AnyObject {
    func cancelClicked()
    func setCategoryAStream(selectedQuality: MediaStreamQuality, duplicate: Bool)
    func setCategoryBStreams(noOfStreams: Int, selectedQuality: MediaStreamQuality)
    func setCategoryCStream(selectedQuality: MediaStreamQuality)
}

class MultiStreamSettingsView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private let qualityPickerView = UIPickerView()
    private let qualityItems = [MediaStreamQuality.LD, MediaStreamQuality.SD, MediaStreamQuality.HD, MediaStreamQuality.FHD]
    var selectedQuality = MediaStreamQuality.LD
    var isDuplicate = false
    weak var delegate: MultiStreamSettingsViewDelegate?
    
    private lazy var headerLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Set Category A Options"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .labelColor
        label.textAlignment = .center
        return label
    }()
    
    private lazy var noOfStreamsLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "No of streams"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .labelColor
        return label
    }()
    
    private lazy var noOfStreamsTextField: UITextField = {
        let field = UITextField(frame: .zero)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.accessibilityIdentifier = "noOfStreamsTextField"
        field.keyboardType = .numberPad
        field.placeholder = "No of streams"
        field.borderStyle = .roundedRect
        field.text = "24"
        let keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(doneButtonClicked(_:)))
        keyboardDoneButtonView.items = [doneButton]
        field.inputAccessoryView = keyboardDoneButtonView
        return field
    }()
    
    private lazy var noOfStreamsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [noOfStreamsLabel, noOfStreamsTextField])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var duplicateSwitch: UISwitch = {
        let toggle = UISwitch(frame: .zero)
        toggle.isOn = isDuplicate
        toggle.setHeight(30)
        toggle.onTintColor = .momentumBlue50
        toggle.addTarget(self, action: #selector(duplicateSwitchValueDidChanged(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private lazy var duplicateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "duplicateLabel"
        label.text = "Duplicate"
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .labelColor
        return label
    }()
    
    private lazy var duplicateSwitchStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [duplicateLabel, duplicateSwitch])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fillProportionally
        return stack
    }()
    
    private lazy var qualityLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "quality"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .labelColor
        return label
    }()
    
    private lazy var qualityTextField: UITextField = {
        let field = UITextField(frame: .zero)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.accessibilityIdentifier = "qualityTextFieldF"
        field.placeholder = "Quality"
        field.borderStyle = .roundedRect
        field.tintColor = .clear
        field.text = "\(MediaStreamQuality.LD)"
        return field
    }()
    
    private lazy var qualityStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [qualityLabel, qualityTextField])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitleColor(.labelColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 28)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.borderColor = UIColor.momentumGreen40.cgColor
        button.alpha = 1
        button.setTitle("Cancel", for: .normal)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 4
        button.addTarget(self, action: #selector(cancelButtonClicked(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var okButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitleColor(.labelColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 28)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.borderColor = UIColor.momentumGreen40.cgColor
        button.alpha = 1
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 4
        button.setTitle("Save", for: .normal)
        button.addTarget(self, action: #selector(saveButtonClicked(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var buttonStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [cancelButton, okButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 30
        stack.distribution = .fillEqually
        return stack
    }()
    
    @objc func duplicateSwitchValueDidChanged(_ sender: UISwitch) {
        self.isDuplicate = sender.isOn
    }
    
    @objc func doneButtonClicked(_ sender: UISwitch) {
        self.endEditing(true)
    }
    
    @objc func cancelButtonClicked(_ sender: UIButton) {
        delegate?.cancelClicked()
    }
    
    @objc func saveButtonClicked(_ sender: UIButton) {
        if  noOfStreamsStack.isHidden && duplicateSwitchStack.isHidden {
            delegate?.setCategoryCStream(selectedQuality: selectedQuality)
        } else if noOfStreamsStack.isHidden {
            delegate?.setCategoryAStream(selectedQuality: selectedQuality, duplicate: isDuplicate)
        } else {
            delegate?.setCategoryBStreams(noOfStreams: Int(Double(noOfStreamsTextField.text ?? "0") ?? 0.0), selectedQuality: selectedQuality)
        }
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
    
    func setupViews() {
        addSubview(headerLabel)
        addSubview(noOfStreamsStack)
        addSubview(duplicateSwitchStack)
        addSubview(qualityStack)
        addSubview(buttonStack)
        qualityPickerView.delegate = self
        qualityPickerView.dataSource = self
        qualityTextField.inputView = self.qualityPickerView
        qualityTextField.inputAccessoryView = self.pickerViewToolBar(inputView: qualityTextField)
        self.layer.borderColor = UIColor.momentumGreen40.cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 4
    }
    
    func setupConstraints() {
        var customConstraints: [NSLayoutConstraint] = []
        
        customConstraints.append(headerLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 8))
        customConstraints.append(headerLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor))
        headerLabel.fillWidth(of: self, padded: 32)
        
        customConstraints.append(noOfStreamsStack.centerXAnchor.constraint(equalTo: self.centerXAnchor))
        customConstraints.append(noOfStreamsStack.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8))
        noOfStreamsStack.fillWidth(of: self, padded: 32)
        
        customConstraints.append(qualityStack.centerXAnchor.constraint(equalTo: self.centerXAnchor))
        customConstraints.append(qualityStack.topAnchor.constraint(equalTo: noOfStreamsStack.bottomAnchor, constant: 8))
        qualityStack.fillWidth(of: self, padded: 32)
        
        customConstraints.append(duplicateSwitchStack.centerXAnchor.constraint(equalTo: self.centerXAnchor))
        customConstraints.append(duplicateSwitchStack.topAnchor.constraint(equalTo: qualityStack.bottomAnchor, constant: 8))
        duplicateSwitchStack.fillWidth(of: self, padded: 32)
        
        customConstraints.append(buttonStack.centerXAnchor.constraint(equalTo: self.centerXAnchor))
        customConstraints.append(buttonStack.topAnchor.constraint(equalTo: duplicateSwitchStack.bottomAnchor, constant: 8))
        buttonStack.fillWidth(of: self, padded: 32)
                
        NSLayoutConstraint.activate(customConstraints)
    }
    
    func setupViewForCategoryA() {
        self.noOfStreamsStack.isHidden = true
        self.duplicateSwitchStack.isHidden = false
        self.headerLabel.text = "Set Category A Options"
    }
    
    func setupViewForCategoryB() {
        self.noOfStreamsStack.isHidden = false
        self.duplicateSwitchStack.isHidden = true
        self.headerLabel.text = "Set Category B Options"
    }
    
    func setupViewForCategoryC() {
        self.noOfStreamsStack.isHidden = true
        self.duplicateSwitchStack.isHidden = true
        self.headerLabel.text = "Set Category C Options"
    }
}

extension MultiStreamSettingsView: UIPickerViewDataSource {
    // MARK: UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case qualityPickerView:
            return qualityItems.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case qualityPickerView:
            return "\(qualityItems[row])"
        default:
            return ""
        }
    }
}

extension MultiStreamSettingsView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == qualityPickerView {
            selectedQuality = qualityItems[row]
            qualityTextField.text = "\(selectedQuality)"
        }
    }
}
