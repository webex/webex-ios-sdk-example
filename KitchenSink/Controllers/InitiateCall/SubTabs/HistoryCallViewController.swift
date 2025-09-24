import UIKit
import WebexSDK

class HistoryCallViewController: UIViewController, UITableViewDataSource {
    // MARK: Properties
    private let kCellId = "Cell"
    private var items: [CallHistoryRecord] = []
    
    // MARK: Views
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero)
        table.dataSource = self
        table.register(CallHistoryRecordTableViewCell.self, forCellReuseIdentifier: self.kCellId)
        table.tableFooterView = UIView()
        table.allowsSelection = false
        table.rowHeight = 64
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private var placeholderLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Your History is empty"
        label.textColor = .grayColor
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title2)
        return label
    }()
    
    // MARK: Lifecycle Methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        items = webex.phone.getCallHistory()
        if items.isEmpty {
            tableView.backgroundView = placeholderLabel
        }
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        
        setupViews()
        setupConstraints()
        
        webex.phone.onCallHistoryEvent = { [weak self] (event) in
            guard let self = self else { return }
            print("Call History Event: \(event)")
            switch event {
            case .syncCompleted:
                items = webex.phone.getCallHistory()
                tableView.reloadData()
                break
            case .removed(let recordIds):
                // Find indexes of items whose recordId is in recordIds
                let indexes = items.enumerated()
                    .compactMap { (idx: Int, item: CallHistoryRecord) -> Int? in
                        guard let recordId = item.recordId, recordIds.contains(recordId) else { return nil }
                        return idx
                    }
                guard !indexes.isEmpty else { break }
                let indexPaths = indexes.map { IndexPath(row: $0, section: 0) }
                // Remove items from the data source in reverse order to avoid index issues
                for index in indexes.sorted(by: >) {
                    items.remove(at: index)
                }
                tableView.beginUpdates()
                tableView.deleteRows(at: indexPaths, with: .automatic)
                tableView.endUpdates()
                // Show placeholder if list is empty
                if items.isEmpty {
                    tableView.backgroundView = placeholderLabel
                }
                break
            case .removeFailed:
                break
            default:
                break
            }
        }
    }
    
    // MARK: TableView Datasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: kCellId, for: indexPath) as? CallHistoryRecordTableViewCell else {
            return UITableViewCell()
        }
        let callHistoryRecord = items[indexPath.row]
        cell.setupCell(callHistoryRecord: callHistoryRecord, buttonActionHandler: { [weak self] in
            self?.redialCallHistoryRecord(callHistoryRecord) })
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("Deleted")
            if let recordIdToDelete = items[indexPath.row].recordId {
                webex.phone.removeCallHistoryRecords(recordIds: [recordIdToDelete])
            }
        }
    }
    
    // MARK: Methods
    private func redialCallHistoryRecord(_ callHistoryRecord: CallHistoryRecord) {
        present(CallViewController(callInviteAddress: callHistoryRecord.callbackAddress, isPhoneNumber: callHistoryRecord.isPhoneNumber), animated: true)
    }
    
    private func setupViews() {
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        tableView.fillSuperView()
    }
}

extension HistoryCallViewController: NavigationItemSetupProtocol {
    var rightBarButtonItems: [UIBarButtonItem]? {
        return nil
    }
}
