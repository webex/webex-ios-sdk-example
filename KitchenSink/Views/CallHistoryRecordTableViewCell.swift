import UIKit
import WebexSDK

class CallHistoryRecordTableViewCell: UITableViewCell, ReusableCell {
    typealias ButtonActionHandler = () -> Void
    private var buttonActionHandler: ButtonActionHandler?
    
    // MARK: - Properties
    private lazy var callIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(callIconImageView)
        addSubview(nameLabel)
        addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            callIconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            callIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            callIconImageView.widthAnchor.constraint(equalToConstant: 20),
            callIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            nameLabel.leadingAnchor.constraint(equalTo: callIconImageView.trailingAnchor, constant: 8),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: (accessoryView != nil) ? accessoryView!.leadingAnchor : safeAreaLayoutGuide.trailingAnchor, constant: -8),
            
            timeLabel.leadingAnchor.constraint(equalTo: callIconImageView.trailingAnchor, constant: 8),
            timeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            timeLabel.trailingAnchor.constraint(equalTo:  (accessoryView != nil) ? accessoryView!.leadingAnchor : safeAreaLayoutGuide.trailingAnchor, constant: -8),
            
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        buttonActionHandler = nil
    }
    
    func setupCell(callHistoryRecord: CallHistoryRecord, buttonActionHandler handler: @escaping ButtonActionHandler) {
        
        nameLabel.text = callHistoryRecord.displayName
        timeLabel.text = getFormattedCallDateAndDuration(callHistoryRecord)
        callIconImageView.image = getCallDirectionImage(callHistoryRecord)
        
        buttonActionHandler = handler
        addButtonToAccessoryView()
    }
    
    private func getCallDirectionImage(_ callHistoryRecord: CallHistoryRecord) -> UIImage? {
        if(callHistoryRecord.isMissedCall){
            return UIImage(named: "missed-call.png")
        } else if(callHistoryRecord.callDirection == .outgoing) {
            return UIImage(named: "outgoing-call.png")
        } else {
            return UIImage(named: "incoming-call.png")
        }
    }
    
    private func getFormattedCallDateAndDuration(_ callHistoryRecord: CallHistoryRecord) -> String {
        
        var startTimeAndDuration = ""
        
        let duration = DateUtils.getReadableDuration(durationInSeconds: callHistoryRecord.duration)
        
        if let startDateTime = DateUtils.getReadableDateTime(date: callHistoryRecord.startTime) {
            startTimeAndDuration = startDateTime
        }
        
        if let duration = duration {
            startTimeAndDuration = [startTimeAndDuration, duration].joined(separator: " - ")
        }
        
        return startTimeAndDuration
    }
    
    @objc private func handleButtonAction(_ sender: UIButton) {
        buttonActionHandler?()
    }
    
    private func addButtonToAccessoryView() {
        let button = CallButton(style: .outlined, size: .small, type: .connectCall)
        button.frame.size = CGSize(width: 44, height: 44)
        button.addTarget(self, action: #selector(handleButtonAction), for: .touchUpInside)
        button.accessibilityIdentifier = "actionButton"
        accessoryView = button
    }
}
