import UIKit
import WebexSDK

protocol SpaceMembershipViewControllerDelegate: AnyObject {
    func spaceMembershipViewControllerDidSelectMembership(membership: Membership)
}

final class SpaceMembershipViewController: BasicTableViewController<Membership, ContactTableViewCell> {
    weak var delegate: SpaceMembershipViewControllerDelegate?
    private let spaceId: String?
    private let personId: String?
    private let personEmail: EmailAddress?
    
    init(spaceId: String? = nil, personId: String? = nil, personEmail: EmailAddress? = nil) {
        self.spaceId = spaceId
        self.personId = personId
        self.personEmail = personEmail
        super.init(placeholderText: "No Members in Space")
        tableView.accessibilityIdentifier = "SpaceMembershipTableView"
        title = "Space Membership"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMemberTapped))
        registerMembershipCallBack()
        registerMembershipCallBackWithPayload()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func refreshList() {
        guard let spaceId = spaceId else {
            webex.memberships.list(max: nil, queue: .global(qos: .default)) { [weak self] in
                switch $0 {
                case .success(let memberships):
                    self?.listItems = memberships
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            return
        }
        
        if let personId = personId {
            webex.memberships.list(spaceId: spaceId, personId: personId, queue: DispatchQueue.global(qos: .background)) { [weak self] in
                switch $0 {
                case .success(let memberships):
                    self?.listItems = memberships
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        } else if let personEmail = personEmail {
            webex.memberships.list(spaceId: spaceId, personEmail: personEmail, queue: DispatchQueue.global(qos: .background)) { [weak self] in
                switch $0 {
                case .success(let memberships):
                    self?.listItems = memberships
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        } else {
            webex.memberships.list(spaceId: spaceId, max: nil, queue: DispatchQueue.global(qos: .background)) { [weak self] in
                self?.listItems = $0.data ?? []
            }
        }
    }
}

extension SpaceMembershipViewController {
    // MARK: Private Methods
    private func fetchMembership(byId id: String) {
        webex.memberships.get(membershipId: id, queue: .global(qos: .default)) { result in
            let message: String = {
                switch result {
                case .success(let membership):
                    return membership.displayValue
                case .failure:
                    return "Failed to get Membership"
                }
            }()
            
            let alertController = UIAlertController(title: "Fetch Membership", message: message, preferredStyle: .alert)
            alertController.addAction(.dismissAction())
            DispatchQueue.main.async { [weak self] in
                self?.present(alertController, animated: true)
            }
        }
    }
    
    private func updateMembership(_ membership: Membership, isModerator: Bool) {
        guard let membershipId = membership.id else { return }
        webex.memberships.update(membershipId: membershipId, isModerator: isModerator) { result in
            let message: String = {
                switch result {
                case .success(let membership):
                    return membership.displayValue
                case .failure:
                    return "Failed to set moderator."
                }
            }()
            
            let alertController = UIAlertController(title: "Set Moderator", message: message, preferredStyle: .alert)
            alertController.addAction(.dismissAction())
            DispatchQueue.main.async { [weak self] in
                self?.present(alertController, animated: true)
            }
        }
    }
    
    private func buildSetModeratorAction(membership: Membership) -> UIAlertAction {
        let isModerator = (membership.isModerator ?? false)
        let title = isModerator ? "Remove Moderator" : "Set Moderator"
        return UIAlertAction(title: title, style: .default) { [weak self] _ in
            self?.updateMembership(membership, isModerator: !isModerator)
        }
    }
    
    private func showDeleteMembershipConfirmationAlert(membershipId: String) {
        let alertController = UIAlertController(title: "Please Confirm", message: "This action will delete the Membership", preferredStyle: .alert)
        alertController.addAction(UIAlertAction.dismissAction())
        alertController.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            alertController.dismiss(animated: true) {
                webex.memberships.delete(membershipId: membershipId, queue: DispatchQueue.global(qos: .default)) { [weak self] result in
                    self?.refreshList()
                    let (title, message) = { () -> (String, String) in
                        switch result {
                        case .success:
                            return ("Success", "Membership has been deleted")
                        case .failure(let error):
                            return ("Failure", "Membership deletion failure \n \(error)")
                        }
                    }()
                    let successController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    successController.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
                    DispatchQueue.main.async {
                        self?.present(successController, animated: true)
                    }
                }
            }
        })
        
        present(alertController, animated: true)
    }
    
    private func createMembershipWithId(_ personId: String, spaceId: String, personDisplayName: String) {
        webex.memberships.create(spaceId: spaceId, personId: personId, queue: .global(qos: .default)) { [weak self] result in
            let message: String = {
                switch result {
                case .success:
                    return "\(personDisplayName) added to \(spaceId)"
                case .failure:
                    return "Failed to add \(personDisplayName)"
                }
            }()
            let alertController = UIAlertController(title: "Create Membership", message: message, preferredStyle: .alert)
            alertController.addAction(.dismissAction())
            DispatchQueue.main.async {
                self?.present(alertController, animated: true)
                self?.refreshList()
            }
        }
    }
    
    private func createMembershipWithEmail(_ email: EmailAddress, spaceId: String, personDisplayName: String) {
        webex.memberships.create(spaceId: spaceId, personEmail: email, queue: .global(qos: .default)) { [weak self] result in
            let message: String = {
                switch result {
                case .success:
                    return "\(personDisplayName) added to \(spaceId)"
                case .failure:
                    return "Failed to add \(personDisplayName)"
                }
            }()
            let alertController = UIAlertController(title: "Create Membership", message: message, preferredStyle: .alert)
            alertController.addAction(.dismissAction())
            DispatchQueue.main.async {
                self?.present(alertController, animated: true)
                self?.refreshList()
            }
        }
    }
    
    @objc private func addMemberTapped() {
        let vc = ContactSearchViewController()
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func registerMembershipCallBack() {
        webex.memberships.onEvent = { event in
            switch event {
            case .created:
                break
            case .deleted:
                break
            case .update:
                break
            case .messageSeen:
                break
            @unknown default:
                break
            }
        }
    }
    
    func registerMembershipCallBackWithPayload() {
        webex.memberships.onEventWithPayload = { [self] event, id in
            print(id)
            switch event {
            case .created:
                self.refreshList()
            case .deleted:
                self.refreshList()
            case .update:
                self.refreshList()
            case .messageSeen:
                break
            @unknown default:
                self.refreshList()
            }
        }
    }
}

extension SpaceMembershipViewController {
    // MARK: UITableViewDatasource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.reuseIdentifier, for: indexPath) as? ContactTableViewCell else {
            return UITableViewCell()
        }
        let membership = listItems[indexPath.row]
        cell.setupCell(name: "Display Name: \(membership.personDisplayName.valueOrEmpty)", description: "Space ID: \(membership.spaceId.valueOrEmpty)\nEmail: \((membership.personEmail?.toString()).valueOrEmpty)")
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let membershipId = listItems[indexPath.row].id {
                showDeleteMembershipConfirmationAlert(membershipId: membershipId)
            }
        }
    }
}

extension SpaceMembershipViewController {
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard delegate == nil else {
            delegate?.spaceMembershipViewControllerDidSelectMembership(membership: listItems[indexPath.row])
            return
        }
        
        guard let membershipId = listItems[indexPath.row].id, self.personEmail == nil && self.personId == nil else { tableView.deselectRow(at: indexPath, animated: true); return }
        
        let membership = listItems[indexPath.row]
        let alertController = UIAlertController(title: "Membership Actions", message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Fetch Membership by ID", style: .default) { [weak self] _ in
            self?.fetchMembership(byId: membershipId)
        })
        if let spaceId = membership.spaceId, let personId = membership.personId {
            alertController.addAction(UIAlertAction(title: "Show All Memberships For This Space and PersonId", style: .default) { [weak self] _ in
                self?.present(SpaceMembershipViewController(spaceId: spaceId, personId: personId), animated: true)
            })
        }
        if let spaceId = membership.spaceId, let personEmail = membership.personEmail {
            alertController.addAction(UIAlertAction(title: "Show All Memberships For This Space and PersonEmail", style: .default) { [weak self] _ in
                self?.present(SpaceMembershipViewController(spaceId: spaceId, personEmail: personEmail), animated: true)
            })
        }
        alertController.addAction(buildSetModeratorAction(membership: membership))
        alertController.addAction(.dismissAction())
        
        present(alertController, animated: true) { [weak tableView] in
            tableView?.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension SpaceMembershipViewController: NavigationItemSetupProtocol {
    // MARK: NavigationItemSetupProtocol
    var rightBarButtonItems: [UIBarButtonItem]? {
        return [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMemberTapped))]
    }
}

extension SpaceMembershipViewController: ContactSearchViewControllerDelegate {
    // MARK: ContactSearchViewControllerDelegate
    func contactSelected(person: Person) {
        navigationController?.popViewController(animated: true)
        guard let spaceId = spaceId,
            let personId = person.id,
            let emailAddress = person.emails?.first else { return }
        let personDisplayName = person.displayName.valueOrEmpty
        let alertController = UIAlertController(title: "Add Membership", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "By Person Id", style: .default) { [weak self] _ in
            self?.createMembershipWithId(personId, spaceId: spaceId, personDisplayName: personDisplayName)
        })
        
        alertController.addAction(UIAlertAction(title: "By Email Address", style: .default) { [weak self] _ in
            self?.createMembershipWithEmail(emailAddress, spaceId: spaceId, personDisplayName: personDisplayName)
        })
        
        alertController.addAction(.dismissAction())
        
        present(alertController, animated: true)
    }
}

extension Membership {
    var displayValue: String {
        return "Membership ID: \(id.valueOrEmpty)\n Person ID: \(personId.valueOrEmpty)\n Email Address: \((personEmail?.toString()).valueOrEmpty)\n Space ID: \(spaceId.valueOrEmpty)\n Moderator: \(String(isModerator ?? false))\n Display Name: \(personDisplayName.valueOrEmpty)"
    }
}
