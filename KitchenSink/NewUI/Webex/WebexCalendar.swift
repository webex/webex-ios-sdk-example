import Foundation
import WebexSDK

@available(iOS 16.0, *)
class WebexCalendar {
    /// Lists all calendar meetings.
    func listCalendarMeetings(completion: @escaping (Result<[MeetingsKS]?>) -> Void) {
        webex.calendarMeetings.list(fromDate: nil, toDate: nil, completionHandler: { result in
            switch result {
            case .success(let meetings):
                var meetingsKS: [MeetingsKS] = []
                guard let meetings = meetings else { return }
                for meeting in meetings {
                    meetingsKS.append(MeetingsKS.buildFrom(meeting: meeting))
                    completion(.success(meetingsKS))
                }
            case .failure(let err):
                completion(.failure(err))
            @unknown default:
                break
            }
        })
    }
}
