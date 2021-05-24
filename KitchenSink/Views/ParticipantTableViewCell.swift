import UIKit

class ParticipantTableViewCell: UITableViewCell {
    typealias MuteActionHandler = () -> Void
    private var muteActionHandler: MuteActionHandler?
    let mutebutton = CallButton(style: .cta, size: .small, type: .mutedCall)
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        mutebutton.frame.size = CGSize(width: 44, height: 44)
        accessoryView = mutebutton
        textLabel?.numberOfLines = 2
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
        textLabel?.text = name
        mutebutton.isHidden = !isAudioMuted
    }
}
