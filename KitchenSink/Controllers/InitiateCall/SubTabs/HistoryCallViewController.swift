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
    
    // MARK: Methods
    private func redialCallHistoryRecord(_ callHistoryRecord: CallHistoryRecord) {
        present(CallViewController(callInviteAddress: callHistoryRecord.callbackAddress), animated: true)
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
