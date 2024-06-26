import UIKit
import WebexSDK

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

    lazy var statusIcon: UIImageView = {
        let statusIcon = UIImageView(frame: .zero)
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusIcon.contentMode = .scaleAspectFit
        statusIcon.accessibilityIdentifier = "StatusIcon"
        statusIcon.setHeight(30)
        statusIcon.setWidth(30)
        return statusIcon
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "StatusLabel"
        label.font = .preferredFont(forTextStyle: .title2)
        return label
    }()

    private lazy var statusStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [statusIcon, statusLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fill
        stack.alignment = .fill
        stack.setHeight(40)
        return stack
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
    
    func setupCell(name: String?, description: String?, isOnCall: Bool, presence: Presence?, messageButtonHandler: @escaping ButtonActionHandler = {}) {
        if let presence = presence {
            displayStatus(presence: presence)
        } else {
            statusLabel.text = "NA: Group Space / BOT"
            statusLabel.textColor = .momentumGray50
            statusIcon.image = UIImage(named: "unknown")
        }
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

    func displayStatus(presence: Presence) {
        switch presence.status {
        case .Unknown:
            statusLabel.text = "Unknown"
            statusLabel.textColor = .momentumGray50
            statusIcon.image = UIImage(named: "unknown")
        case .Pending:
            statusLabel.text = "Pending"
            statusLabel.textColor = .momentumOrange50
            statusIcon.image = UIImage(named: "wall-clock")
        case .Active:
            statusLabel.text = "Active"
            statusLabel.textColor = .momentumGreen50
            statusIcon.image = UIImage(named: "yes")
        case .Inactive:
            let time = presence.lastActiveTime.timeIntervalSinceNow.stringFromTimeInterval()
            statusLabel.text = "Inactive \(time)"
            statusLabel.textColor = .momentumSlate50
            statusIcon.image = UIImage(named: "inactive")
        case .Dnd:
            statusLabel.text = "Do Not Disturb"
            statusLabel.textColor = .momentumRed50
            statusIcon.image = UIImage(named: "busy")
        case .Quiet:
            statusLabel.text = "Quiet"
            statusLabel.textColor = .momentumGold50
            statusIcon.image = UIImage(named: "quiet")
        case .Busy:
            statusLabel.text = "Busy"
            statusLabel.textColor = .momentumYellow50
            statusIcon.image = UIImage(named: "dnd")
        case .OutOfOffice:
            statusLabel.textColor = .momentumLime50
            statusLabel.text = "Out Of Office"
            statusIcon.image = UIImage(named: "outofoffice")
        case .Call:
            statusLabel.textColor = .momentumGreen50
            statusLabel.text = "On Call"
            statusIcon.image = UIImage(named: "on-call")
        case .Meeting:
            statusLabel.textColor = .momentumYellow50
            statusLabel.text = "In Meeting"
            statusIcon.image = UIImage(named: "meeting")
        case .Presenting:
            statusLabel.textColor = .momentumRed50
            statusLabel.text = "Presenting"
            statusIcon.image = UIImage(named: "share-screen")
        case .CalendarItem:
            statusLabel.textColor = .momentumYellow50
            statusLabel.text = "In Calendar Meeting"
            statusIcon.image = UIImage(named: "calendar-meeting")
        @unknown default:
            statusLabel.textColor = .momentumGray50
            statusLabel.text = "Unknown"
            statusIcon.image = UIImage(named: "unknown")
        }

        if !presence.customStatus.isEmpty {
            statusLabel.text?.append(" - \(presence.customStatus)")
        }
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

        contentView.addSubview(statusStackView)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: statusStackView, attribute: .leading, relatedBy: .equal, toItem: titleLabel, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: statusStackView, attribute: .top, relatedBy: .equal, toItem: titleLabel, attribute: .bottom, multiplier: 1, constant: 8),
        ])
        
        contentView.addSubview(detailLabel)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: detailLabel, attribute: .leading, relatedBy: .equal, toItem: statusStackView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: detailLabel, attribute: .top, relatedBy: .equal, toItem: statusStackView, attribute: .bottom, multiplier: 1, constant: 8),
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
