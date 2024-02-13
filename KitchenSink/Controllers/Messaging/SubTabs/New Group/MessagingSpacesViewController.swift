import UIKit
import WebexSDK

final class MessagingSpacesViewController: BasicTableViewController<MessagingSpacesViewController.SpaceItem, SpaceTableViewCell> {
    private var spaceValue = SpaceValue.space
    fileprivate var onGoingSpaceCalls = [String: Bool]()
    var directSpaceIds : [String] = []
    var spaceIdPresenceDict: [String: Presence] = [:]
    var selfPersonId: String?
    var spaceIdPersonIdDict: [String : String] = [:]
    var handles: [PresenceHandle] = []

    init() {
        super.init(placeholderText: "No Spaces")
        registerSpaceCallBack()
        registerSpaceCallBackWithPayload()
        registerSyncingSpacesStatusChanged()
        getActiveCalls()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func refreshList() {
        switch spaceValue {
        case .space:
            webex.spaces.list(teamId: nil, max: nil, type: nil, sortBy: .byLastActivity, queue: DispatchQueue.global(qos: .default)) { [weak self] in
                switch $0 {
                case .failure(let error):
                    DispatchQueue.main.sync {
                        let alert = UIAlertController(title: "Error listing spaces", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(.dismissAction(withTitle: "Ok"))
                        self?.present(alert, animated: true)
                    }
                case .success(let listspaces):
                    let directSpaces = listspaces.filter( {$0.type == .direct} )
                    self?.directSpaceIds = directSpaces.map { $0.id ?? "" }
                    self?.listItems = (listspaces).map { .space($0) }
                    self?.getPresenceStatus()
                }
            }
        case .readStatus:
            webex.spaces.listWithReadStatus(max: 20, queue: DispatchQueue.global(qos: .default)) { [weak self] in
                switch $0 {
                case .failure(let error):
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Error listing spaces with read status", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(.dismissAction(withTitle: "Ok"))
                        self?.present(alert, animated: true)
                    }
                    
                case .success(let listspaces):
                    self?.listItems = (listspaces ?? []).map { return .readStatus($0) }
                }
            }
        }
    }
}

extension MessagingSpacesViewController {
    // MARK: Enums
    enum SpaceValue {
        case space, readStatus
    }
    enum SpaceItem {
        case space(WebexSDK.Space), readStatus(SpaceReadStatus)
    }
}

extension MessagingSpacesViewController {
    // MARK: Private Methods
    @objc private func addSpace() {
        let alertController = UIAlertController.createWithTextField(title: "Add Space", message: "Enter the name of the new Space", style: .alert)
        alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            if let title = alertController.textFields?.first?.text {
                webex.spaces.create(title: title) { [weak self] _ in
                    self?.refreshList()
                }
            }
        })
        present(alertController, animated: true)
    }
    
    private func sendMessageToSpace(spaceId: String) {
        present(MessageComposerViewController(id: spaceId, type: .spaceId), animated: true, completion: nil)
    }
    
    private func fetchSpace(byId id: String) {
        webex.spaces.get(spaceId: id, queue: DispatchQueue.global(qos: .background)) {  [weak self] result in
            DispatchQueue.main.async {
                let dismissAction = UIAlertAction.dismissAction(withTitle: "Dismiss")
                switch result {
                case .success(let space):
                    let alertController = UIAlertController(title: "Space Found", message: space.displayValue, preferredStyle: .alert)
                    alertController.addAction(dismissAction)
                    self?.present(alertController, animated: true)
                case .failure(let error):
                    let alertController = UIAlertController(title: "Error Fetching Space", message: "No space found with given id", preferredStyle: .alert)
                    alertController.addAction(dismissAction)
                    self?.present(alertController, animated: true)
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    private func deleteSpace(byId id: String, withTitle title: String?) {
        let alertController = UIAlertController(title: "Please Confirm", message: "This action will delete the space: \(title.valueOrEmpty)", preferredStyle: .alert)
        alertController.addAction(UIAlertAction.dismissAction())
        alertController.addAction(UIAlertAction(title: "Delete", style: .default) { _ in
            alertController.dismiss(animated: true) {
                webex.spaces.delete(spaceId: id, queue: DispatchQueue.global(qos: .background)) { [weak self]  in
                    switch $0 {
                    case .success:
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Deleted Space", message: "Deleted: \(title.valueOrEmpty)", preferredStyle: .alert)
                            alert.addAction(.dismissAction(withTitle: "Dismiss"))
                            self?.present(alert, animated: true)
                            self?.refreshList()
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Error Deleting Space", message: error.localizedDescription, preferredStyle: .alert)
                            alert.addAction(.dismissAction(withTitle: "Dismiss"))
                            self?.present(alert, animated: true)
                        }
                    }
                }
            }
        })

        present(alertController, animated: true)
    }
    
    private func fetchMeetingInfo(byId id: String) {
        webex.spaces.getMeetingInfo(spaceId: id, queue: DispatchQueue.global(qos: .userInitiated)) { result in
            DispatchQueue.main.async { [weak self] in
                let dismissAction = UIAlertAction.dismissAction(withTitle: "Dismiss")
                switch result {
                case .success(let meetingInfo):
                    let alertController = UIAlertController(title: "Meeting Information", message: meetingInfo.displayValue, preferredStyle: .alert)
                    alertController.addAction(dismissAction)
                    self?.present(alertController, animated: true)
                case .failure:
                    break
                }
            }
        }
    }
    
    private func fetchSpaceReadStatus(byId id: String) {
        webex.spaces.getWithReadStatus(spaceId: id, queue: DispatchQueue.global(qos: .default)) { [weak self] readStatus in
            DispatchQueue.main.async {
                let readStatusData = readStatus.data
                let dismissAction = UIAlertAction.dismissAction(withTitle: "Dismiss")
                switch readStatus {
                case .failure:
                    let alertController = UIAlertController(title: "Error Fetching Space Read Status", message: "No space read status found with given id", preferredStyle: .alert)
                    alertController.addAction(dismissAction)
                    self?.present(alertController, animated: true)
                    
                case .success(readStatusData):
                    guard let readStatusData = readStatusData else { return }
                    let alertController = UIAlertController(title: "Space Read Status", message: readStatusData?.displayValue, preferredStyle: .alert)
                    alertController.addAction(dismissAction)
                    self?.present(alertController, animated: true)
                @unknown default:
                    return
                }
            }
        }
    }
    
    @objc private func showFilterSheet() {
        let filterSpacesVC = FilterSpacesViewController()
        filterSpacesVC.delegate = self
        present(filterSpacesVC, animated: true)
    }
    
    private func spaceIdFrom(spaceItem: SpaceItem) -> String? {
        switch spaceItem {
        case .space(let space):
            return space.id
        case .readStatus(let readStatus):
            return readStatus.id
        }
    }
    
    private func getSpaceNameFrom(spaceItem: SpaceItem) -> String? {
        switch spaceItem {
        case .space(let space):
            return space.title
        default:
            return nil
        }
    }
    
    private func showUpdateSpaceNameAlert(spaceId: String, title: String?) {
        let alertController = UIAlertController.createWithTextField(title: "Update Space Title", message: "Enter the new title of the Space", style: .alert)
        if let title = title {
            alertController.textFields?.first?.text = title
        }
        alertController.addAction(UIAlertAction(title: "Update", style: .default) { _ in
            guard let title = alertController.textFields?.first?.text else { return }
            alertController.dismiss(animated: true) {
                webex.spaces.update(spaceId: spaceId, title: title, queue: .global(qos: .default)) { result in
                    let space = result.data
                    let (alertTitle, alertMsg) = (space != nil) ? ("Success", "Space's new title: \(space?.title ?? "")") : ("Failure", "Space update failure")
                    let successController = UIAlertController(title: alertTitle, message: alertMsg, preferredStyle: .alert)
                    successController.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
                    DispatchQueue.main.async { [weak self] in
                        self?.present(successController, animated: true)
                        self?.refreshList()
                    }
                }
            }
        })
        
        present(alertController, animated: true)
    }
    
    private func markSpaceAsRead(_ spaceId: String) {
        webex.messages.markAsRead(spaceId: spaceId, queue: DispatchQueue.global(qos: .default)) { result in
            let message: String = {
                switch result {
                case .success:
                    return "Message marked read."
                case .failure(let error):
                    return "Failed to mark message read. \(error)"
                }
            }()
            let alert = UIAlertController(title: "Result", message: message, preferredStyle: .alert)
            alert.addAction(.dismissAction(withTitle: "Ok"))
            DispatchQueue.main.async { [weak self] in
                self?.present(alert, animated: true)
            }
        }
    }
    
    func registerSpaceCallBack() {
        webex.spaces.onEvent = { event in
            switch event {
            case .create:
                break
            case .update:
                break
            case .spaceCallStarted:
                break
            case .spaceCallEnded:
                break
            default:
                break
            }
        }
    }
    
    func registerSpaceCallBackWithPayload() {
        webex.spaces.onEventWithPayload = { event, id in
            print(id)
            switch event {
            case .create:
                self.refreshList()
            case .update:
                self.refreshList()
            case .spaceCallStarted(let spaceId):
                self.spaceCallOnGoing(spaceId, isStarted: true)
            case .spaceCallEnded(let spaceId):
                self.spaceCallOnGoing(spaceId, isStarted: false)
            default:
                break
            }
        }
    }
    
    func registerSyncingSpacesStatusChanged() {
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

    }
    
    private func spaceCallOnGoing(_ spaceId: String, isStarted: Bool) {
        if isStarted, self.onGoingSpaceCalls[spaceId] == nil {
            self.onGoingSpaceCalls[spaceId] = isStarted
        } else if !isStarted, self.onGoingSpaceCalls[spaceId] != nil {
            self.onGoingSpaceCalls.removeValue(forKey: spaceId)
        }
        
        for i in 0..<listItems.count {
            let id = spaceIdFrom(spaceItem: listItems[i])
            if id == spaceId {
                let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? SpaceTableViewCell
                let spaceItem = listItems[i]
                switch spaceItem {
                case .space(let space):
                    var presence : Presence?
                    if let presenceOfSpaceId = spaceIdPresenceDict[spaceId] {
                        presence = presenceOfSpaceId
                    }
                    cell?.setupCell(name: space.title, description: space.displayValue, isOnCall: isStarted, presence: presence) { [weak self] in
                        guard let self = self, let spaceId = space.id else { return }
                        self.sendMessageToSpace(spaceId: spaceId)
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func getActiveCalls() {
        webex.spaces.listWithActiveCalls(completionHandler: { result in
            switch result {
            case .success(let spaceIds):
                for i in 0..<spaceIds.count {
                    self.onGoingSpaceCalls[spaceIds[i]] = true
                }
                DispatchQueue.main.async {
                    if !spaceIds.isEmpty {
                        self.refreshList()
                    }
                }
            case .failure(_):
                break
            @unknown default:
                break
            }
        })
    }
}

extension MessagingSpacesViewController {
    // MARK: UITableViewDatasource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SpaceTableViewCell.reuseIdentifier, for: indexPath) as? SpaceTableViewCell else {
            return UITableViewCell()
        }
        let spaceItem = listItems[indexPath.row]
        switch spaceItem {
        case .space(let space):
            var onCall = false
            guard let spaceId = space.id else { return UITableViewCell() }
            if self.onGoingSpaceCalls[spaceId] != nil {
                onCall = true
            }
            var presence: Presence?
            if let spaceId = space.id, let presenceForSpaceId = spaceIdPresenceDict[spaceId] {
                presence = presenceForSpaceId
            }
            cell.setupCell(name: space.title, description: space.displayValue, isOnCall: onCall, presence: presence) { [weak self] in
                guard let self = self, let spaceId = space.id else { return }
                self.sendMessageToSpace(spaceId: spaceId)
            }
        case .readStatus(let readStatus):
            cell.setupCell(name: "Space Read Status", description: readStatus.displayValue, isOnCall: false, presence: nil)
        }
        
        return cell
    }
}

extension MessagingSpacesViewController {
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let spaceItem = listItems[indexPath.row]
        let alertController = UIAlertController.actionSheetWith(title: "Space Actions", message: nil, sourceView: self.view)
        
        alertController.addAction(.dismissAction(withTitle: "Cancel"))
        
        if let spaceId = spaceIdFrom(spaceItem: spaceItem) {
            alertController.addAction(UIAlertAction(title: "Fetch Space by Id", style: .default) { [weak self] _ in
                self?.fetchSpace(byId: spaceId)
            })
            alertController.addAction(UIAlertAction(title: "Get Space Meeting Info", style: .default) { [weak self] _ in
                self?.fetchMeetingInfo(byId: spaceId)
            })
            
            alertController.addAction(UIAlertAction(title: "Fetch Space Read Status", style: .default) { [weak self] _ in
                self?.fetchSpaceReadStatus(byId: spaceId)
            })
            
            alertController.addAction(UIAlertAction(title: "Show Messages in Space", style: .default) { [weak self] _ in
                webex.people.getMe { result in
                    switch result {
                    case .success(let person):
                        self?.selfPersonId = person.id
                    case .failure:
                        break
                    @unknown default:
                        break
                    }
                    
                    let spaceMessagesTableVC = SpaceMessagesTableViewController(spaceId: spaceId)
                    spaceMessagesTableVC.selfPersonId = self?.selfPersonId
                    
                    self?.navigationController?.pushViewController(spaceMessagesTableVC, animated: true)
                }
            })
            
            alertController.addAction(UIAlertAction(title: "Show Space Members", style: .default) { [weak self] _ in
                self?.navigationController?.pushViewController(SpaceMembershipViewController(spaceId: spaceId), animated: true)
            })
            
            alertController.addAction(UIAlertAction(title: "Show Space Memberships with Read Status", style: .default) { [weak self] _ in
                self?.navigationController?.pushViewController(SpaceMembershipReadStatusViewController(spaceId: spaceId), animated: true)
            })
            
            alertController.addAction(UIAlertAction(title: "Update Space Title", style: .default) { [weak self] _ in
                self?.showUpdateSpaceNameAlert(spaceId: spaceId, title: self?.getSpaceNameFrom(spaceItem: spaceItem))
            })
            
            alertController.addAction(UIAlertAction(title: "Delete Space", style: .default) { [weak self] _ in
                self?.deleteSpace(byId: spaceId, withTitle: self?.getSpaceNameFrom(spaceItem: spaceItem))
            })
            
            alertController.addAction(UIAlertAction(title: "Mark Space Read", style: .default) { [weak self] _ in
                self?.markSpaceAsRead(spaceId)
            })
        }
        
        present(alertController, animated: true) { [weak tableView] in
            tableView?.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension MessagingSpacesViewController: NavigationItemSetupProtocol {
    // MARK: NavigationItemSetupProtocol functions
    var rightBarButtonItems: [UIBarButtonItem]? {
        let filterSpacesButton = UIBarButtonItem(image: UIImage(named: "slider-horizontal-3"), style: .plain, target: self, action: #selector(showFilterSheet))
        filterSpacesButton.accessibilityIdentifier = "FilterSpaces"
        return [filterSpacesButton, UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addSpace))]
    }
}

extension MessagingSpacesViewController: FilterSpacesDelegate {
    // MARK: FilterSpacesDelegate
    func didUpdateListParameters(teamId: String?, maxNumberOfSpaces: Int?, spaceType: SpaceType?, sortType: SpaceSortType?, spaceValueType: SpaceValue) {
        spaceValue = spaceValueType
        switch spaceValue {
        case .space:
            webex.spaces.list(teamId: teamId, max: maxNumberOfSpaces, type: spaceType, sortBy: sortType, queue: nil) { [weak self] in
                switch $0 {
                case .failure(let error):
                    DispatchQueue.main.sync {
                        let alert = UIAlertController(title: "Error listing spaces", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(.dismissAction(withTitle: "Ok"))
                        self?.present(alert, animated: true)
                    }
                case .success(let spaces):
                    self?.listItems = (spaces ?? []).map { .space($0) }
                    let directSpaces = spaces.filter( {$0.type == .direct} )
                    self?.directSpaceIds = directSpaces.map { $0.id ?? "" }
                }
            }
            
        case .readStatus:
            webex.spaces.listWithReadStatus(max: 20, queue: DispatchQueue.global(qos: .default)) { [weak self] in
                switch $0 {
                case .failure(let error):
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Error listing spaces with read status", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(.dismissAction(withTitle: "Ok"))
                        self?.present(alert, animated: true)
                    }
                    
                case .success(let listspaces):
                    self?.listItems = (listspaces ?? []).map { return .readStatus($0) }
                }
            }
        }
    }
}
extension WebexSDK.Space {
    var displayValue: String {
        "Space Id: \(id ?? "--"),\nTeam Id: \(teamId ?? "--"),\nSpace Type: \(type?.rawValue ?? "--"),\nCreated Date: \(created?.description ?? "--"),\nLast Activity: \(lastActivityTimestamp?.description ?? "--")"
    }
}

extension SpaceMeetingInfo {
    var displayValue: String {
        "Space Id: \(spaceId ?? "--")\n Meeting Link: \(meetingLink ?? "--")\n SIP Address: \(sipAddress ?? "")\n Meeting Number: \(meetingNumber ?? "--")\n Call In Toll Free Number: \(callInTollFreeNumber ?? "--")\n Call In Toll Number: \(callInTollNumber ?? "--")"
    }
}

extension SpaceReadStatus {
    var displayValue: String {
        "Space Id: \(id ?? "--"),\nSpace Type: \(type?.rawValue ?? "--"),\nLast Activity: \(lastActivityDate?.description ?? "--"), \nLast Seen Activity: \(lastSeenActivityDate?.description ?? "--")"
    }
}

extension MessagingSpacesViewController {
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
                        if let spacceId = spaceId, self.spaceIdPresenceDict[spacceId]?.status != presence.status {
                            self.spaceIdPresenceDict[spacceId] = presence
                            for i in 0..<self.listItems.count {
                                switch self.listItems[i] {
                                case .space(let space):
                                    if space.id == spaceId {
                                        DispatchQueue.main.async {
                                            self.tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .none)
                                        }
                                    }
                                case .readStatus(_):
                                    continue
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


