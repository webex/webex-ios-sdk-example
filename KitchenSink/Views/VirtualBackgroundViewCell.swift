import UIKit
import WebexSDK

class VirtualBackgroundViewCell: UICollectionViewCell {
    typealias ButtonActionHandler = () -> Void
    private var buttonActionHandler: ButtonActionHandler?
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
        view.layer.cornerRadius = 10
        return view
    }()
    
    private var backgroundImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "none")
        imageView.setWidth(40)
        imageView.setHeight(40)
        return imageView
    }()
    
    private var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .labelColor
        return label
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(UIImage(named: "delete"), for: .normal)
        button.backgroundColor = .momentumRed50
        button.setWidth(20)
        button.setHeight(20)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(handleButtonAction(_:)), for: .touchUpInside)
        return button
    }()
    
    func setupCell(with backgroundItem: Phone.VirtualBackground, buttonActionHandler handler: @escaping ButtonActionHandler = {}) {
        switch backgroundItem.type {
        case .none:
            self.backgroundImage.image = UIImage(named: "none")
            self.label.text = "None"
        case .blur:
            self.backgroundImage.image = UIImage(named: "blur")
            self.label.text = "Blur"
        case .custom:
            guard let thumbnailData = backgroundItem.thumbnail.thumbnail else { return }
            DispatchQueue.main.async {
                self.backgroundImage.image = UIImage(data: thumbnailData)
                self.label.text = "Custom"
            }
        default:
            self.backgroundImage.image = UIImage(named: "none")
        }
        if backgroundItem.isActive {
            self.tileView.backgroundColor = .blue
        } else {
            self.tileView.backgroundColor = .white
        }
        self.buttonActionHandler = handler
    }
    
    @objc private func handleButtonAction(_ sender: UIButton) {
        print("virtual bg: hit delete button")
        buttonActionHandler?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        buttonActionHandler = nil
    }
    
    func setupViews() {
        contentView.addSubview(tileView)
        contentView.addSubview(backgroundImage)
        contentView.addSubview(label)
        contentView.addSubview(deleteButton)
    }
    
    func setupConstraints() {
        var customConstraints: [NSLayoutConstraint] = []
        
        customConstraints.append(deleteButton.topAnchor.constraint(equalTo: tileView.topAnchor))
        customConstraints.append(deleteButton.trailingAnchor.constraint(equalTo: tileView.trailingAnchor))
        
        customConstraints.append(tileView.widthAnchor.constraint(equalToConstant: 50))
        customConstraints.append(tileView.heightAnchor.constraint(equalToConstant: 50))
        customConstraints.append(tileView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor))
        customConstraints.append(tileView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -12))
        
        customConstraints.append(backgroundImage.widthAnchor.constraint(equalToConstant: 40))
        customConstraints.append(backgroundImage.heightAnchor.constraint(equalToConstant: 40))
        customConstraints.append(backgroundImage.centerXAnchor.constraint(equalTo: tileView.centerXAnchor))
        customConstraints.append(backgroundImage.centerYAnchor.constraint(equalTo: tileView.centerYAnchor))
        
        customConstraints.append(label.topAnchor.constraint(equalTo: tileView.bottomAnchor, constant: 8))
        customConstraints.append(label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor))
        
        NSLayoutConstraint.activate(customConstraints)
    }
}
