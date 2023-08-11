import UIKit
import AVKit
import WebexSDK

class ScreenShareConfigView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {

    private lazy var headerAudioOption: UILabel = {
        let view = UILabel()
        view.text = "Enable Audio"
        view.font = UIFont.systemFont(ofSize: 20)
        view.textAlignment = .center
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var shareOptimiseOption: UIPickerView = {
        let view = UIPickerView()
        view.delegate = self
        view.dataSource = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var audioOption: UISwitch = {
        let view = UISwitch()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(audioOptionValueDidChange(_:)), for: .valueChanged)
        return view
    }()
    
    let optionList = ["Default", "Optimize for text and images", "Optimize for motion and video"]
    
    var selectedOption = "Default"
    var isSendingAudio = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func setupViews() {
        backgroundColor = .backgroundColor
        addSubview(headerAudioOption)
        addSubview(shareOptimiseOption)
        addSubview(audioOption)
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            shareOptimiseOption.leftAnchor.constraint(equalTo: self.leftAnchor),
            shareOptimiseOption.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            shareOptimiseOption.widthAnchor.constraint(equalTo: self.widthAnchor),
            shareOptimiseOption.heightAnchor.constraint(equalToConstant: 150),
            headerAudioOption.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20),
            headerAudioOption.topAnchor.constraint(equalTo: shareOptimiseOption.bottomAnchor, constant: 20),
            audioOption.leftAnchor.constraint(equalTo: headerAudioOption.rightAnchor, constant: 20),
            audioOption.topAnchor.constraint(equalTo: shareOptimiseOption.bottomAnchor, constant: 20)
        ])
    }
    
    @objc func audioOptionValueDidChange(_ sender: UISwitch) {
        DispatchQueue.main.async {
            if sender.isOn == true {
                self.isSendingAudio = true
            } else {
                self.isSendingAudio = false
            }
        }
    }
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return optionList.count
    }
    
    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel(frame: CGRectMake(0, 0, 400, 44));
        label.lineBreakMode = .byWordWrapping;
        label.numberOfLines = 0;
        label.text = optionList[row]
        label.sizeToFit()
        return label;
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedOption = optionList[row]
        print("Selected option: \(selectedOption)")
    }
    
    public func getSelectedConfig() -> ShareConfig
    {
        var shareType: ShareOptimizeType = .Default
        switch selectedOption
        {
        case "Default":
            shareType = .Default
        case "Optimize for text and images":
            shareType = .OptimizeText
        case "Optimize for motion and video":
            shareType = .OptimizeVideo
        default:
            shareType = .Default
        }
        return ShareConfig(shareType: shareType, enableAudio: isSendingAudio)
    }
}
