import UIKit
import WebexSDK

final class TeamMembershipViewController: BasicTableViewController<TeamMembership, ContactTableViewCell> {
    private let teamId: String
    
    init(teamId: String) {
        self.teamId = teamId
        super.init(placeholderText: "No Members in Team")
        tableView.accessibilityIdentifier = "TeamMembershipTableView"
        title = "Team Membership"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))]
        navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: true)
    }
    
    override func refreshList() {
        webex.teamMemberships.list(teamId: teamId, max: nil, queue: DispatchQueue.global(qos: .background)) { [weak self] in
            self?.listItems = $0.data ?? []
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
}

extension TeamMembershipViewController {
    // MARK: Private Methods
    private func fetchTeamMembership(byId id: String) {
        webex.teamMemberships.get(membershipId: id, queue: .global(qos: .default)) { result in
            let message: String = {
                switch result {
                case .success(let teamMembership):
                    return teamMembership.displayValue
                case .failure(let error):
                    return "Failed to get TeamMembership. \(error)"
                }
            }()
            
            let alertController = UIAlertController(title: "Fetch Team Membership", message: message, preferredStyle: .alert)
            alertController.addAction(.dismissAction())
            DispatchQueue.main.async { [weak self] in
                self?.present(alertController, animated: true)
            }
        }
    }
    
    private func updateTeamMembership(_ teamMembership: TeamMembership, isModerator: Bool) {
        guard let teamMembershipId = teamMembership.id else { return }
        webex.teamMemberships.update(membershipId: teamMembershipId, isModerator: isModerator, queue: .global(qos: .default)) { [weak self] result in
            let operation = isModerator ? "Set" : "Remove"
            let message: String = {
                switch result {
                case .success(let teamMembership):
                    return teamMembership.displayValue
                case .failure(let error):
                    return "Failed to \(operation) moderator. \(error)"
                }
            }()
            
            self?.refreshList()
            
            let alertController = UIAlertController(title: "\(operation) Moderator", message: message, preferredStyle: .alert)
            alertController.addAction(.dismissAction())
            DispatchQueue.main.async { [weak self] in
                self?.present(alertController, animated: true)
            }
        }
    }
    
    private func buildSetModeratorAction(teamMembership: TeamMembership) -> UIAlertAction {
        let isModerator = (teamMembership.isModerator ?? false)
        let title = isModerator ? "Remove Moderator" : "Set Moderator"
        return UIAlertAction(title: title, style: .default) { [weak self] _ in
            self?.updateTeamMembership(teamMembership, isModerator: !isModerator)
        }
    }
    
    @objc private func addButtonTapped() {
        let contactSearchViewController = ContactSearchViewController()
        contactSearchViewController.delegate = self
        self.navigationController?.pushViewController(contactSearchViewController, animated: true)
    }
    
    private func showDeleteTeamMembershipConfirmationAlert(teamMembershipId: String) {
        let alertController = UIAlertController(title: "Please Confirm", message: "This action will delete the Team Membership", preferredStyle: .alert)
        alertController.addAction(UIAlertAction.dismissAction())
        alertController.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            alertController.dismiss(animated: true) {
                webex.teamMemberships.delete(membershipId: teamMembershipId, queue: DispatchQueue.global(qos: .default)) { [weak self] result in
                    self?.refreshList()
                    let (title, message) = { () -> (String, String) in
                        switch result {
                        case .success:
                            return ("Success", "Team Membership has been deleted")
                        case .failure(let error):
                            return ("Failure", "Team Membership deletion failure \n \(error)")
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
    
    private func createTeamMembershipWithId(_ personId: String, teamId: String, personDisplayName: String) {
        webex.teamMemberships.create(teamId: teamId, personId: personId, queue: .global(qos: .default)) { [weak self] result in
            let message: String = {
                switch result {
                case .success:
                    return "\(personDisplayName) added to \(teamId)"
                case .failure:
                    return "Failed to add \(personDisplayName)"
                }
            }()
            
            self?.refreshList()
            
            let alertController = UIAlertController(title: "Create Team Membership", message: message, preferredStyle: .alert)
            alertController.addAction(.dismissAction())
            DispatchQueue.main.async {
                self?.present(alertController, animated: true)
            }
        }
    }
    
    private func createTeamMembershipWithEmail(_ email: EmailAddress, teamId: String, personDisplayName: String) {
        webex.teamMemberships.create(teamId: teamId, personEmail: email, queue: .global(qos: .default)) { [weak self] result in
            let message: String = {
                switch result {
                case .success:
                    return "\(personDisplayName) added to \(teamId)"
                case .failure:
                    return "Failed to add \(personDisplayName)"
                }
            }()
            
            self?.refreshList()
            
            let alertController = UIAlertController(title: "Create Team Membership", message: message, preferredStyle: .alert)
            alertController.addAction(.dismissAction())
            DispatchQueue.main.async {
                self?.present(alertController, animated: true)
            }
        }
    }
}

extension TeamMembershipViewController {
    // MARK: UITableViewDatasource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.reuseIdentifier, for: indexPath) as? ContactTableViewCell else {
            return UITableViewCell()
        }
        let teamMembership = listItems[indexPath.row]
        cell.setupCell(name: "Display Name: \(teamMembership.personDisplayName ?? "--")", description: "Email: \(teamMembership.personEmail?.toString() ?? "")")
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let teamMembershipId = listItems[indexPath.row].id {
                showDeleteTeamMembershipConfirmationAlert(teamMembershipId: teamMembershipId)
            }
        }
    }
}

extension TeamMembershipViewController {
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let membershipId = listItems[indexPath.row].id else { tableView.deselectRow(at: indexPath, animated: true); return }
        
        let teamMembership = listItems[indexPath.row]
        
        let alertController = UIAlertController.actionSheetWith(title: "Membership Actions", message: nil, sourceView: self.view)
        
        alertController.addAction(UIAlertAction(title: "Fetch Team Membership by ID", style: .default) { [weak self] _ in
            self?.fetchTeamMembership(byId: membershipId)
        })
        
        alertController.addAction(buildSetModeratorAction(teamMembership: teamMembership))
        alertController.addAction(.dismissAction())
        
        present(alertController, animated: true) { [weak tableView] in
            tableView?.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension TeamMembershipViewController: ContactSearchViewControllerDelegate {
    func contactSelected(person: Person) {
        navigationController?.popViewController(animated: true)
        guard let personId = person.id, let emailAddress = person.emails?.first else { return }
        
        let personDisplayName = person.displayName.valueOrEmpty
        let alertController = UIAlertController.actionSheetWith(title: "Add Team Membership", message: nil, sourceView: self.view)
        alertController.addAction(UIAlertAction(title: "By Person Id", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.createTeamMembershipWithId(personId, teamId: self.teamId, personDisplayName: personDisplayName)
        })
        
        alertController.addAction(UIAlertAction(title: "By Email Address", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.createTeamMembershipWithEmail(emailAddress, teamId: self.teamId, personDisplayName: personDisplayName)
        })

        alertController.addAction(.dismissAction())
        
        present(alertController, animated: true)
    }
}

extension TeamMembership {
    var displayValue: String {
        return "Team Membership ID: \(id.valueOrEmpty)\n Person ID: \(personId.valueOrEmpty)\n Email Address: \((personEmail?.toString()).valueOrEmpty)\n Team ID: \(teamId.valueOrEmpty)\n Moderator: \(String(isModerator ?? false))\n Display Name: \(personDisplayName.valueOrEmpty)"
    }
}
