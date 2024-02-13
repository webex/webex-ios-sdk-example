import Foundation
import WebexSDK

class WebexTeams {
    /// Fetches a list of teams.
    func getListOfTeams(completion: @escaping (Result<[Team]>) -> Void) {
        webex.teams.list(max: 100, queue: DispatchQueue.global(qos: .default), completionHandler: completion)
    }

    /// Creates a new team with the specified title.
    func createTeam(title: String, completion: @escaping (Result<Team>) -> Void) {
        webex.teams.create(name: title, completionHandler: completion)
    }
}

