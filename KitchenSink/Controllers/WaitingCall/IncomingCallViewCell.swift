import UIKit
import AVKit
import WebexSDK
class IncomingCallViewCell: UITableViewCell, ReusableCell {
    typealias ButtonActionHandler = () -> Void

    private var endButtonActionHandler: ButtonActionHandler?
    private var connectCallButtonActionHandler: ButtonActionHandler?
    var currentCallId: String?
    var space: Space?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
    }
    required init?(coder: NSCoder) {
        fatalError()
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "MeetingTitleLabel:"
        label.font = .preferredFont(forTextStyle: .title3)
        label.font = label.font.withSize(20)
        label.sizeToFit()
        return label
    }()

    private lazy var connectCallButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .momentumGreen50
        button.setWidth(30)
        button.setHeight(30)
        button.setImage(UIImage(named: "audio-call"), for: .normal)
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "connectButton"
        button.addTarget(self, action: #selector(connectCallTapped), for: .touchUpInside)
        return button
    }()

    private lazy var endCallButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .momentumRed50
        button.setWidth(30)
        button.setHeight(30)
        button.setImage(UIImage(named: "end-call"), for: .normal)
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "endButton"
        button.addTarget(self, action: #selector(endCallTapped), for: .touchUpInside)
        return button
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        connectCallButtonActionHandler = nil
        endButtonActionHandler = nil
    }

    func setupCallCell(name: String?, connectButtonActionHandler: @escaping ButtonActionHandler, endButtonActionHandler: @escaping ButtonActionHandler) {
        self.titleLabel.text = name
        self.titleLabel.numberOfLines = 0 
        self.titleLabel.lineBreakMode = .byWordWrapping
        self.connectCallButtonActionHandler = connectButtonActionHandler
        self.endButtonActionHandler = endButtonActionHandler
    }

}

extension IncomingCallViewCell{
    // MARK: Private Methods
     @objc private func connectCallTapped() {
        connectCallButtonActionHandler?()
    }

    @objc private func endCallTapped() {
        endButtonActionHandler?()
    }

    private func setupConstraints() {


        contentView.addSubview(endCallButton)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: endCallButton, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: -20)
        ])
        endCallButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true


        contentView.addSubview(connectCallButton)
        connectCallButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: connectCallButton, attribute: .trailing, relatedBy: .equal, toItem: endCallButton, attribute: .trailing, multiplier: 1, constant: -50)
        ])

        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: titleLabel, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 12),
            NSLayoutConstraint(item: titleLabel, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 10),
            NSLayoutConstraint(item: titleLabel, attribute: .rightMargin, relatedBy: .equal, toItem: connectCallButton, attribute: .leftMargin, multiplier: 1, constant: -5)
        ])
    }
}
