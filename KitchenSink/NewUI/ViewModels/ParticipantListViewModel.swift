import SwiftUI

@available(iOS 16.0, *)
class ParticipantListViewModel: ObservableObject
{
    var call: CallProtocol?
    var callParticipants: [CallMembershipKS] = []

    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var showAlert = false
    @Published var inMeeting: [CallMembershipKS] = []
    @Published var notInMeeting: [CallMembershipKS] = []
    @Published var inLobby: [CallMembershipKS] = []
    
    init(call: CallProtocol?) {
         self.call = call
        registerForCallMembershipCallbacks()
    }
    
    
    func registerForCallMembershipCallbacks() {
        call?.onCallMembershipChanged = { [weak self] event in
            self?.updateCallParticipants()
        }
    }
    
    func updateCallParticipants() {
        var inMeetingList: [CallMembershipKS] = []
        var inLobbyList: [CallMembershipKS] = []
        var notInMeetingList: [CallMembershipKS] = []

        self.callParticipants = self.call?.memberships ?? []
        inMeetingList = self.callParticipants.filter({ participant in
            participant.state == .joined
        })

        inLobbyList = self.callParticipants.filter({ participant in
            participant.state == .waiting
        })

        notInMeetingList = self.callParticipants.filter({ participant in
            participant.state == .declined || participant.state == .idle || participant.state == .left
        })

        DispatchQueue.main.async { [weak self] in
            self?.inMeeting = inMeetingList
            self?.inLobby = inLobbyList
            self?.notInMeeting = notInMeetingList
        }
    }
    
    func makeHost(participantId: String) {
        call?.makeHost(participantId:  participantId) { [weak self] result in
            var errorMessage = ""
            switch result {
                case .success():
                errorMessage = "makeHost successful"
                case .failure(let error):
                errorMessage = "\(error)"
            }
            self?.showError("makeHost", errorMessage)
        }
    }
    
    func reclaimHost(hostKey: String = "") {
        call?.reclaimHost(hostKey: hostKey) { [weak self] result in
            var errorMessage = ""
            switch result {
                case .success():
                errorMessage = "reclaimHost successful"
                case .failure(let error):
                errorMessage = "\(error)"
            }
            self?.showError("reclaimHost", errorMessage)
        }
    }
    
    func inviteParticipant(participant: String) {
        call?.inviteParticipant(participant: participant) { [weak self] result in
            var errorMessage = ""
            
            switch result {
            case .success():
                errorMessage = "added successfully"
            case .failure(let error):
                errorMessage = "\(error)"
            @unknown default:
                break
            }
            
            self?.showError("Invite Participant", errorMessage)
        }
    }
    
    // Shows the alert with the given title and message.
    func showError(_ alertTitle: String, _ alertMessage: String) {
        DispatchQueue.main.async { [weak self] in
            self?.alertTitle = alertTitle
            self?.alertMessage = alertMessage
            self?.showAlert = true
        }
    }
    
    func muteParticipant(participant: CallMembershipKS)
    {
        if participant.isSelf {
            showError("Not Supported",  "Cannot mute self from participants list.")
        } else {
            var isMuted = !participant.sendingAudio
            isMuted.toggle()
            call?.setParticipantAudioMuteState(participantId: participant.personId ?? "", isMuted: isMuted)
        }
    }
    
}
