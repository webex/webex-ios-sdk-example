import UIKit

final class MessageTableViewCell: UITableViewCell, ReusableCell {
    typealias ButtonActionHandler = (Int) -> Void
    private var buttonActionHandler: ButtonActionHandler?
    var messageConstraints: NSLayoutConstraint?
    var replyConstraints: NSLayoutConstraint?
    private let senderIdLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    private let messageBodyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    private var stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 20
        stack.alignment = .leading
        return stack
    }()
    
    private let replyImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "reply")
        imageView.setHeight(30)
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(senderName: String?, sendDate: String?, messagebody: NSAttributedString?, filesName: [String] = [], isReply: Bool, buttonActionHandler handler: @escaping ButtonActionHandler) {
        if isReply {
            messageConstraints?.deactivate()
            replyConstraints = NSLayoutConstraint(item: replyImage, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
            replyConstraints?.activate()
            layoutIfNeeded()
        } else {
            messageConstraints?.activate()
        }
        replyImage.isHidden = !isReply
        senderIdLabel.text = "Sender: \(senderName.valueOrEmpty)"
        dateLabel.text = sendDate
        messageBodyLabel.attributedText = messagebody
        let removedSubviews = stackView.arrangedSubviews.reduce([]) { allSubviews, subview -> [UIView] in
            self.stackView.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        // Deactivate all constraints
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        // Remove the views from self
        removedSubviews.forEach({ $0.removeFromSuperview() })
        buttonActionHandler = handler
        for i in 0..<filesName.count {
            let thumbnailButton: UIButton = {
                let button = UIButton()
                button.contentHorizontalAlignment = .left
                button.tag = i
                button.addTarget(self, action: #selector(handleButtonAction(_:)), for: .touchUpInside)
                return button
            }()
            thumbnailButton.setTitle(filesName[i], for: .normal)
            thumbnailButton.setTitleColor(.green, for: .normal)
            stackView.addArrangedSubview(thumbnailButton)
        }
    }
    
    @objc private func handleButtonAction(_ sender: UIButton) {
        buttonActionHandler?(sender.tag)
    }
}

extension MessageTableViewCell {
    // MARK: Private Methods
    private func setupConstraints() {
        contentView.addSubview(replyImage)
        
        messageConstraints = NSLayoutConstraint(item: replyImage, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        messageConstraints?.activate()
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: replyImage, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: replyImage, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)
        ])
        
        contentView.addSubview(senderIdLabel)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: senderIdLabel, attribute: .leading, relatedBy: .equal, toItem: replyImage, attribute: .trailing, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: senderIdLabel, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: senderIdLabel, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: -8)
        ])
        
        contentView.addSubview(dateLabel)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: dateLabel, attribute: .leading, relatedBy: .equal, toItem: senderIdLabel, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: dateLabel, attribute: .top, relatedBy: .equal, toItem: senderIdLabel, attribute: .bottom, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: dateLabel, attribute: .trailing, relatedBy: .equal, toItem: senderIdLabel, attribute: .trailing, multiplier: 1, constant: 0)
        ])
        
        contentView.addSubview(messageBodyLabel)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: messageBodyLabel, attribute: .leading, relatedBy: .equal, toItem: dateLabel, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: messageBodyLabel, attribute: .top, relatedBy: .equal, toItem: dateLabel, attribute: .bottom, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: messageBodyLabel, attribute: .trailing, relatedBy: .equal, toItem: dateLabel, attribute: .trailing, multiplier: 1, constant: 0)
        ])
        
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: stackView, attribute: .leading, relatedBy: .equal, toItem: messageBodyLabel, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: stackView, attribute: .top, relatedBy: .equal, toItem: messageBodyLabel, attribute: .bottom, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: stackView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: -8)
        ])
    }
}
