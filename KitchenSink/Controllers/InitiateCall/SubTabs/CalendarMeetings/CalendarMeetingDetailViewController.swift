import UIKit
import WebexSDK

class CalendarMeetingDetailViewController: UIViewController {
    // MARK: Properties
    var meeting: WebexSDK.Meeting
    
    init(meeting: WebexSDK.Meeting) {
        self.meeting = meeting
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Views
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        return sv
    }()
    
    private lazy var informationStackView: UIStackView = {
        let sv = UIStackView()
        sv.alignment = .top
        sv.axis = .vertical
        return sv
    }()
    
    private lazy var subjectLabel: UILabel = {
        let label = UILabel()
        label.text = "Subject: \(meeting.subject)"
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Description: \(meeting.description)"
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private lazy var meetingIdLabel: UILabel = {
        let label = UILabel()
        label.text = "MeetingId: \(meeting.meetingId)"
        return label
    }()
    
    private lazy var seriesIdLabel: UILabel = {
        let label = UILabel()
        label.text = "SeriesId: \(meeting.seriesId)"
        return label
    }()
    
    private lazy var organizerNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Organizer: \(meeting.organizerName)"
        return label
    }()
    
    private lazy var organizerIdLabel: UILabel = {
        let label = UILabel()
        label.text = "OrganizerId: \(meeting.organizer)"
        return label
    }()
    
    private lazy var startTimeLabel: UILabel = {
        let label = UILabel()
        let readableTime = DateUtils.getReadableDateTime(date: meeting.startTime)
        label.text = "Start Time: \(readableTime ?? "StartTime not available")"
        return label
    }()
    
    private lazy var endTimeLabel: UILabel = {
        let label = UILabel()
        let readableTime = DateUtils.getReadableDateTime(date: meeting.endTime)
        label.text = "End Time: \(readableTime ?? "EndTime not available")"
        return label
    }()
    
    private lazy var meetingLinkLabel: UILabel = {
        let label = UILabel()
        label.text = "Meeting Link: \(meeting.link)"
        return label
    }()
    
    private lazy var sipUrlLabel: UILabel = {
        let label = UILabel()
        label.text = "SIP url: \(meeting.sipUrl)"
        return label
    }()
    
    private lazy var meetingLocationLabel: UILabel = {
        let label = UILabel()
        label.text = "Location: \(meeting.location)"
        return label
    }()
    
    private lazy var isAllDayLabel: UILabel = {
        let label = UILabel()
        label.text = "Is All Day: \(meeting.isAllDay.description)"
        return label
    }()
    
    private lazy var isRecurringLabel: UILabel = {
        let label = UILabel()
        label.text = "Is Recurring: \(meeting.isRecurring.description)"
        return label
    }()
    
    private lazy var attendeesLabel: UILabel = {
        let label = UILabel()
        label.text = "Attendees (\(meeting.invitees.count))"
        return label
    }()
    
    private lazy var attendeesButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Attendees", style: .done, target: self, action: #selector(showAttendees(_:)))
        return button
    }()

    // MARK: overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        title = "Meeting details"
        self.navigationItem.setRightBarButton(attendeesButton, animated: true)
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(informationStackView)
        
        informationStackView.addArrangedSubview(meetingIdLabel)
        informationStackView.addArrangedSubview(subjectLabel)
        informationStackView.addArrangedSubview(descriptionLabel)
        informationStackView.addArrangedSubview(organizerNameLabel)
        informationStackView.addArrangedSubview(organizerIdLabel)
        informationStackView.addArrangedSubview(seriesIdLabel)
        informationStackView.addArrangedSubview(startTimeLabel)
        informationStackView.addArrangedSubview(endTimeLabel)
        informationStackView.addArrangedSubview(isAllDayLabel)
        informationStackView.addArrangedSubview(isRecurringLabel)
        informationStackView.addArrangedSubview(meetingLinkLabel)
        informationStackView.addArrangedSubview(sipUrlLabel)
        informationStackView.addArrangedSubview(meetingLocationLabel)
        informationStackView.addArrangedSubview(attendeesLabel)
        
        informationStackView.subviews.forEach { subView in
            if let label = subView as? UILabel {
                label.numberOfLines = 0
                label.lineBreakMode = .byWordWrapping
            }
        }
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        informationStackView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).activate()
        scrollView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).activate()
        scrollView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).activate()
        scrollView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).activate()
        
        informationStackView.topAnchor.constraint(equalTo: scrollView.topAnchor).activate()
        informationStackView.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor).activate()
        informationStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).activate()
        informationStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).activate()
        informationStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).activate()
        
        informationStackView.subviews.last?.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).activate()
    }
    
    @objc private func showAttendees(_ sender: UIButton) {
        let attendeesViewController = CalendarAtendeesTableViewController(attendees: meeting.invitees)
        present(attendeesViewController, animated: true)
    }
}
