import UIKit
import WebexSDK

class CallingSpacesListViewController: UIViewController, UITableViewDataSource {
    // MARK: Properties
    private let kCellId = "SpaceCallCell"
    private var spaces: [WebexSDK.Space] = []
    var directSpaceIds : [String] = []
    var spaceIdPresenceDict: [String: Presence] = [:]
    var selfPersonId: String?
    var spaceIdPersonIdDict: [String : String] = [:]
    var handles: [PresenceHandle] = []
    
    // MARK: Lifecycle Methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if !webex.spaces.isSpacesSyncCompleted {
            print("isSpacesSyncCompleted \(false)")
            self.showLoadingIndicator("syncing spaces")
        }
        
        webex.spaces.onSyncingSpacesStatusChanged = { isSpacesSyncInProgress in
            print("Syncing Spaces: \(isSpacesSyncInProgress)")
            if isSpacesSyncInProgress {
                self.showLoadingIndicator("syncing spaces")
            } else {
                self.dismissLoadingIndicator()
            }
        }
        
        webex.spaces.list(teamId: nil, max: nil, type: nil, sortBy: .byLastActivity, queue: nil) { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case .success(let lists):
                self.spaces = lists
                let directSpaces = lists.filter( {$0.type == .direct} )
                self.directSpaceIds = directSpaces.map { $0.id ?? "" }
                self.getPresenceStatus()
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: kCellId, for: indexPath) as? CallingSpacesTableViewCell else {
            return UITableViewCell()
        }
        let space = spaces[indexPath.row]
        var presence: Presence?
        if let spaceId = space.id, let presenceForSpaceId = spaceIdPresenceDict[spaceId] {
            presence = presenceForSpaceId
        }

        cell.setupCell(name: space.title ?? "", presence: presence, isGroupSpace: (space.type == .group), buttonActionHandler: { [weak self] in self?.callSpace(space) })
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
        table.register(CallingSpacesTableViewCell.self, forCellReuseIdentifier: self.kCellId)
        table.tableFooterView = UIView()
        table.allowsSelection = false
        table.rowHeight = 100
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

extension CallingSpacesListViewController {
    func getPresenceStatus() {
        let selfId = UserDefaults.standard.string(forKey: Constants.selfId)
        for spaceId in directSpaceIds {
            webex.memberships.list(spaceId: spaceId, completionHandler: { result in
                switch result {
                case .success(let memberships):
                    var personId = ""
                    for membership in memberships {
                        if membership.personId != selfId {
                            personId = membership.personId ?? ""
                            self.spaceIdPersonIdDict[personId] = spaceId
                        }
                    }
                    self.handles = webex.people.startWatchingPresences(contactIds: [personId], completionHandler: { presence in
                        let spaceId = self.spaceIdPersonIdDict[personId]
                        if let spaceId = spaceId, self.spaceIdPresenceDict[spaceId]?.status != presence.status {
                            self.spaceIdPresenceDict[spaceId] = presence
                            if let index = self.spaces.firstIndex(where: { $0.id == spaceId }) {
                                DispatchQueue.main.async {
                                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                                }
                            }
                        }
                    })
                case .failure(_):
                    return
                @unknown default:
                    return
                }
            })
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        webex.people.stopWatchingPresences(presenceHandles: self.handles)
    }
}
