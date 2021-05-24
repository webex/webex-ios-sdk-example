import UIKit
import AVKit
import WebexSDK
class ScheduledMeetingTableViewCell: UITableViewCell, ReusableCell {
    typealias JoinButtonActionHandler = () -> Void
    private var joinButtonActionHandler: JoinButtonActionHandler?

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

    private let timeLabel: UILabel = {
        let label1 = UILabel()
        label1.translatesAutoresizingMaskIntoConstraints = false
        label1.accessibilityIdentifier = "TimeLabel:"
        label1.font = .preferredFont(forTextStyle: .title3)
        label1.font = label1.font.withSize(14)
        return label1
    }()

    private lazy var joinButton: UIButton = {
        let button = UIButton()
        button.setTitle("JOIN", for: .normal)
        button.backgroundColor = .momentumGreen50
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(joinButtonTappedView), for: .touchUpInside)
        button.accessibilityIdentifier = "joinButton"
        return button
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        joinButtonActionHandler = nil
    }

    func setupCell(name: String?, start: Date?, end:Date?, joinButtonActionHandler: @escaping JoinButtonActionHandler) {
        self.titleLabel.text = name
        self.titleLabel.numberOfLines = 0 // line wrap
        self.titleLabel.lineBreakMode = .byWordWrapping
        if start != nil && end != nil {
            var startTime: String = "\(String(describing: start))"
            var endTime: String = "\(String(describing: end))"
            startTime = startTime.subString(from:19,to:28)
            endTime = endTime.subString(from:19,to:28)
            let hypenTime:String = " -"
            let timeSlot = startTime + hypenTime + endTime

            self.timeLabel.text = timeSlot
        }
        self.joinButtonActionHandler = joinButtonActionHandler
    }
    @objc private func joinButtonTappedView(_ sender: UIButton) {
        joinButtonActionHandler?()
    }
}

extension String {
    func subString(from: Int, to: Int) -> String {
       let startIndex = self.index(self.startIndex, offsetBy: from)
       let endIndex = self.index(self.startIndex, offsetBy: to)
       return String(self[startIndex..<endIndex])
    }
}
extension ScheduledMeetingTableViewCell {
    // MARK: Private Methods
    private func setupConstraints() {

        contentView.addSubview(joinButton)
        NSLayoutConstraint.activate([

            NSLayoutConstraint(item: joinButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30),
            NSLayoutConstraint(item: joinButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 80),
            NSLayoutConstraint(item: joinButton, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: -20)
        ])

        joinButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true

        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: titleLabel, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 12),
            NSLayoutConstraint(item: titleLabel, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 10),
            NSLayoutConstraint(item: titleLabel, attribute: .rightMargin, relatedBy: .equal, toItem: joinButton, attribute: .leftMargin, multiplier: 1, constant: -5)
        ])
        contentView.addSubview(timeLabel)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: timeLabel, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 10),
            NSLayoutConstraint(item: timeLabel, attribute: .top, relatedBy: .equal, toItem: titleLabel, attribute: .lastBaseline, multiplier: 1, constant: 40),
            NSLayoutConstraint(item: timeLabel, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: -5)
        ])

    }
}
