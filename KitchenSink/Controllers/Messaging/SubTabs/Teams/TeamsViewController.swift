import UIKit
import WebexSDK

final class TeamsViewController: BasicTableViewController<Team, ContactTableViewCell> {
    init() {
        super.init(placeholderText: "No Teams")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func refreshList() {
        webex.teams.list(max: 100, queue: DispatchQueue.global(qos: .default)) { [weak self] teams in
            DispatchQueue.main.async {
                switch teams {
                case .success(let teams):
                    self?.listItems = teams.filter { !$0.isDeleted }
                case .failure(let error):
                        let alert = UIAlertController(title: "Error listing teams", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(.dismissAction(withTitle: "Ok"))
                        self?.present(alert, animated: true)
                }
            }
        }
    }
}

extension TeamsViewController {
    // MARK: Private Methods
    private func showCreateSpaceAlert(teamId: String) {
        let alertController = UIAlertController.createWithTextField(title: "Add Space", message: "Enter the name of the new Space", style: .alert)
        alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            guard let title = alertController.textFields?.first?.text else { return }
            alertController.dismiss(animated: true)
            webex.spaces.create(title: title, teamId: teamId, queue: nil) { [weak self] result in
                DispatchQueue.main.async {
                    let dismissAction = UIAlertAction.dismissAction(withTitle: "Dismiss")
                    switch result {
                    case .success(let space):
                        let successAlert = UIAlertController(title: "Success", message: "New Space titled: \(space.title ?? "") added", preferredStyle: .alert)
                        successAlert.addAction(dismissAction)
                        self?.present(successAlert, animated: true)
                    case .failure(let error):
                        let failureAlert = UIAlertController(title: "Error creating space", message: error.localizedDescription, preferredStyle: .alert)
                        failureAlert.addAction(dismissAction)
                        self?.present(failureAlert, animated: true)
                    }
                }
            }
        })
        
        present(alertController, animated: true)
    }
    
    private func fetchTeam(byId id: String) {
        webex.teams.get(teamId: id, queue: DispatchQueue.global(qos: .background)) { [weak self] result in
            DispatchQueue.main.async {
                let dismissAction = UIAlertAction.dismissAction(withTitle: "Dismiss")
                if let team = result.data {
                    let alertController = UIAlertController(title: "Team Found", message: team.displayValue, preferredStyle: .alert)
                    alertController.addAction(dismissAction)
                    self?.present(alertController, animated: true)
                } else {
                    let alertController = UIAlertController(title: "Error Fetching Team", message: "No team found with given id", preferredStyle: .alert)
                    alertController.addAction(dismissAction)
                    self?.present(alertController, animated: true)
                }
            }
        }
    }
    
    private func showUpdateTeamNameAlert(teamId: String, name: String?) {
        let alertController = UIAlertController.createWithTextField(title: "Update Team Name", message: "Enter the new name of the Team", style: .alert)
        if let name = name {
            alertController.textFields?.first?.text = name
        }
        alertController.addAction(UIAlertAction(title: "Update", style: .default) { _ in
            guard let name = alertController.textFields?.first?.text else { return }
            alertController.dismiss(animated: true) {
                webex.teams.update(teamId: teamId, name: name, queue: nil) { [weak self] result in
                    self?.refreshList()
                    let (title, message) = { () -> (String, String) in
                        switch result {
                        case .success(let team):
                            return ("Success", "Team's new name: \(team.name ?? "")")
                        case .failure(let error):
                            return ("Failure", "Team update failure.\n\(error)")
                        }
                    }()
                    let successController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    successController.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
                    self?.present(successController, animated: true)
                }
            }
        })
        
        present(alertController, animated: true)
    }
    
    @objc private func addTeam() {
        let alertController = UIAlertController.createWithTextField(title: "Add Team", message: "Enter the name of the new Team", style: .alert)
        alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            guard let teamName = alertController.textFields?.first?.text else { return }
            webex.teams.create(name: teamName) { [weak self] result in
                let message: String = {
                    switch result {
                    case .success:
                        return "Created new team: \(teamName)"
                    case .failure:
                        return "Failed to create new team: \(teamName)"
                    }
                }()
                
                self?.refreshList()
                
                let alertController = UIAlertController(title: "Create Team", message: message, preferredStyle: .alert)
                alertController.addAction(.dismissAction(withTitle: "Ok"))
                DispatchQueue.main.async {
                    self?.present(alertController, animated: true)
                }
            }
        })
        present(alertController, animated: true)
    }
    
    private func showDeleteTeamConfirmationAlert(teamId: String) {
        let alertController = UIAlertController(title: "Please Confirm", message: "This action will delete the Team", preferredStyle: .alert)
        alertController.addAction(UIAlertAction.dismissAction())
        alertController.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            alertController.dismiss(animated: true) {
                webex.teams.delete(teamId: teamId, queue: nil) { [weak self] result in
                    self?.refreshList()
                    let (title, message) = { () -> (String, String) in
                        switch result {
                        case .success:
                            return ("Success", "Team has been deleted")
                        case .failure(let error):
                            return ("Failure", "Team deletion failure \n \(error)")
                        }
                    }()
                    let successController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    successController.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
                    self?.present(successController, animated: true)
                }
            }
        })
        
        present(alertController, animated: true)
    }
}

extension TeamsViewController {
    // MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.reuseIdentifier, for: indexPath) as? ContactTableViewCell else {
            return UITableViewCell()
        }
        let team = listItems[indexPath.row]
        cell.setupCell(name: team.name, description: team.displayValue)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let teamId = listItems[indexPath.row].id {
                showDeleteTeamConfirmationAlert(teamId: teamId)
            }
        }
    }
}

extension TeamsViewController {
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let alertController = UIAlertController(title: "Team Actions", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Add Space to Team", style: .default) { [weak self] _ in
            guard let teamId = self?.listItems[indexPath.row].id else { return }
            self?.showCreateSpaceAlert(teamId: teamId)
        })
        
        if let teamId = listItems[indexPath.row].id {
            alertController.addAction(UIAlertAction(title: "Fetch Team by Id", style: .default) { [weak self] _ in
                self?.fetchTeam(byId: teamId)
            })
            
            alertController.addAction(UIAlertAction(title: "Update Team Name", style: .default) { [weak self] _ in
                self?.showUpdateTeamNameAlert(teamId: teamId, name: self?.listItems[indexPath.row].name)
            })
            
            alertController.addAction(UIAlertAction(title: "Show Team Members", style: .default) { [weak self] _ in
                self?.navigationController?.pushViewController(TeamMembershipViewController(teamId: teamId), animated: true)
            })
        }
        
        alertController.addAction(.dismissAction())
        
        present(alertController, animated: true)
    }
}

extension TeamsViewController: NavigationItemSetupProtocol {
    // MARK: NavigationItemSetupProtocol functions
    var rightBarButtonItems: [UIBarButtonItem]? {
        return [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTeam))]
    }
}

extension Team {
    var displayValue: String {
        "Team Id: \(id ?? "--"),\nCreated Date: \(created?.description ?? "--")\n"
    }
}
