import SwiftUI
import WebexSDK

@available(iOS 16.0, *)
class TeamSpaceMemberShipViewModel: ObservableObject {
   
    @Published var isLoading = false
    @Published var teamMembershipResults = [TeamMembershipKS]()
    @Published var showError: Bool = false
    @Published var err: String = ""

    let webexTeamMembership = WebexTeamMembership()
    
    /// Fetches a list of team memberships associated with the provided team ID
    func teamMembershipList(byId id: String) {
        showLoading(show: true)
        self.teamMembershipResults = []
        webexTeamMembership.listMemberships(teamId: id) { result in
            switch result {
            case .success(let teamMemberships):
                self.showLoading(show: false)
                guard let teamMemberships = teamMemberships else { return }
                DispatchQueue.main.async {
                    self.teamMembershipResults = teamMemberships
                }
            case .failure(let error):
                self.showLoading(show: false)
                DispatchQueue.main.async {
                    self.showError = true
                    self.err = error.localizedDescription
                }
            @unknown default:
                break
            }
        }
    }
    
    /// Fetches team membership details by ID
    func fetchTeamMemberShip(byId Id: String, completion:@escaping (String) -> Void) {
        showLoading(show: true)
        webexTeamMembership.fetchTeamMemberShip(byId: Id) { result in
            self.showLoading(show: false)
            completion(result)
        }
    }
    
    /// Sets or unsets a team member as a moderator based on the given boolean value
    func setModerator(teamMembershipId: String, isModerator: Bool, completion:@escaping (String) -> Void) {
        showLoading(show: true)
        webexTeamMembership.setModerator(teamMembershipId: teamMembershipId, isModerator: isModerator) { result in
            self.showLoading(show: false)
            completion(result)
        }
    }
    
    /// Updates the name of a team based on the provided team ID and new title
    func updateTeamName(teamId: String, title: String, completion: @escaping (String, String) -> Void) {
        showLoading(show: true)
        webexTeamMembership.updateTeamName(teamId: teamId, title: title) { (title, message) in
            self.showLoading(show: false)
            completion(title,message)
        }
    }
    
    /// Fetches a team by its ID
    func fetchTeamById(teamId: String, completion: @escaping (String, String) -> Void) {
        showLoading(show: true)
        webexTeamMembership.fetchTeamById(teamId: teamId) { title, message in
            self.showLoading(show: false)
            completion(title,message)
        }
    }
    
    //TODO - This will change when models will be updated.
    /// Adds a new space to a team using the provided title and team ID
    func addSpaceToTeam(title:String, teamId: String, completion: @escaping (String, String) -> Void) {
        showLoading(show: true)
        webex.spaces.create(title: title, teamId: teamId) { result in
            switch result {
            case .success(let space):
                self.showLoading(show: false)
                completion("Success","New Space titled: \(space.title ?? "") added")
            case .failure(let error):
                self.showLoading(show: false)
                completion("Error creating space", error.localizedDescription)
            @unknown default:
                break
            }
        }
    }
    
    /// Creates a team membership with a specific person ID, team ID and person display name
    func createTeamMembership(withPersonId id: String, teamId: String, personDisplayName: String, completion: @escaping (String, String) -> Void) {
        showLoading(show: true)
        webexTeamMembership.createTeamMembership(withPersonId: id, teamId: teamId, personDisplayName: personDisplayName) { title, message in
            self.showLoading(show: false)
            completion(title,message)
        }
    }
    
    /// Adds a team membership using a specific email, team ID, and person display name
    func addTeamMembership(withEmail email: EmailAddress, teamId: String, personDisplayName: String, completion: @escaping (String, String) -> Void) {
        showLoading(show: true)
        webexTeamMembership.addTeamMembership(withEmail: email, teamId: teamId, personDisplayName: personDisplayName) { title, message in
            self.showLoading(show: false)
            completion(title,message)
        }
    }

    /// Asynchronously controls the visibility of a loading indicator on the main queue.
    func showLoading(show: Bool) {
        DispatchQueue.main.async {
            self.isLoading = show
        }
    }
}
