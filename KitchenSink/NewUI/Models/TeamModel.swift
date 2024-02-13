import Foundation
import WebexSDK

/// A structure representing a team.
struct TeamKS: Identifiable {
    var id: String?
    var name: String?
    var created: String?
    
    ///constructs a `TeamKS` instance from a `WebexSDK.Team` object.
    static func buildFrom(team: WebexSDK.Team) -> Self {
        return TeamKS(id: team.id, name: team.name, created: team.created?.description)
    }
}
