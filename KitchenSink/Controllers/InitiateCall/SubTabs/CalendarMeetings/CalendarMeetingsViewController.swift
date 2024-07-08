import UIKit
import WebexSDK

struct CalendarMeetingItem {
    var calendarMeeting: WebexSDK.Meeting
    var canShowJoinButton: Bool
}

class CalendarMeetingsViewController: UIViewController, UITableViewDataSource {
    // MARK: Properties
    private let kCellId = "CalendarMeetingsListCell"
    private var items: [CalendarMeetingItem] = []
    private var filterStartDate: Date? = Date()
    private var filterEndDate: Date? = Date().addingTimeInterval(60 * 60 * 24)
    // MARK: Views
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero)
        table.dataSource = self
        table.delegate = self
        table.register(CalendarMeetingTableViewCell.self, forCellReuseIdentifier: self.kCellId)
        table.tableFooterView = UIView()
        table.allowsSelection = true
        table.rowHeight = 128
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private var placeholderLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "No calendar meetings"
        label.textColor = .grayColor
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title2)
        return label
    }()
    
    private var startDatePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        if #available(iOS 13.4, *) {
            dp.preferredDatePickerStyle = .compact
        }
        return dp
    }()
    
    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        
        setupViews()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        reloadMeetings(startDate: filterStartDate, endDate: filterEndDate)
        webex.calendarMeetings.onEvent = { event in
            switch event {
            case .created(let meeting):
                self.items.append(CalendarMeetingItem(calendarMeeting: meeting, canShowJoinButton: meeting.canJoin))
            case .updated(let meeting):
                if let eventItem = self.items.firstIndex(where: { $0.calendarMeeting.meetingId == meeting.meetingId }) {
                    self.items[eventItem].calendarMeeting = meeting
                    self.items[eventItem].canShowJoinButton = meeting.canJoin
                    self.resetTableData()
                }
            case .removed(let meetingId):
                self.items.removeAll(where: { $0.calendarMeeting.meetingId == meetingId })
                self.resetTableData()
            @unknown default:
                break
            }
        }
    }
    
    private func reloadMeetings(startDate: Date?, endDate: Date?) {
        webex.calendarMeetings.list(fromDate: startDate, toDate: endDate, completionHandler: { [weak self] result in
            guard let self = self else {
                print("CalendarMeetingsVC self is nil")
                return
            }
            switch result {
            case .success(let meetings):
                self.items = (meetings ?? []).map { CalendarMeetingItem(calendarMeeting: $0, canShowJoinButton: $0.canJoin) }
            case .failure(let error):
                self.items = []
                print("CalendarMeetingsVC error happened: \(error)")
            @unknown default:
                print("CalendarMeetingsVC error happened: unknown error")
            }
            self.resetTableData()
        })
    }
    
    private func resetTableData() {
        DispatchQueue.main.async {
            if self.items.isEmpty {
                self.tableView.backgroundView = self.placeholderLabel
            }
            self.tableView.reloadData()
        }
    }
    
    // MARK: TableView Datasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: kCellId, for: indexPath) as? CalendarMeetingTableViewCell else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        cell.setupCell(meeting: item.calendarMeeting, shouldShowJoinButton: item.canShowJoinButton, buttonActionHandler: { [weak self] in self?.joinMeeting(meeting: item.calendarMeeting) })
        return cell
    }
    
    // MARK: Methods
    private func joinMeeting(meeting: WebexSDK.Meeting) {
        // Present joining options
        let alertController = UIAlertController.actionSheetWith(title: "Join Meeting", message: nil, sourceView: self.view)
        alertController.addAction(UIAlertAction(title: "Join by Meeting Id", style: .default) { _ in
            let callVC = CallViewController(callInviteAddress: meeting.meetingId, moveMeeting: meeting.isOngoingMeeting)
            self.present(callVC, animated: true)
        })
        alertController.addAction(UIAlertAction(title: "Join by Meeting Link", style: .default) { _ in
            let callVC = CallViewController(callInviteAddress: meeting.link, moveMeeting: meeting.isOngoingMeeting)
            self.present(callVC, animated: true)
        })
        alertController.addAction(UIAlertAction(title: "Join by Meeting Number", style: .default) { _ in
            let callVC = CallViewController(callInviteAddress: meeting.sipUrl, moveMeeting: meeting.isOngoingMeeting)
            self.present(callVC, animated: true)
        })
        alertController.addAction(.dismissAction())
        self.present(alertController, animated: true)
    }
    
    private func setupViews() {
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        tableView.fillSuperView()
    }
}

extension CalendarMeetingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let meetingId = items[indexPath.row].calendarMeeting.meetingId
        webex.calendarMeetings.get(meetingId: meetingId) { result in
            switch result {
            case .success(let meeting):
                guard let meeting = meeting else {
                    print("Unable to fetch meeting with id: \(meetingId)")
                    return
                }
                let detailVC = CalendarMeetingDetailViewController(meeting: meeting)
                self.navigationController?.pushViewController(detailVC, animated: true)
            case .failure(let error):
                print(error)
            @unknown default:
                print("Unknown error")
            }
        }
    }
}

extension CalendarMeetingsViewController: NavigationItemSetupProtocol {
    // MARK: NavigationItemSetupProtocol functions
    var rightBarButtonItems: [UIBarButtonItem]? {
        let filterSpacesButton = UIBarButtonItem(image: UIImage(named: "slider-horizontal-3"), style: .plain, target: self, action: #selector(showFilterSheet))
        filterSpacesButton.accessibilityIdentifier = "FilterSpaces"
        return [filterSpacesButton]
    }
    
    @objc private func showFilterSheet() {
        let filterCalendarMeetingsVC = FilterCalendarMeetingsViewController()
        filterCalendarMeetingsVC.delegate = self
        if filterStartDate != nil {
            filterCalendarMeetingsVC.startDatePicker.date = filterStartDate!
        }
        if filterEndDate != nil {
            filterCalendarMeetingsVC.endDatePicker.date = filterEndDate!
        }
        present(filterCalendarMeetingsVC, animated: true)
    }
}

extension CalendarMeetingsViewController: FilterCalendarMeetingsDelegate {
    func didUpdateListParameters(startDate: Date?, endDate: Date?) {
        filterStartDate = startDate
        filterEndDate = endDate
        self.reloadMeetings(startDate: filterStartDate, endDate: filterEndDate)
    }
}
