import UIKit
import WebexSDK

class SearchContactViewController: UIViewController, UITableViewDataSource, UISearchBarDelegate {
    // MARK: Properties
    private var searchTimer: Timer?
    private let kCellId = "ResultCell"
    private var items: [Space] = []
    // MARK: Views
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.placeholder = "Type Email or Username"
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero)
        table.dataSource = self
        table.register(ContactTableViewCell.self, forCellReuseIdentifier: self.kCellId)
        table.tableFooterView = UIView()
        table.allowsSelection = false
        table.rowHeight = 64
        table.keyboardDismissMode = .onDrag
        table.backgroundView = self.placeholderLabel
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
    
    // MARK: SearchBar Delegates
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
            self.fetchResults(for: searchText)
        })
    }
    
    // MARK: Private Methods
    private func callSpace(_ space: Space) {
        present(CallViewController(space: space), animated: true)
    }
    
    private func updateResults(_ results: [Space]) {
        items = results
        tableView.reloadData()
        tableView.backgroundView = items.isEmpty ? placeholderLabel : nil
    }
    
    private func fetchResults(for text: String) {
        webex.spaces.filter(query: text) { [weak self] filteredSpaces in
            self?.updateResults(filteredSpaces)
        }
    }
    
    private func setupViews() {
        view.addSubview(searchBar)
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).activate()
        searchBar.fillWidth(of: view)
        
        tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor).activate()
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).activate()
        tableView.fillWidth(of: view)
    }
}

extension SearchContactViewController: NavigationItemSetupProtocol {
    var rightBarButtonItems: [UIBarButtonItem]? {
        return nil
    }
}
