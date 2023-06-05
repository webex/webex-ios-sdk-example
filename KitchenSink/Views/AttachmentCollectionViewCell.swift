import UIKit
class AttachmentCollectionViewCell: UICollectionViewCell {
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
        
    private lazy var progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "delete"), for: .normal)
        button.tintColor = .red
        return button
    }()
    
    public private(set) var id:String = ""
    private var deleteButtonAction: (() -> Void)?
    
    private func addConstraints() {
        // Add constraints for imageView
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        // Add constraints for progressView
        NSLayoutConstraint.activate([
            progressView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
            progressView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
            progressView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        
        // Add constraints for deleteButton
        NSLayoutConstraint.activate([
            deleteButton.widthAnchor.constraint(equalToConstant: 16),
            deleteButton.heightAnchor.constraint(equalToConstant: 16),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
        ])
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(progressView)
        contentView.addSubview(deleteButton)
        addConstraints()
    }
    
    public func configure(id: String, image: UIImage, action: @escaping () -> Void) {
        self.id = id
        imageView.image = image
        deleteButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        deleteButtonAction = action
    }
    
    public func configureUploadProgress(progress: Float) {
        progressView.setProgress(progress, animated: false)
    }
    
    @objc func buttonTapped() {
        deleteButtonAction?()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
