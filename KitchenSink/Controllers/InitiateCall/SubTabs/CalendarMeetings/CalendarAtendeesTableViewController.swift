import Foundation
import UIKit
import WebexSDK

class CalendarInviteeTableViewCell: UITableViewCell, ReusableCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func setupCell(inviteeName: String, inviteeResponse: String) {
        textLabel?.numberOfLines = 2
        textLabel?.text = inviteeName
        
        detailTextLabel?.numberOfLines = 0
        detailTextLabel?.text = inviteeResponse
    }
}

class CalendarAtendeesTableViewController: UIViewController, UITableViewDataSource {
    var attendees: [MeetingInvitee]
    private let cellReuseIdentifier = "CalendarAtendeesCell"
    
    init(attendees: [MeetingInvitee]) {
        self.attendees = attendees
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let headerLabel: UILabel = {
        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = "Meeting Attendees"
        headerLabel.font = .boldSystemFont(ofSize: 32)
        return headerLabel
    }()

    private lazy var attendeesTableView: UITableView = {
        let table = UITableView(frame: .zero)
        table.dataSource = self
        table.register(CalendarInviteeTableViewCell.self, forCellReuseIdentifier: self.cellReuseIdentifier)
        table.allowsSelection = false
        table.rowHeight = 64
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    // MARK: overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        title = "Meeting Attendees"
        self.attendeesTableView.reloadData()
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        view.addSubview(attendeesTableView)
        view.addSubview(headerLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: headerLabel, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 16),
            NSLayoutConstraint(item: headerLabel, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 16),
            NSLayoutConstraint(item: headerLabel, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 16),
            NSLayoutConstraint(item: attendeesTableView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 16),
            NSLayoutConstraint(item: attendeesTableView, attribute: .top, relatedBy: .equal, toItem: headerLabel, attribute: .bottom, multiplier: 1, constant: 16),
            NSLayoutConstraint(item: attendeesTableView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 16),
            NSLayoutConstraint(item: attendeesTableView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 16)
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attendees.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as? CalendarInviteeTableViewCell else {
            return UITableViewCell()
        }

        cell.setupCell(inviteeName: attendees[indexPath.row].displayName, inviteeResponse: attendees[indexPath.row].response.rawValue)
        return cell
    }
}
