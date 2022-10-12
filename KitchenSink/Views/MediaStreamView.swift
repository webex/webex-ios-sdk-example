import UIKit
import WebexSDK

class MediaStreamView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    var mediaRenderView: MediaRenderView = {
        let auxView = MediaRenderView()
        auxView.translatesAutoresizingMaskIntoConstraints = false
        auxView.contentMode = .scaleAspectFit
        return auxView
    }()
    
    var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .labelColor
        return label
    }()
    
    var muteButton: CallButton = {
        var button = CallButton(style: .cta, size: .medium, type: .muteCall)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(25)
        button.setHeight(25)
        button.accessibilityIdentifier = "muteButton"
        return button
    }()
    
    func setRenderView(view: MediaRenderView) {
        removeAllSubviews(type: MediaRenderView.self)
        mediaRenderView = view
        addSubview(mediaRenderView)
        setupConstraints()
    }
    
    func updateView(with auxStream: AuxStream?) {
        if let auxStream = auxStream {
            label.text = auxStream.person?.displayName
            label.textAlignment = .left
            label.isHidden = false
            label.alpha = 1
            mediaRenderView.isHidden = false
        } else {
            label.isHidden = true
            mediaRenderView.isHidden = true
        }
    }
    
    func updateView(with mediaStream: MediaStream?) {
        muteButton.isHidden = false
        if let mediaStream = mediaStream {
            label.text = mediaStream.person.displayName
            label.textAlignment = .left
            label.isHidden = false
            label.alpha = 1
            mediaRenderView.isHidden = false
            if mediaStream.person.sendingVideo {
                DispatchQueue.main.async { [weak self] in
                    self?.mediaRenderView.isHidden = false
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.mediaRenderView.isHidden = true
                }
            }
            
            if mediaStream.person.sendingAudio {
                DispatchQueue.main.async { [weak self] in
                    self?.muteButton.setImage(UIImage(named: "microphone-unmuted"), for: .normal)
                    self?.muteButton.backgroundColor = .systemGray2
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.muteButton.setImage(UIImage(named: "microphone-muted"), for: .normal)
                    self?.muteButton.backgroundColor = .systemGray2
                }
            }
            self.layer.borderWidth = 2
            if mediaStream.isPinned {
                self.layer.borderColor = UIColor.red.cgColor
            } else{
                self.layer.borderColor = UIColor.green.cgColor
            }
          
        } else {
            label.isHidden = true
            mediaRenderView.isHidden = true
        }
    }
    
    func setupViews() {
        addSubview(mediaRenderView)
        addSubview(label)
        addSubview(muteButton)
        muteButton.isHidden = true
    }
    
    func setupConstraints() {
        var customConstraints: [NSLayoutConstraint] = []
        customConstraints.append(mediaRenderView.widthAnchor.constraint(equalToConstant: 170))
        customConstraints.append(mediaRenderView.heightAnchor.constraint(equalToConstant: 130))
        customConstraints.append(mediaRenderView.centerXAnchor.constraint(equalTo: self.centerXAnchor))
        customConstraints.append(mediaRenderView.centerYAnchor.constraint(equalTo: self.centerYAnchor))
                
        customConstraints.append(muteButton.bottomAnchor.constraint(equalTo: mediaRenderView.bottomAnchor, constant: 4))
        customConstraints.append(muteButton.leftAnchor.constraint(equalTo: mediaRenderView.leftAnchor))
        
        customConstraints.append(label.topAnchor.constraint(equalTo: mediaRenderView.bottomAnchor, constant: 8))
        customConstraints.append(label.centerXAnchor.constraint(equalTo: mediaRenderView.centerXAnchor))

        NSLayoutConstraint.activate(customConstraints)
    }
}
