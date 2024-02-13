import SwiftUI
import WebexSDK

@available(iOS 16.0, *)
/// A structure representing a team membership.
struct TeamMembershipKS: Identifiable {
    var id: String?
    var teamId: String?
    var personId: String?
    var personEmail: EmailAddress?
    var isModerator: Bool?
    var personDisplayName: String?
    var created: Date?
    var personOrgId: String?
    
    ///constructs a `TeamMembershipKS` instance from a `WebexSDK.TeamMembership` object.
    static func buildFrom(teamMembership: WebexSDK.TeamMembership) -> Self {
        return TeamMembershipKS(id: teamMembership.id, teamId: teamMembership.teamId, personId: teamMembership.personId, personEmail: teamMembership.personEmail, isModerator: teamMembership.isModerator, personDisplayName: teamMembership.personDisplayName, created: teamMembership.created, personOrgId: teamMembership.personOrgId)
        }

}

@available(iOS 16.0, *)
/// A structure representing a person.
struct PersonKS: Identifiable {
    var id: String?
    var emails:[EmailAddress]?
    var displayName:String?
    
    ///constructs a `PersonKS` instance from a `WebexSDK.Person` object.
    static func buildFrom(person: WebexSDK.Person) -> Self {
        return PersonKS(id: person.id, emails: person.emails, displayName: person.displayName)
    }
}

@available(iOS 16.0, *)
/// A structure representing a person data.
struct PersonDataKS: Identifiable {
    var id: String
    var personName: String
    
    ///constructs a `PersonDataKS` instance from a `WebexSDK.PersonData` object.
    static func buildFrom(personData: PersonData) -> Self {
        return PersonDataKS(id: personData.personId, personName: personData.personName)
    }
}
