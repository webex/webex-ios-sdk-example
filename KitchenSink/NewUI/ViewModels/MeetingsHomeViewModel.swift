import Foundation
import WebexSDK

@available(iOS 16.0, *)
class MeetingsHomeViewModel: ObservableObject {
    @Published var showLoading: Bool = false
    @Published var meetings: [MeetingsKS] = []
    @Published var showError: Bool = false
    @Published var error: String = ""
    @Published var incomingCall: CallKS?
    @Published var isCallIncoming: Bool = false
    
    let webexMeetings = WebexCalendar()
    
    /// List all meetings.
    func listMeetings() {
        webexMeetings.listCalendarMeetings(completion: { result in
            switch result {
            case .success(let meetings):
                self.meetings = []
                guard let meetings = meetings else { return }
                DispatchQueue.main.async {
                    self.meetings = meetings
                }
            case .failure(let err):
                DispatchQueue.main.async {
                    self.showError = true
                    self.error = err.localizedDescription
                }
            @unknown default:
                break
            }
        })
    }
    
    func isMoveMeetingAllowed(meetingId: String) -> Bool
    {
        return webex.calendarMeetings.isMoveMeetingSupported(meetingId: meetingId)
    }

    /// Updates list of meeting in case any meeting is added or updated.
    func updateMeetings() {
        if self.meetings.isEmpty {
            listMeetings()
        }
        webex.calendarMeetings.onEvent = { event in
            switch event {
            case .created(let meeting):
                self.meetings.append(MeetingsKS(title: meeting.subject, id: meeting.meetingId, start: getLocalDate(serverDate: meeting.startTime), end: getLocalDate(serverDate: meeting.endTime), canJoin: meeting.canJoin, link: meeting.link, sipUrl: meeting.sipUrl, isOngoingMeeting: meeting.isOngoingMeeting))
            case .updated(let meeting):
                guard let index = self.meetings.firstIndex(where: { $0.id == meeting.meetingId }) else { return }
                self.meetings.remove(at: index)
                self.meetings.append(MeetingsKS(title: meeting.subject, id: meeting.meetingId, start: getLocalDate(serverDate: meeting.startTime), end: getLocalDate(serverDate: meeting.endTime), canJoin: meeting.canJoin, link: meeting.link, sipUrl: meeting.sipUrl, isOngoingMeeting: meeting.isOngoingMeeting))
            case .removed(let meetingId):
                guard let index = self.meetings.firstIndex(where: { $0.id == meetingId }) else { return }
                self.meetings.remove(at: index)
            @unknown default:
                break
            }

        }
    }
}

// MARK: Phone
@available(iOS 16.0, *)
extension MeetingsHomeViewModel {
    /// Registers a callback for Incoming call event.
    func registerIncomingCall() {
        webex.phone.onIncoming = { call in
            if !call.isMeeting || !call.isScheduledMeeting || !call.isSpaceMeeting {
                self.incomingCall = CallKS(call: call)
                self.isCallIncoming = true
            }
        }
    }
}
