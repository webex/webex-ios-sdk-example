import Foundation
import WebexSDK

/// A structure representing a space.
@available(iOS 16.0, *)
struct SpaceKS: Identifiable {
    var id: String?
    var name: String?
    var created: String?
    var teamId: String?
    var lastActivityTime: String?
    var type: SpaceTypeKS?
    var presenceStatus: PresenceStatusKS?
    
    ///constructs a `SpaceKS` instance from a `WebexSDK.Space` object.
    static func buildFrom(space: WebexSDK.Space) -> Self {
        return SpaceKS(id: space.id, name: space.title, created: space.created?.description, teamId: space.teamId, lastActivityTime: space.lastActivityTimestamp?.description, type: space.type == .group ? SpaceTypeKS.group : SpaceTypeKS.direct)
    }
    
    ///constructs a `SpaceKS` instance from a `WebexSDK.SpaceReadStatus` object.
    static func buildFrom(space: WebexSDK.SpaceReadStatus, presenceStatus: PresenceStatusKS) -> Self {
        return SpaceKS(id: space.id, name: "Space Read Status", created: space.lastActivityDate?.description, type: space.type == .group ? .group : .direct, presenceStatus: presenceStatus)
    }
}
