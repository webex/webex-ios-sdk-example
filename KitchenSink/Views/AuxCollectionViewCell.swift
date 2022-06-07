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
    
    func updateCell(with auxStream: AuxStream?) {
        streamView.updateView(with: auxStream)
    }
    
    func updateCell(with mediaStream: MediaStream?) {
        streamView.updateView(with: mediaStream)
    }
    
    func setupViews() {
        contentView.addSubview(streamView)
    }
    
    func setupConstraints() {
        var customConstraints: [NSLayoutConstraint] = []
        customConstraints.append(streamView.widthAnchor.constraint(equalTo: contentView.widthAnchor))
        customConstraints.append(streamView.heightAnchor.constraint(equalTo: contentView.heightAnchor))
        customConstraints.append(streamView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor))
        customConstraints.append(streamView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor))
        NSLayoutConstraint.activate(customConstraints)
    }
}
