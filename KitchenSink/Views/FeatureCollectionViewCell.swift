import UIKit

class FeatureCollectionViewCell: UICollectionViewCell {
    struct Constants {
        static let imageSize: CGFloat = 32
        static let cellDiameter: CGFloat = 72
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        tileView.layer.cornerRadius = Constants.cellDiameter / 2
        tileView.layer.masksToBounds = true
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private var tileView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .labelColor
        return label
    }()
    
    func setupCell(with feature: Feature) {
        imageView.image = UIImage(named: feature.icon)?.withRenderingMode(.alwaysTemplate)
        tileView.backgroundColor = feature.tileColor
        label.text = feature.title
        accessibilityIdentifier = feature.title
    }
    
    func setupViews() {
        contentView.addSubview(tileView)
        contentView.addSubview(imageView)
        contentView.addSubview(label)
    }
    
    func setupConstraints() {
        var customConstraints: [NSLayoutConstraint] = []
        
        customConstraints.append(tileView.widthAnchor.constraint(equalToConstant: Constants.cellDiameter))
        customConstraints.append(tileView.heightAnchor.constraint(equalToConstant: Constants.cellDiameter))
        customConstraints.append(tileView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor))
        customConstraints.append(tileView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -12))
        
        customConstraints.append(imageView.widthAnchor.constraint(equalToConstant: Constants.imageSize))
        customConstraints.append(imageView.heightAnchor.constraint(equalToConstant: Constants.imageSize))
        customConstraints.append(imageView.centerXAnchor.constraint(equalTo: tileView.centerXAnchor))
        customConstraints.append(imageView.centerYAnchor.constraint(equalTo: tileView.centerYAnchor))
        
        customConstraints.append(label.topAnchor.constraint(equalTo: tileView.bottomAnchor, constant: 8))
        customConstraints.append(label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor))
        
        NSLayoutConstraint.activate(customConstraints)
    }
}
