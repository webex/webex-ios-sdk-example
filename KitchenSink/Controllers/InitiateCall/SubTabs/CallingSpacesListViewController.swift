import UIKit
import WebexSDK

class CallingSpacesListViewController: UIViewController, UITableViewDataSource {
    // MARK: Properties
    private let kCellId = "SpaceCell"
    private var spaces: [WebexSDK.Space] = []
    
    // MARK: Lifecycle Methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        webex.spaces.list(teamId: nil, max: nil, type: nil, sortBy: .byLastActivity, queue: nil) { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case .success(let lists):
                self.spaces = lists
            case .failure:
                return
            }
            if self.spaces.isEmpty {
                self.tableView.backgroundView = self.placeholderLabel
            }
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        setupViews()
        setupConstraints()
    }
    
    // MARK: TableView Datasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return spaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: kCellId, for: indexPath) as? ContactTableViewCell else {
            return UITableViewCell()
        }
        let space = spaces[indexPath.row]
        cell.setupCell(name: space.title ?? "", buttonActionHandler: { [weak self] in self?.callSpace(space) })
        return cell
    }
    
    // MARK: Methods
    private func callSpace(_ space: WebexSDK.Space) {
        present(CallViewController(space: space), animated: true)
    }
    
    // MARK: Views and Constraints
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
    
    private func setupViews() {
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        tableView.fillSuperView()
    }
}

extension CallingSpacesListViewController: NavigationItemSetupProtocol {
    var rightBarButtonItems: [UIBarButtonItem]? {
        return nil
    }
}
