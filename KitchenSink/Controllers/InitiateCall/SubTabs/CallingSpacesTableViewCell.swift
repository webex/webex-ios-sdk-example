import UIKit
import WebexSDK

class CallingSpacesTableViewCell: UITableViewCell, ReusableCell {
    typealias ButtonActionHandler = () -> Void
    private var callButtonHandler: ButtonActionHandler?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "TitleLabel"
        label.font = .preferredFont(forTextStyle: .title3)
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

    private let callButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "CallButton"
        button.setImage(UIImage(named: "on-call"), for: .normal)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
        callButton.addTarget(self, action: #selector(callButtonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        callButtonHandler = nil
    }

    func setupCell(name: String?, presence: Presence?, buttonActionHandler: @escaping ButtonActionHandler = {}) {
        if let presence = presence {
            displayStatus(presence: presence)
        } else {
            statusLabel.text = "NA: Group Space / BOT"
            statusLabel.textColor = .momentumGray50
            statusIcon.image = UIImage(named: "unknown")
        }
        titleLabel.text = name
        self.callButtonHandler = buttonActionHandler
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

extension CallingSpacesTableViewCell {
    // MARK: Private Methods
    @objc private func callButtonTapped() {
        callButtonHandler?()
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

        contentView.addSubview(callButton)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: callButton, attribute: .leading, relatedBy: .equal, toItem: titleLabel, attribute: .trailing, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: callButton, attribute: .leading, relatedBy: .equal, toItem: statusStackView, attribute: .trailing, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: callButton, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: callButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 24),
            NSLayoutConstraint(item: callButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 24),
            NSLayoutConstraint(item: callButton, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: -16)
        ])
    }
}

extension TimeInterval {

    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        let minutes = (time / 60) % 60
        let hours = (time / 3600)

        if hours > 1 {
            return String(format: "\(hours) hours ago")
        } else {
            return String(format: "\(minutes) minutes ago")
        }
    }
}
