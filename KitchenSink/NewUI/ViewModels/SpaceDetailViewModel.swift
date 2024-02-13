import SwiftUI
import WebexSDK

@available(iOS 16.0, *)
class SpaceDetailViewModel: ObservableObject {
    @Published var loading = true
    @Published var membershipResults = [MembershipKS]()
    @Published var membershipReadStatusResults = [MembershipReadStatusKS]()
    @Published var showError: Bool = false
    @Published var error: String = ""

    let webexSpace = WebexSpaces()
    let webexMembership = WebexMembership()
    
    /// Fetches the list of memberships from the Webex SDK and updates the `membershipResults` array with the fetched data.
    func getMembershipList(spaceId: String? = nil, personId: String? = nil, personEmail: EmailAddress? = nil) {
        webexMembership.listMemberships(spaceId: spaceId, personId: personId, personEmail: personEmail, queue: .global(qos: .default), completion: { [weak self] result in
            switch result {
            case .success(let memberships):
                DispatchQueue.main.async {
                    self?.membershipResults = []
                    for membership in memberships {
                        self?.membershipResults.append(MembershipKS.buildFrom(membership: membership))
                    }
                    self?.loadingIndicator(show: false)
                }
            case .failure(let error):
                print(error.localizedDescription)
                self?.loadingIndicator(show: false)
                self?.showError(error: error)
            @unknown default:
                break
            }
        })
    }

    /// Fetches the list of memberships with read status from the Webex SDK and updates the `membershipReadStatusResults` array with the fetched data.
    func getMembershipListWithReadStatus(spaceId:String) {
        webexMembership.listWithReadStatus(spaceId: spaceId) { [weak self] result in
            switch result {
            case .success(let memberships):
                DispatchQueue.main.async {
                    self?.membershipReadStatusResults = []
                    for membership in memberships {
                        self?.membershipReadStatusResults.append(MembershipReadStatusKS.buildFrom(membership: membership))
                    }
                    self?.loadingIndicator(show: false)
                }
            case .failure(let error):
                print(error.localizedDescription)
                self?.loadingIndicator(show: false)
                self?.showError(error: error)
            @unknown default:
                break
            }
        }
    }
    
    /// Fetches the space by its ID from the Webex SDK and calls the completion handler with the space's display value.
    func fetchSpaceById(spaceId: String, completion: @escaping (String) -> Void) {
        self.loadingIndicator(show: true)
        webexSpace.fetchSpace(byId: spaceId) { result in
            switch result {
            case.success(let space):
                self.loadingIndicator(show: false)
                completion(space.displayValue)
            case .failure(let error):
                self.loadingIndicator(show: false)
                print(error)
                self.showError(error: error)
            @unknown default:
                break
            }
        }
    }
    
    /// Fetches the meeting information of the space by its ID from the Webex SDK and calls the completion handler with the meeting info's display value.
    func fetchSpaceMeetingInfo(id: String, completion: @escaping (String) -> Void) {
        self.loadingIndicator(show: true)
        webexSpace.fetchSpaceMeetingInfo(id: id) { result in
            switch result {
            case .success(let meetingInfo):
                self.loadingIndicator(show: false)
                completion(meetingInfo.displayValue)
            case .failure(let error):
                self.loadingIndicator(show: false)
                print(error)
                self.showError(error: error)
            @unknown default:
                break
            }
        }
    }
    
    /// Fetches the read status of the space by its ID from the Webex SDK and calls the completion handler with the read status's display value.
    func fetchSpaceReadStatus(byId id: String, completion: @escaping (String) -> Void) {
        self.loadingIndicator(show: true)
        webexSpace.fetchSpaceReadStatus(id: id) { result in
            guard let readStatusData = result.data else {return}
            switch result {
            case .success(readStatusData):
                self.loadingIndicator(show: false)
                completion(readStatusData?.displayValue ?? "")
            case .failure(let error):
                self.loadingIndicator(show: false)
                print(error)
                self.showError(error: error)
            @unknown default:
                break
            }
        }
    }
    
    /// Marks all messages in the space as read in the Webex SDK and calls the completion handler with a status message.
    func markSpaceAsRead(spaceId: String, completion: @escaping (String) -> Void) {
        self.loadingIndicator(show: true)
        webex.messages.markAsRead(spaceId: spaceId) { result in
            switch result {
            case .success:
                self.loadingIndicator(show: false)
                return completion("Message marked read.")
            case .failure(let error):
                self.loadingIndicator(show: false)
                return completion("Failed to mark message read. \(error)")
            @unknown default:
                break
            }
        }
    }
    
    /// Deletes the space by its ID in the Webex SDK and calls the completion handler with a status message.
    func deleteSpace(spaceId: String, completion: @escaping (String) -> Void) {
        self.loadingIndicator(show: true)
        webexSpace.deleteSpace(id: spaceId) { result in
            switch result {
            case .success:
                self.loadingIndicator(show: false)
                return completion("Deleted")
            case .failure(let error):
                self.loadingIndicator(show: false)
                return completion("Error Deleting Space \(error)")
            @unknown default:
                break
            }
        }
    }
    
    /// Updates the title of the space by its ID in the Webex SDK and calls the completion handler with a status message.
    func updateSpaceTitle(spaceId: String, title: String, completion: @escaping (String) -> Void) {
        self.loadingIndicator(show: true)
        webexSpace.updateSpaceTitle(id: spaceId, title: title) { result in
            guard let message = result.data?.title else { return }
            switch result {
            case .success:
                self.loadingIndicator(show: false)
                return completion("Space's new title: \(String(describing: message))")
            case .failure(let error):
                self.loadingIndicator(show: false)
                return completion("Space update failure: \(error)")
            @unknown default:
                break
            }
        }
    }
    
    /// Fetches the membership by its ID from the Webex SDK and calls the completion handler with the membership's display value.
    func fetchMembershipById(membershipId: String, completion: @escaping (String)-> Void) {
        self.loadingIndicator(show: true)
        webexMembership.fetchMembershipById(membershipId: membershipId) { result in
            switch result {
            case.success(let space):
                self.loadingIndicator(show: false)
                completion(space.displayValue)
            case .failure(let error):
                self.loadingIndicator(show: false)
                print(error)
                self.showError(error: error)
            @unknown default:
                break
            }
        }
    }
    
    /// Sets the moderator status for the membership by its ID in the Webex SDK and calls the completion handler with the membership's display value.
    func setModerator(membershipId: String, isModerator: Bool, completion: @escaping (String)-> Void) {
        self.loadingIndicator(show: true)
        webexMembership.setModerator(membershipId: membershipId, isModerator: isModerator) { result in
            switch result {
            case.success(let membership):
                self.loadingIndicator(show: false)
                completion(membership.displayValue)
            case .failure(let error):
                self.loadingIndicator(show: false)
                print(error)
                self.showError(error: error)
            @unknown default:
                break
            }
        }
    }
    
    /// Creates a membership with the given person ID, space ID, and person display name in the Webex SDK and calls the completion handler with a status message and a detail message.
    func createMembership(personId: String, spaceId: String, personDisplayName: String, completion: @escaping (String, String) -> Void) {
        self.loadingIndicator(show: true)
        webexMembership.createTeamMembership(withPersonId: personId, spaceId: spaceId, personDisplayName: personDisplayName) { result in
            switch result {
            case.success:
                self.loadingIndicator(show: false)
                completion("Success", "\(personDisplayName) added to \(spaceId)")
            case .failure:
                self.loadingIndicator(show: false)
                completion("Failure", "Failed to add \(personDisplayName)")
            @unknown default:
                break
            }
        }
    }
    
    /// Adds a team membership with the given email, space ID, and person display name in the Webex SDK and calls the completion handler with a status message and a detail message.
    func addTeamMembership(withEmail email: EmailAddress, spaceId: String, personDisplayName: String, completion: @escaping (String, String) -> Void) {
        self.loadingIndicator(show: true)
        webexMembership.addTeamMembership(withEmail: email, spaceId: spaceId, personDisplayName: personDisplayName) { result in
            switch result {
            case.success:
                self.loadingIndicator(show: false)
                completion("Success", "\(personDisplayName) added to \(spaceId)")
            case .failure:
                self.loadingIndicator(show: false)
                completion("Failure", "Failed to add \(personDisplayName)")
            @unknown default:
                break
            }
        }
    }
    
    /// Deletes the membership by its ID in the Webex SDK and calls the completion handler with a status message.
    func deleteMembership(membershipId: String, completion: @escaping (String) -> Void) {
        self.loadingIndicator(show: true)
        webexMembership.deleteMembership(membershipId: membershipId ) { result in
            switch result {
            case .success:
                self.loadingIndicator(show: false)
                return completion("Deleted")
            case .failure(let error):
                self.loadingIndicator(show: false)
                return completion("Error Deleting Space \(error)")
            @unknown default:
                break
            }
        }
    }

    /// Asynchronously controls the visibility of a loading indicator on the main queue.
    func loadingIndicator(show: Bool) {
        DispatchQueue.main.async {
            self.loading = show
        }
    }

    /// Asynchronously displays an error message on the main queue.
    func showError(error: Error) {
        DispatchQueue.main.async {
            self.showError = true
            self.error = error.localizedDescription
        }
    }
}
