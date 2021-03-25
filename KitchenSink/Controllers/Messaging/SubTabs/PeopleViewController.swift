import Foundation
import UIKit
import WebexSDK

final class PeopleViewController: BasicTableViewController<Person, ContactTableViewCell> {
    // MARK: Properties
    private var searchTimer: Timer?
    private var searchTerm: String = "" {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.refreshList()
            }
        }
    }
    // MARK: Views
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        searchBar.placeholder = "Type Email or Username"
        searchBar.delegate = self
        return searchBar
    }()
    
    init() {
        super.init(placeholderText: "No People")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    private func setupViews() {
        tableView.tableHeaderView = searchBar
    }
    
    override func refreshList() {
        webex.people.list(email: nil, displayName: searchTerm, id: nil, max: 50, queue: DispatchQueue.global(qos: .default) ) {
            [weak self] in
            switch $0 {
            case .success(let val):
                self?.listItems = val
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

extension PeopleViewController {
    private func fetchPerson(byId id: String) {
        webex.people.get(personId: id, queue: DispatchQueue.global(qos: .background)) { [weak self] result in
            let dismissAction = UIAlertAction.dismissAction(withTitle: "Dismiss")
            let alertController: UIAlertController
            if let person = result.data {
                alertController = UIAlertController(title: "Person Found", message: person.displayValue, preferredStyle: .alert)
            } else {
                alertController = UIAlertController(title: "Error Fetching Person", message: "There was an error getting person \(String(describing: result.error))", preferredStyle: .alert)
            }
            alertController.addAction(dismissAction)
            DispatchQueue.main.async {
                self?.present(alertController, animated: true)
            }
        }
    }
    
    private func postMessageByPersonId(byId id: String) {
        present(MessageComposerViewController(id: id, type: .personId), animated: true, completion: nil)
    }
    
    private func postMessageByPersonEmail(byId id: String) {
        present(MessageComposerViewController(id: id, type: .personEmail), animated: true, completion: nil)
    }
}

extension PeopleViewController {
    // MARK: UITableViewDatasource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.reuseIdentifier, for: indexPath) as? ContactTableViewCell else {
            return UITableViewCell()
        }
        let personItem = listItems[indexPath.row]
        cell.setupCell(name: personItem.displayName, description: personItem.displayValue)
        
        return cell
    }
}

extension PeopleViewController {
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let alertController = UIAlertController(title: "People Actions", message: nil, preferredStyle: .actionSheet)
        if let personId = listItems[indexPath.row].id {
            alertController.addAction(UIAlertAction(title: "Fetch Person by Id", style: .default) { [weak self] _ in
                self?.fetchPerson(byId: personId)
            })
            
            alertController.addAction(UIAlertAction(title: "Post Message by PersonId", style: .default) { [weak self] _ in
                self?.postMessageByPersonId(byId: personId)
            })
            
            alertController.addAction(UIAlertAction(title: "Post Message by PersonEmail", style: .default) { [weak self] _ in
                self?.postMessageByPersonEmail(byId: personId)
            })
        }
        present(alertController, animated: true)
    }
}

extension PeopleViewController: UISearchBarDelegate {
    // MARK: SearchBar Delegates
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
            self.searchTerm = searchText
        })
    }
}
extension PeopleViewController: NavigationItemSetupProtocol {
    // MARK: NavigationItemSetupProtocol functions
    var rightBarButtonItems: [UIBarButtonItem]? {
        return []
    }
}

extension WebexSDK.Person {
    var displayValue: String {
        "Person Id: \(id ?? "--"),\nDisplay Name: \(displayName ?? "--"),\nCreated Date: \(created?.description ?? "--"),\nLast Activity: \(lastActivity?.description ?? "--"),\nEmail: \(emails?.map { $0.toString() }.joined() ?? "--"),\nFirstName: \(firstName?.description ?? "--"),\nLast Name: \(lastName?.description ?? "--"),\nOrg Id: \(orgId?.description ?? "--")"
    }
}
