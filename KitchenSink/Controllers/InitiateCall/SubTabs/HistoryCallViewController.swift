import UIKit
import WebexSDK

class HistoryCallViewController: UIViewController, UITableViewDataSource {
    // MARK: Properties
    private let kCellId = "Cell"
    private var items: [Space] = []
    
    // MARK: Views
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero)
        table.dataSource = self
        table.register(ContactTableViewCell.self, forCellReuseIdentifier: self.kCellId)
        table.tableFooterView = UIView()
        table.allowsSelection = false
        table.rowHeight = 64
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private var placeholderLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "No Spaces"
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: kCellId, for: indexPath) as? ContactTableViewCell else {
            return UITableViewCell()
        }
        let space = items[indexPath.row]
        cell.setupCell(name: space.title ?? "", buttonActionHandler: { [weak self] in self?.callSpace(space) })
        return cell
    }
    
    // MARK: Methods
    private func callSpace(_ space: Space) {
        present(CallViewController(space: space), animated: true)
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
