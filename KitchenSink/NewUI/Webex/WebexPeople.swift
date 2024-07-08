import Foundation
import WebexSDK

@available(iOS 16.0, *)
class WebexPeople {
    /// Fetches the details of the current user.
    func getMe(completion: @escaping (Result<Person>) -> Void) {
        webex.people.getMe(completionHandler: completion)
    }

    func startWatchingPresenceForSpaces(spaceIds: [String], completion: @escaping (Presence) -> Void) -> [PresenceHandle] {
        return webex.people.startWatchingPresenceForSpaces(spaceIds: spaceIds, completionHandler: completion)
    }

    /// Stops watching the presence of the specified contacts.
    func stopWatchingPresence(handles: [PresenceHandle]) {
        webex.people.stopWatchingPresences(presenceHandles: handles)
    }
    
    /// Searches for people by their email or display name.
    func searchPeopleList(searchString: String, completion: @escaping ([PersonKS]) -> Void) {
        if let email = EmailAddress.fromString(searchString) {
            webex.people.list(email: email) { results in
                guard let searchResults = results.data else { return }
                var personList: [PersonKS] = []
                for person in searchResults {
                    personList.append(PersonKS.buildFrom(person: person))
                }
                completion(personList)
            }
        } else {
            webex.people.list(displayName: searchString) { results in
                guard let searchResults = results.data else { return }
                var personList: [PersonKS] = []
                for person in searchResults {
                    personList.append(PersonKS.buildFrom(person: person))
                }
                completion(personList)
            }
        }
    }
}
