import SwiftUI
import WebexSDK

@available(iOS 16.0, *)
enum SortTypeKS: CaseIterable {
    case id
    case created
    case lastActivity
}

@available(iOS 16.0, *)
enum SpaceTypeKS: String, CaseIterable {
    case direct
    case group
    
    var description: String {
        switch self {
        case .direct: return "Direct"
        case .group: return "Group"
        }
    }
}

@available(iOS 16.0, *)
struct PresenceStatusKS {
    var title: String
    var image: String
    var textColor: Color
}

@available(iOS 16.0, *)
class MessagingHomeViewModel: ObservableObject {
    @Published var profile: ProfileKS?
    @Published var created: Bool = false
    @Published var showLoading: Bool = false
    @Published var isLoggedOut: Bool = false
    @Published var spaces: [SpaceKS] = []
    @Published var teams: [TeamKS] = []
    @Published var showError: Bool = false
    @Published var error: String = ""
    @Published var incomingCall: CallKS?
    @Published var isCallIncoming: Bool = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var shouldDeleteTeam = false
    @Published var selectedTeam: TeamKS?
    var mailVM = MailViewModel()
    var handles: [PresenceHandle] = []
    let webexSpace = WebexSpaces()
    let webexTeam = WebexTeams()
    let webexMembership = WebexMembership()
    let webexPeople = WebexPeople()
    let messagingHomeUtil = MessagingHomeUtil()
    let throttler = Throttler(minimumDelay: 0.5)

    init() {
        syncSpaces()
        registerSpaceCallBack()
        registerSpaceCallBackWithPayload()
    }

    func showAlert(alertTitle: String, alertMessage: String, selectedTeam: TeamKS) {
        self.showAlert = true
        self.alertTitle = alertTitle
        self.alertMessage = alertMessage
        self.selectedTeam = selectedTeam
    }
}

// MARK: Spaces
@available(iOS 16.0, *)
extension MessagingHomeViewModel {
    /// Creates a new space with the given title.
    func createNewSpace(title: String) {        
        webexSpace.createSpace(title: title, teamdId: nil, completion: { result in
            switch result {
            case.success(_):
                DispatchQueue.main.async {
                    self.created = true
                    self.getListOfSpaces()
                }
            case .failure(let error):
                self.showError(error: error)
            @unknown default:
                break
            }
        })
    }

    /// Fetches a list of spaces with optional filters
    func getListOfSpaces(teamId: String? = nil, max: Int? = nil, type: SpaceType? = nil, sortBy: SpaceSortType? = .byLastActivity) {
        loadingIndicator(show: true)
        webexSpace.getListOfSpaces(teamId: teamId, max: max, type: type, sortBy: sortBy, queue: .global(qos: .default), completion: { result in
            switch result {
            case.success(let spaces):
                self.loadingIndicator(show: false)
                    var spaceKS: [SpaceKS] = []
                    for space in spaces {
                        spaceKS.append(SpaceKS.buildFrom(space: space))
                    }
                DispatchQueue.main.async {
                    self.spaces = spaceKS
                }
            case .failure(let error):
                print(error)
                self.loadingIndicator(show: false)
                self.showError(error: error)
            @unknown default:
                break
            }
        })
    }
    
    /// Syncs the list of spaces and updates the loading status.
    func syncSpaces() {
        print("isSpacesSyncCompleted : \(webexSpace.isSyncCompleted)")
        if !webexSpace.isSyncCompleted {
            self.loadingIndicator(show: true)
        } else {
            self.loadingIndicator(show: false)
        }

        webex.spaces.onSyncingSpacesStatusChanged = { isSpacesSyncInProgress in
            print("Syncing Spaces: \(isSpacesSyncInProgress)")
            if isSpacesSyncInProgress {
                self.loadingIndicator(show: true)
            } else {
                self.loadingIndicator(show: false)
            }
        }
    }

    /// Registers a callback function for Webex Spaces events.
    func registerSpaceCallBack() {
        webex.spaces.onEvent = { event in
            switch event {
            case .create, .update:
                self.throttler.throttle {
                    self.getListOfSpaces()
                }
            case .spaceCallStarted(_):
                break
            case .spaceCallEnded(_):
                break
            default:
                break
            }
        }
    }

    /// Registers a callback function for Webex Spaces events with payload.
    func registerSpaceCallBackWithPayload() {
        webex.spaces.onEventWithPayload = { event, id in
            print(id)
            switch event {
            case .create, .update:
                self.throttler.throttle {
                    self.getListOfSpaces()
                }
            case .spaceCallStarted(_):
                break
            case .spaceCallEnded(_):
                break
            default:
                break
            }
        }
    }

    /// Deletes a specific space by its ID.
    func deleteSpace(id: String) {
        webexSpace.deleteSpace(id: id, completion: { result in
            switch result {
            case .success():
                print("Deleted!")
            case .failure(let err):
                self.showError(error: err)
            @unknown default:
                break
            }
        })
    }

    /// Filters the list of spaces based on the given parameters i.e. teamId, max number, space type, sort type
    func filterSpace(teamId: String? = nil, max: Int? = nil, typeOfSpace: SpaceTypeKS? = nil, sortBy: SortTypeKS? = nil) {

        var spaceType: SpaceType?
        var spaceSortType: SpaceSortType?

        if sortBy == .id {
            spaceSortType = .byId
        } else if sortBy == .created {
            spaceSortType = .byCreated
        } else if sortBy == .lastActivity {
            spaceSortType = .byLastActivity
        }

        if typeOfSpace == .direct {
            spaceType = .direct
        } else if typeOfSpace == .group {
            spaceType = .group
        }

        getListOfSpaces(teamId: teamId, max: max, type: spaceType, sortBy: spaceSortType)
    }

    /// Fetches the read status for all spaces
    func showSpaceReadStatus() {
        loadingIndicator(show: true)
        stopWatchingPresence()
        self.throttler.throttle { [self] in
            webexSpace.getListOfSpacesWithReadStatus(completion: { result in
                switch result {
                case.success(let spaceReadStatuses):
                    self.loadingIndicator(show: false)
                    guard let spaceReadStatuses = spaceReadStatuses else { return }
                    if spaceReadStatuses.count != self.spaces.count {
                        var spacesKS:[SpaceKS] = []
                        for space in spaceReadStatuses {
                            let presenceStatusKS = PresenceStatusKS(title: "Last Activity: \(space.lastActivityDate?.description ?? "")", image: "", textColor: .secondary)
                            spacesKS.append(SpaceKS.buildFrom(space: space, presenceStatus: presenceStatusKS))
                        }
                        DispatchQueue.main.async {
                            self.spaces = spacesKS
                        }
                    }
                case .failure(let error):
                    print(error)
                    self.loadingIndicator(show: false)
                    self.showError(error: error)
                @unknown default:
                    break
                }
            })
        }
    }
}

// MARK: Teams
@available(iOS 16.0, *)
extension MessagingHomeViewModel {
    /// Creates a new team with the given title.
    func createNewTeam(title: String) {
        webexTeam.createTeam(title: title, completion: { result in
            switch result {
            case.success(_):
                DispatchQueue.main.async {
                    self.created = true
                    self.getListOfTeams()
                }
            case .failure(let error):
                self.showError(error: error)
            @unknown default:
                break
            }
        })
    }

    /// Fetches a list of teams and updates
    func getListOfTeams() {
        loadingIndicator(show: true)
        webexTeam.getListOfTeams(completion: { result in
            switch result {
            case.success(let teams):
                let teamsKS = teams.filter { !$0.isDeleted }.map{ TeamKS.buildFrom(team: $0) }
                DispatchQueue.main.async {
                    self.loadingIndicator(show: false)
                    self.teams = teamsKS
                }
            case .failure(let error):
                print(error)
                self.loadingIndicator(show: false)
                self.showError(error: error)
            @unknown default:
                break
            }})
    }
    
    /// Deletes selected team
    func deleteTeam() {
        loadingIndicator(show: true)
        guard let team = self.selectedTeam, let teamId = team.id else { return }
        webexTeam.deleteTeam(id: teamId) { result in
            switch result {
            case.success(_):
                DispatchQueue.main.async {
                    self.shouldDeleteTeam = false
                    self.showAlert = true
                    self.alertTitle = "Success"
                    self.alertMessage = "Team has been deleted"
                    self.teams = self.teams.filter { $0.id != teamId }
                }
            case .failure(let error):
                self.shouldDeleteTeam = false
                self.showAlert = true
                self.alertTitle = "Failure"
                self.alertMessage = "Team deletion failure \n \(error)"
            @unknown default:
                break
            }
        }
    }
}

// MARK: People
@available(iOS 16.0, *)
extension MessagingHomeViewModel {
    /// Fetches the profile of the current user
    func getMe() {
        webexPeople.getMe(completion: { result in
            switch result {
            case .failure(let err):
                self.showError(error: err)
            case .success(let person):
                UserDefaults.standard.set(person.id, forKey: Constants.selfId)
                DispatchQueue.main.async {
                    self.profile = ProfileKS(imageUrl: person.avatar, name: person.displayName, status: person.status)
                    self.registerPush(personId: person.encodedId ?? "")
                }
            @unknown default:
                break
            }
        })
    }
    func registerPush(personId: String) {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") else { return }
        guard let keys = NSDictionary(contentsOfFile: path) else { return }
        guard let token = token, let voipToken = voipToken else { return }

        if let urlString = keys["registrationUrl"] as? String  {
            guard let serviceUrl = URL(string: urlString) else { print("Invalid URL"); return }

            let parameters: [String: Any] = [
                "voipToken": voipToken,
                "deviceToken": token,
                "pushProvider": "APNS",
                "userId": personId,
                "prod": false
            ]
            var request = URLRequest(url: serviceUrl)
            request.httpMethod = "POST"
            request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
            guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                return
            }
            request.httpBody = httpBody
            request.timeoutInterval = 20
            let session = URLSession.shared
            session.dataTask(with: request) { (data, response, error) in
                if let response = response {
                    print("DEVICE REGISTRATION: \(response)")
                }
            }.resume()
        }
        else {
            let bundleId = keys["bundleId"] as? String ?? ""

            webex.phone.setPushTokens(bundleId: bundleId, deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "", deviceToken: token, voipToken: voipToken, appId: nil)
            return
        }
    }
}

// MARK: Memberships
@available(iOS 16.0, *)
extension MessagingHomeViewModel {
    /// Fetches the presence status for all direct spaces
    func getPresenceStatusForSpaces(directSpaceIds: [String]) {
        self.handles = self.webexPeople.startWatchingPresenceForSpaces(spaceIds: directSpaceIds,  completion: { presence in
            if let index = self.spaces.firstIndex(where: { $0.id == presence.spaceId }) {
                // Not getting presence status for space read status
                if self.spaces[index].presenceStatus?.image != "" {
                    let presenceStatusKS = self.messagingHomeUtil.getPresenceStatusKS(presence: presence)
                    if (self.spaces[index].presenceStatus?.title != presenceStatusKS.title) {
                        DispatchQueue.main.async {
                            self.spaces[index].presenceStatus = presenceStatusKS
                        }
                    }
                }
            }
        })
    }

    /// Asynchronously displays an error message on the main queue.
    func showError(error: Error) {
        DispatchQueue.main.async {
            self.showError = true
            self.error = error.localizedDescription
        }
    }

    /// Stops watching the presence status for all contacts.
    func stopWatchingPresence() {
        webexPeople.stopWatchingPresence(handles: handles)
    }

    /// Asynchronously controls the visibility of a loading indicator on the main queue.
    func loadingIndicator(show: Bool) {
        DispatchQueue.main.async {
            self.showLoading = show
        }
    }
}

// MARK: Phone
@available(iOS 16.0, *)
extension MessagingHomeViewModel {
    /// Registers a callback for Incoming call event.
    func registerIncomingCall() {
        webex.phone.onIncoming = { call in
            if call.isWebexCallingOrWebexForBroadworks {
                if WebexManager.shared.isCurrentScreenIsCallScreen()
                {
                    voipUUID = UUID()
                    AppDelegate.shared.callKitManager?.reportIncomingCallFor(uuid: voipUUID!, sender: call.title ?? "") {
                    AppDelegate.shared.callKitManager?.updateCall(call: call, voipUUID: voipUUID)
                        return
                    }
                }
                print("webex.phone.onIncoming calll \(String(describing: call.callId))")
                AppDelegate.shared.callKitManager?.updateCall(call: call)
                return
            }
            if !call.isMeeting || !call.isScheduledMeeting || !call.isSpaceMeeting {
                self.incomingCall = CallKS(call: call)
                self.isCallIncoming = true
            }
        }
    }
}
