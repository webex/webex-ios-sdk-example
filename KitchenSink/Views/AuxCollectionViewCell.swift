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
    
    private var tileView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
    
    var auxView: MediaRenderView = {
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
    
    func updateCell(with auxStream: AuxStream?) {
        if let auxStream = auxStream {
            label.text = auxStream.person?.displayName
            label.isHidden = false
            auxView.isHidden = false
            tileView.isHidden = false
        } else {
            label.isHidden = true
            auxView.isHidden = true
            tileView.isHidden = true
        }
    }
    
    func setupViews() {
        contentView.addSubview(tileView)
        contentView.addSubview(auxView)
        contentView.addSubview(label)
    }
    
    func setupConstraints() {
        var customConstraints: [NSLayoutConstraint] = []
        
        customConstraints.append(tileView.widthAnchor.constraint(equalToConstant: 170))
        customConstraints.append(tileView.heightAnchor.constraint(equalToConstant: 130))
        customConstraints.append(tileView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor))
        customConstraints.append(tileView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -12))
        
        customConstraints.append(auxView.widthAnchor.constraint(equalToConstant: 170))
        customConstraints.append(auxView.heightAnchor.constraint(equalToConstant: 130))
        customConstraints.append(auxView.centerXAnchor.constraint(equalTo: tileView.centerXAnchor))
        customConstraints.append(auxView.centerYAnchor.constraint(equalTo: tileView.centerYAnchor))
        
        customConstraints.append(label.topAnchor.constraint(equalTo: tileView.bottomAnchor, constant: 8))
        customConstraints.append(label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor))
        
        NSLayoutConstraint.activate(customConstraints)
    }
}
