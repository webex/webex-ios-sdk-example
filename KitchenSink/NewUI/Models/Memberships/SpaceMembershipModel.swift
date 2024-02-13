import SwiftUI
import WebexSDK

@available(iOS 16.0, *)
/// A structure representing a membership
struct MembershipKS: Identifiable {
    var id: String?
    var personId: String?
    var spaceId: String?
    var created: Date?
    var isModerator: Bool?
    var personDisplayName: String?
    var personEmail: EmailAddress?
    var personOrgId: String?
    
    ///constructs a `MembershipKS` instance from a `WebexSDK.Membership` object.
    static func buildFrom(membership: Membership) -> Self {
        return MembershipKS(id: membership.id, personId: membership.personId, spaceId: membership.spaceId, created: membership.created, isModerator: membership.isModerator, personDisplayName: membership.personDisplayName, personEmail: membership.personEmail, personOrgId: membership.personOrgId)
    }
}

@available(iOS 16.0, *)
/// A structure representing a membership read status.
struct MembershipReadStatusKS: Identifiable {
    var id: String?
    var member: MembershipKS?
    var lastSeenId: String?
    var lastSeenDate: Date?
    
    ///constructs a `MembershipReadStatusKS` instance from a `WebexSDK.MembershipReadStatus` object.
    static func buildFrom(membership: MembershipReadStatus) -> Self {
        return MembershipReadStatusKS(member:MembershipKS.buildFrom(membership: membership.member), lastSeenId: membership.lastSeenId, lastSeenDate: membership.lastSeenDate)
    }
}


@available(iOS 16.0, *)
extension MembershipReadStatusKS {
    /// A property that returns a formatted string containing the details of the member and the last seen date.
    var displayValue: String {
        return "\(member?.displayValue ?? "")\n Last Seen Date:\((lastSeenDate?.description).valueOrEmpty)"
    }
}

@available(iOS 16.0, *)
extension MembershipKS {
    /// A property that returns a formatted string containing the details of the membership.
    var displayValue: String {
        return "Membership ID: \(id.valueOrEmpty)\n Display Name: \(personDisplayName.valueOrEmpty)\n Person ID: \(personId.valueOrEmpty)\n Email Address: \((personEmail?.toString()).valueOrEmpty)\n Space ID: \(spaceId.valueOrEmpty)\n Moderator: \(String(isModerator ?? false))"
    }
}
