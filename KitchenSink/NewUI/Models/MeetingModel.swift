import Foundation
import WebexSDK

/// A structure representing a meeting.
struct MeetingsKS: Identifiable {
    var title: String
    var id: String
    var start: String
    var end: String
    var canJoin: Bool
    var link: String
    var sipUrl: String

    ///constructs a `MeetingsKS` instance from a `WebexSDK.Meeting` object.
    static func buildFrom(meeting: WebexSDK.Meeting) -> Self {
        return MeetingsKS(title: meeting.subject, id: meeting.meetingId, start: getLocalDate(serverDate: meeting.startTime), end: getLocalDate(serverDate: meeting.endTime), canJoin: meeting.canJoin, link: meeting.link, sipUrl: meeting.sipUrl)
    }
}
