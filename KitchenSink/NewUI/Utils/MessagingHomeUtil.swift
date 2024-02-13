import Foundation
import WebexSDK

@available(iOS 16.0, *)
class MessagingHomeUtil {
    func getPresenceStatusKS(presence: Presence) -> PresenceStatusKS {
        var presenceStatusKS: PresenceStatusKS = PresenceStatusKS(title: "", image: "", textColor: .gray)
        switch presence.status {
        case .Unknown:
            presenceStatusKS.title = "Unknown"
            presenceStatusKS.textColor = .gray
            presenceStatusKS.image = "person.crop.circle.badge.questionmark"
        case .Pending:
            presenceStatusKS.title = "Pending"
            presenceStatusKS.textColor = .orange
            presenceStatusKS.image = "person.crop.circle.dashed"
        case .Active:
            presenceStatusKS.title = "Active"
            presenceStatusKS.textColor = .green
            presenceStatusKS.image = "person.crop.circle.fill"
        case .Inactive:
            let time = presence.lastActiveTime.timeIntervalSinceNow.stringFromTimeInterval()
            presenceStatusKS.title = "Inactive \(time)"
            presenceStatusKS.textColor = .secondary
            presenceStatusKS.image = "person.crop.circle.badge.minus"
        case .Dnd:
            presenceStatusKS.title = "Do Not Disturb"
            presenceStatusKS.textColor = .red
            presenceStatusKS.image = "person.crop.circle.badge.moon"
        case .Quiet:
            presenceStatusKS.title = "Quiet"
            presenceStatusKS.textColor = .yellow
            presenceStatusKS.image = "person.crop.circle.badge.moon"
        case .Busy:
            presenceStatusKS.title = "Busy"
            presenceStatusKS.textColor = .yellow
            presenceStatusKS.image = "person.crop.circle.badge.moon"
        case .OutOfOffice:
            presenceStatusKS.textColor = .accentColor
            presenceStatusKS.title = "Out Of Office"
            presenceStatusKS.image = "person.crop.circle.badge.moon"
        case .Call:
            presenceStatusKS.textColor = .green
            presenceStatusKS.title = "On Call"
            presenceStatusKS.image = "phone.circle"
        case .Meeting:
            presenceStatusKS.textColor = .yellow
            presenceStatusKS.title = "In Meeting"
            presenceStatusKS.image = "calendar.circle"
        case .Presenting:
            presenceStatusKS.textColor = .red
            presenceStatusKS.title = "Presenting"
            presenceStatusKS.image = "shared.with.you.circle"
        case .CalendarItem:
            presenceStatusKS.textColor = .yellow
            presenceStatusKS.title = "In Calendar Meeting"
            presenceStatusKS.image = "calendar.circle"
        @unknown default:
            presenceStatusKS.textColor = .gray
            presenceStatusKS.title = "Unknown"
            presenceStatusKS.image = "person.crop.circle.badge.questionmark"
        }

        if !presence.customStatus.isEmpty {
            presenceStatusKS.title.append(" - \(presence.customStatus)")
        }

        return presenceStatusKS
    }
}
