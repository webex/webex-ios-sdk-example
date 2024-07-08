import UIKit
import WebexSDK

class CalendarMeetingTableViewCell: UITableViewCell, ReusableCell {
    typealias ButtonActionHandler = () -> Void
    private var buttonActionHandler: ButtonActionHandler?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        buttonActionHandler = nil
    }
    
    func setupCell(meeting: WebexSDK.Meeting, shouldShowJoinButton: Bool = false, buttonActionHandler handler: @escaping ButtonActionHandler) {
        textLabel?.numberOfLines = 2
        textLabel?.text = meeting.subject
        
        detailTextLabel?.numberOfLines = 0
        detailTextLabel?.text = "Organizer: \(meeting.organizerName) \nStart: \(meeting.startTime.description(with: .current))\nEnd: \(meeting.endTime.description(with: .current))"
        buttonActionHandler = handler
        
        if shouldShowJoinButton {
            addButtonToAccessoryView(showMove: meeting.isOngoingMeeting && webex.calendarMeetings.isMoveMeetingSupported(meetingId: meeting.meetingId))
        } else {
            accessoryView = nil
        }
    }
    
    func setupCell(name: String?, description: String?) {
        detailTextLabel?.numberOfLines = 0
        detailTextLabel?.text = description
        textLabel?.text = name
    }
    
    @objc private func handleButtonAction(_ sender: UIButton) {
        buttonActionHandler?()
    }
    
    private func addButtonToAccessoryView(showMove: Bool = false) {
        let button = UIButton(type: .system)
        let title = showMove ? "Move Meeting here" : "Join"
        let width = showMove ? 145.0 : 45.0
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.frame.size = CGSize(width: width, height: 35)
        button.backgroundColor = .momentumGreen40
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(handleButtonAction), for: .touchUpInside)
        button.accessibilityIdentifier = "actionButton"
        accessoryView = button
    }
}
