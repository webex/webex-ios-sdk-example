import UIKit

class ParticipantTableViewCell: UITableViewCell {
    typealias MuteActionHandler = () -> Void
    private var muteActionHandler: MuteActionHandler?
    let mutebutton = CallButton(style: .cta, size: .small, type: .mutedCall)
    
    private var participantName: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "coHost"
        label.font = .preferredFont(forTextStyle: .headline)
        label.accessibilityIdentifier = "coHostLabel"
        return label
    }()
    
    private var hostLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Host"
        label.font = .preferredFont(forTextStyle: .body)
        label.accessibilityIdentifier = "hostLabel"
        return label
    }()
    
    private var coHostLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "coHost"
        label.font = .preferredFont(forTextStyle: .body)
        label.accessibilityIdentifier = "coHostLabel"
        return label
    }()
    
    private var presenterLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "presenter"
        label.font = .preferredFont(forTextStyle: .body)
        label.accessibilityIdentifier = "presenterLabel"
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        mutebutton.frame.size = CGSize(width: 44, height: 44)
        participantName.numberOfLines = 2
        contentView.addSubview(participantName)
        contentView.addSubview(hostLabel)
        contentView.addSubview(coHostLabel)
        contentView.addSubview(presenterLabel)

        participantName.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        participantName.widthAnchor.constraint(equalToConstant: contentView.bounds.width - 45).activate()
        participantName.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2).isActive = true

        hostLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        hostLabel.topAnchor.constraint(equalTo: participantName.bottomAnchor, constant: 2).isActive = true
        hostLabel.widthAnchor.constraint(equalToConstant: contentView.bounds.width / 4).activate()

        coHostLabel.leadingAnchor.constraint(equalTo: hostLabel.trailingAnchor, constant: 20).isActive = true
        coHostLabel.topAnchor.constraint(equalTo: participantName.bottomAnchor, constant: 2).isActive = true
        coHostLabel.widthAnchor.constraint(equalToConstant: contentView.bounds.width / 4).activate()

        presenterLabel.leadingAnchor.constraint(equalTo: coHostLabel.trailingAnchor, constant: 20).isActive = true
        presenterLabel.topAnchor.constraint(equalTo: participantName.bottomAnchor, constant: 2).isActive = true
        presenterLabel.widthAnchor.constraint(equalToConstant: contentView.bounds.width / 4).activate()

        accessoryView = mutebutton
        mutebutton.accessibilityIdentifier = "muteButton"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        muteActionHandler = nil
    }
    
    func setupCell(name: String, isAudioMuted: Bool) {
        participantName.text = name
        mutebutton.isHidden = !isAudioMuted
    }

    func setupCell(name: String, isAudioMuted: Bool, isHost: Bool, isCoHost: Bool, isPresenter: Bool) {
        participantName.text = name
        mutebutton.isHidden = !isAudioMuted
        hostLabel.isHidden = !isHost
        coHostLabel.isHidden = !isCoHost
        presenterLabel.isHidden = !isPresenter
        mutebutton.isHidden = !isAudioMuted
    }
}
