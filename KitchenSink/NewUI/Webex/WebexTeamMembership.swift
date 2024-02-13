import Foundation
import WebexSDK

@available(iOS 16.0, *)
class WebexTeamMembership {
    /// Lists all the team memberships for the specified team ID.
    func listMemberships(teamId: String, completion: @escaping (Result<[TeamMembershipKS]?>) -> Void) {
        webex.teamMemberships.list(teamId: teamId , completionHandler:  { result in
            switch result {
            case .success(let memberships):
                var teamMemberships: [TeamMembershipKS] = []
                for membership in memberships {
                    teamMemberships.append(TeamMembershipKS.buildFrom(teamMembership: membership))
                    completion(.success(teamMemberships))
                }
            case .failure(let err):
                completion(.failure(err))
            @unknown default:
                break
            }
        })
    }
    
    /// Fetches a specific team membership by its ID.
    func fetchTeamMemberShip(byId Id: String, completion:@escaping (String) -> Void) {
        webex.teamMemberships.get(membershipId: Id) { result in
            switch result {
            case .success(let teamMembership):
                completion(teamMembership.displayValue)
            case .failure(let error):
                completion("Failed to get TeamMembership. \(error)")
            @unknown default:
                break
            }
        }
    }
    
    /// Sets a team member as a moderator.
    func setModerator(teamMembershipId: String, isModerator: Bool, completion:@escaping (String) -> Void) {
        webex.teamMemberships.update(membershipId: teamMembershipId, isModerator: isModerator) { result in
            switch result {
            case .success(let teamMembership):
                completion(teamMembership.displayValue)
            case .failure(let error):
                let operation = isModerator ? "Set" : "Remove"
                completion("Failed to \(operation) moderator. \(error.localizedDescription)")
            @unknown default:
                break
            }
        }
    }
    
    /// Updates the name of a specific team.
    func updateTeamName(teamId: String, title: String, completion: @escaping (String, String) -> Void) {
        webex.teams.update(teamId: teamId, name: title) { result in
            switch result {
            case .success(let team):
                completion("Success", "Team's new name: \(team.name ?? "")")
            case .failure(let error):
                completion("Failure", "Team update failure.\n\(error)")
            @unknown default:
                break
            }
        }
    }
    
    /// Fetches a specific team by its ID.
    func fetchTeamById(teamId: String, completion: @escaping (String, String) -> Void) {
        webex.teams.get(teamId: teamId) { result in
            switch result {
            case .success(let team):
                completion("Team Found",team.displayValue)
            case .failure(_):
                completion("Error Fetching Team", "No team found with given id")
            @unknown default:
                break
            }
        }
    }
    
    /// Creates a team membership for a specific person in a specified team.
    func createTeamMembership(withPersonId id: String, teamId: String, personDisplayName: String, completion: @escaping (String, String) -> Void) {
        webex.teamMemberships.create(teamId: teamId, personId: id) { result in
            switch result {
            case .success:
                completion("Success", "\(personDisplayName) added to \(teamId)")
            case .failure:
                completion("Failure", "Failed to add \(personDisplayName)")
            @unknown default:
                break
            }

        }
    }
    
    /// Adds a person to a specified team based on their email.
    func addTeamMembership(withEmail email: EmailAddress, teamId: String, personDisplayName: String, completion: @escaping (String, String) -> Void) {
        webex.teamMemberships.create(teamId: teamId, personEmail: email) { result in
            switch result {
            case .success:
                completion("Success", "\(personDisplayName) added to \(teamId)")
            case .failure:
                completion("Failure", "Failed to add \(personDisplayName)")
            @unknown default:
                break
            }

        }
    }
}
