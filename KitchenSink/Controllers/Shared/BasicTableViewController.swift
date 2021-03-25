import UIKit
import WebexSDK

class BasicTableViewController<ListItemType, CellType: ReusableCell>: UITableViewController {
    // MARK: Properties
    private let placeholderLabel: UILabel
    var listItems: [ListItemType] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.backgroundView = self.listItems.isEmpty ? self.placeholderLabel : nil
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: Lifecycle Methods
    init(placeholderText: String) {
        placeholderLabel = UILabel.placeholderLabel(withText: placeholderText)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshList()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = .backgroundColor
        navigationController?.view.backgroundColor = .backgroundColor
        configureTable()
    }
    
    func refreshList() {}
}

extension BasicTableViewController {
    // MARK: Private Methods
    private func configureTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CellType.self, forCellReuseIdentifier: CellType.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }
}
