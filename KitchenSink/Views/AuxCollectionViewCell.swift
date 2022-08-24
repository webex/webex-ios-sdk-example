import UIKit
import WebexSDK

class AuxCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    public var streamView: MediaStreamView = {
        let view = MediaStreamView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public var moreButton: UIButton = {
        let button = CallButton(style: .outlined, size: .medium, type: .more)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(25)
        button.setHeight(25)
        button.accessibilityIdentifier = "moreButton"
        button.isHidden = true
        return button
    }()
    
    public var pinButton: UIButton = {
        let button = CallButton(style: .outlined, size: .medium, type: .pin)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setWidth(25)
        button.setHeight(25)
        button.accessibilityIdentifier = "pinButton"
        button.isHidden = true
        return button
    }()
    
    func updateCell(with auxStream: AuxStream?) {
        streamView.updateView(with: auxStream)
    }
    
    func updateCell(with mediaStream: MediaStream?) {
        moreButton.isHidden = false
        streamView.updateView(with: mediaStream)
        pinButton.isHidden = mediaStream?.isPinned ?? false ? false : true
    }
    
    func setupViews() {
        contentView.addSubview(streamView)
        contentView.addSubview(moreButton)
        contentView.addSubview(pinButton)
        self.contentView.isUserInteractionEnabled = false
    }

    func setupConstraints() {
        var customConstraints: [NSLayoutConstraint] = []
        customConstraints.append(streamView.widthAnchor.constraint(equalTo: contentView.widthAnchor))
        customConstraints.append(streamView.heightAnchor.constraint(equalTo: contentView.heightAnchor))
        customConstraints.append(streamView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor))
        customConstraints.append(streamView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor))
        
        customConstraints.append(moreButton.rightAnchor.constraint(equalTo: contentView.rightAnchor))
        customConstraints.append(moreButton.topAnchor.constraint(equalTo: contentView.topAnchor))
        
        customConstraints.append(pinButton.leftAnchor.constraint(equalTo: contentView.leftAnchor))
        customConstraints.append(pinButton.topAnchor.constraint(equalTo: contentView.topAnchor))

        NSLayoutConstraint.activate(customConstraints)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        guard isUserInteractionEnabled else { return nil }
        
        guard !isHidden else { return nil }
        
        guard alpha >= 0.01 else { return nil }

        guard self.point(inside: point, with: event) else { return nil }

        if moreButton.point(inside: convert(point, to: moreButton), with: event) {
            return moreButton
        }
        return super.hitTest(point, with: event)
    }
}
