import Foundation
import WebexSDK

class WebexMembership {
    /// Lists all the memberships.
    func listMemberships(spaceId: String? = nil, personId: String? = nil, personEmail: EmailAddress? = nil, queue: DispatchQueue?, completion: @escaping (WebexSDK.Result<[WebexSDK.Membership]>) -> Void) {
        if let personId = personId, let spaceId = spaceId {
            webex.memberships.list(spaceId: spaceId, personId: personId, queue: queue, completionHandler: completion)
        } else if let spaceId = spaceId , let personEmail = personEmail {
            webex.memberships.list(spaceId: spaceId, personEmail: personEmail, queue: queue, completionHandler: completion)
        } else if let spaceId {
            webex.memberships.list(spaceId: spaceId, queue: queue, completionHandler: completion)
        }
    }
    
    /// Lists all the memberships with their read status.
    func listWithReadStatus(spaceId: String, completion: @escaping (WebexSDK.Result<[WebexSDK.MembershipReadStatus]>) -> Void) {
        webex.memberships.listWithReadStatus(spaceId: spaceId, completionHandler: completion)
    }
    
    /// Fetches a membership by its identifier.
    func fetchMembershipById(membershipId: String,completion: @escaping (Result<Membership>) -> Void) {
        webex.memberships.get(membershipId: membershipId, completionHandler: completion)
    }
    
    /// Sets a user as a moderator.
    func setModerator(membershipId: String, isModerator: Bool, completion:@escaping (Result<Membership>) -> Void) {
        webex.memberships.update(membershipId: membershipId, isModerator: isModerator, completionHandler: completion)
    }
    
    /// Creates a team membership.
    func createTeamMembership(withPersonId id: String, spaceId: String, personDisplayName: String, completion: @escaping (Result<Membership>) -> Void) {
        webex.memberships.create(spaceId: spaceId, personId: id, completionHandler: completion)
    }
    
    /// Adds a membership.
    func addTeamMembership(withEmail email: EmailAddress, spaceId: String, personDisplayName: String, completion: @escaping (Result<Membership>) -> Void) {
        webex.memberships.create(spaceId: spaceId, personEmail: email, completionHandler: completion)
    }
    
    /// Deletes a membership.
    func deleteMembership(membershipId: String, completion: @escaping (Result<Void>) -> Void) {
        webex.memberships.delete(membershipId: membershipId, completionHandler: completion)
    }
}
