import Foundation
import WebexSDK

class WebexSpaces {
    /// A Boolean value indicating whether the synchronization of spaces is complete.
    var isSyncCompleted: Bool = webex.spaces.isSpacesSyncCompleted

    /// A closure that is called when the synchronization of spaces is complete.
    var onSyncCompleted = {
        webex.spaces.onSyncingSpacesStatusChanged
    }

    /// Filters spaces based on the provided query.
    func filterSpaces(filter: String, completion: @escaping ([Space]) -> Void) {
        webex.spaces.filter(query: filter, completionHandler: completion)
    }
    
    /// Fetches the details of a specific space.
    func getDetails(id: String, completion: @escaping (WebexSDK.Result<WebexSDK.Space>) -> Void) {

    }
    
    /// Creates a new space with the specified title and team ID.
    func createSpace(title: String, teamdId: String?, completion: @escaping (WebexSDK.Result<WebexSDK.Space>) -> Void) {
        webex.spaces.create(title: title, teamId: teamdId, completionHandler: completion)
    }
    
    /// Fetches a list of spaces.
    func getListOfSpaces(teamId: String? = nil, max: Int? = nil, type: SpaceType? = nil, sortBy: SpaceSortType? = nil, queue: DispatchQueue?, completion: @escaping (Result<[Space]>) -> Void) {
        webex.spaces.list(teamId: teamId, max: max, type: type, sortBy: sortBy, queue: queue, completionHandler: completion)
    }

    /// Fetches a list of spaces along with their read status.
    func getListOfSpacesWithReadStatus(completion: @escaping (Result<[SpaceReadStatus]?>) -> Void) {
        webex.spaces.listWithReadStatus(max: 20, completionHandler: completion)
    }

    /// Deletes a specific space.
    func deleteSpace(id: String, completion: @escaping (Result<Void>) -> Void) {
        webex.spaces.delete(spaceId: id, completionHandler: completion)
    }
    
    /// Fetches a specific space.
    func fetchSpace(byId id: String, completion: @escaping (Result<Space>) -> Void) {
        webex.spaces.get(spaceId: id, completionHandler: completion)
    }
    
    /// Fetches the meeting information of a specific space.
    func fetchSpaceMeetingInfo(id: String, completion: @escaping (Result<SpaceMeetingInfo>) -> Void) {
        webex.spaces.getMeetingInfo(spaceId: id, completionHandler: completion)
    }
    
    /// Fetches the read status of a specific space.
    func fetchSpaceReadStatus(id: String, completion: @escaping (Result<SpaceReadStatus?>) -> Void) {
        webex.spaces.getWithReadStatus(spaceId: id, completionHandler: completion)
    }
    
    /// Marks a specific space as read.
    func markSpaceAsRead(id: String, completion: @escaping (Result<Void>) -> Void) {
        webex.messages.markAsRead(spaceId: id, completionHandler: completion)
    }
    
    /// Updates the title of a specific space.
    func updateSpaceTitle(id: String, title:String, completion: @escaping (Result<Space>) -> Void) {
        webex.spaces.update(spaceId: id, title: title, completionHandler: completion)
    }
}

