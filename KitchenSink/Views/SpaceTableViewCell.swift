import UIKit

class SpaceTableViewCell: UITableViewCell, ReusableCell {
    typealias ButtonActionHandler = () -> Void
    private var messageButtonHandler: ButtonActionHandler?
    private var addButtonHandler: ButtonActionHandler?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "TitleLabel"
        label.font = .preferredFont(forTextStyle: .title3)
        return label
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "DetailLabel"
        label.font = .preferredFont(forTextStyle: .subheadline)
        return label
    }()
    
    private let messageButton: UIButton = {
        let button = UIButton()
        button.setBackgroundImage(UIImage(named: "bubble-left"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "MessageButton"
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
        messageButton.addTarget(self, action: #selector(messageButtonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageButtonHandler = nil
    }
    
    func setupCell(name: String?, description: String?, isOnCall: Bool, messageButtonHandler: @escaping ButtonActionHandler = {}) {
        detailLabel.text = description
        if isOnCall {
            titleLabel.text = name
            titleLabel.textColor = .green
            titleLabel.text?.append(" (On Call)")
        } else {
            titleLabel.text = name
            if #available(iOS 13.0, *) {
                titleLabel.textColor = .label
            } else {
                titleLabel.textColor = .black
            }
        }
        self.messageButtonHandler = messageButtonHandler
    }
}

extension SpaceTableViewCell {
    // MARK: Private Methods
    @objc private func messageButtonTapped() {
        messageButtonHandler?()
    }
    
    @objc private func addButtonTapped() {
        addButtonHandler?()
    }
    
    private func setupConstraints() {
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: titleLabel, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: titleLabel, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 8)
        ])
        
        contentView.addSubview(detailLabel)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: detailLabel, attribute: .leading, relatedBy: .equal, toItem: titleLabel, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: detailLabel, attribute: .top, relatedBy: .equal, toItem: titleLabel, attribute: .bottom, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: detailLabel, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: -8)
        ])
        
        contentView.addSubview(messageButton)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: messageButton, attribute: .leading, relatedBy: .equal, toItem: titleLabel, attribute: .trailing, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: messageButton, attribute: .leading, relatedBy: .equal, toItem: detailLabel, attribute: .trailing, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: messageButton, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: messageButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 24),
            NSLayoutConstraint(item: messageButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 24),
            NSLayoutConstraint(item: messageButton, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: -16)
        ])
    }
}
