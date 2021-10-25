import UIKit
import WebexSDK

protocol ContactSearchViewControllerDelegate: AnyObject {
    func contactSelected(person: Person)
}

final class ContactSearchViewController: UITableViewController {
    private var searchTimer: Timer?
    private var dataSource = [Person]()
    weak var delegate: ContactSearchViewControllerDelegate?

    private lazy var searchController: UISearchController = {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search by name or email"
        return search
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.searchController = searchController
        title = "Search Contacts"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = true
    }
}

extension ContactSearchViewController {
    // MARK: Private Methods
    private func fetchResults(for text: String) {
        let completion: ((Result<[Person]>) -> Void) = { [weak self] in
            self?.dataSource = $0.data ?? []
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        
        if let email = EmailAddress.fromString(text) {
            webex.people.list(email: email, displayName: nil, id: nil, max: 1, queue: .global(qos: .default), completionHandler: completion)
        } else {
            webex.people.list(email: nil, displayName: text, queue: .global(qos: .default), completionHandler: completion)
        }
    }
}

extension ContactSearchViewController: UISearchResultsUpdating {
    // MARK: UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] _ in
            self?.fetchResults(for: text)
        })
    }
}

extension ContactSearchViewController {
    // MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ContactListCell")
        let person = dataSource[indexPath.row]
        cell.textLabel?.text = person.displayName
        if let email = person.emails?.first?.toString() {
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = email
        }
        return cell
    }
}

extension ContactSearchViewController {
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.contactSelected(person: dataSource[indexPath.row])
    }
}
