import SwiftUI

@available(iOS 16.0, *)
struct ParticipantList: View {
    @ObservedObject var viewModel: ParticipantListViewModel
    @State private var showingReclaimHostAlert = false
    @State private var hostKey = ""
    
    @State private var showingInviteParticipantAlert = false
    @State private var participant = ""

    init(viewModel: ParticipantListViewModel, showingReclaimHostAlert: Bool = false, hostKey: String = "", showingInviteParticipantAlert: Bool = false, participant: String = "") {
        self.viewModel = viewModel
        self.showingReclaimHostAlert = showingReclaimHostAlert
        self.hostKey = hostKey
        self.showingInviteParticipantAlert = showingInviteParticipantAlert
        self.participant = participant
        viewModel.updateCallParticipants()
    }

    var body: some View {
        VStack {
            NavigationView {
                List {
                    Section(header: Text("In Meeting")) {
                        ForEach(viewModel.inMeeting, id: \.personId) { membership in
                            VStack(alignment: .leading){
                                HStack {
                                    Text("\(membership.displayName ?? "") : \((membership.deviceType ?? .unknown).rawValue)")
                                    Spacer()
                                    let color = membership.sendingAudio ? Color.green : Color.red
                                    Button(action: {
                                        muteParticipant(participant: membership)
                                    }) {
                                        
                                        let imageName = membership.sendingAudio ? "mic.fill" : "mic.slash.fill" 
                                        Image(systemName: imageName)
                                            .resizable()
                                            .scaledToFit().frame(width: 20, height: 20)
                                    }.tint(color).accessibilityIdentifier("muteParticipant")
                                }
                                HStack {
                                    if membership.isHost {
                                        Text("Host").font(.caption)
                                    }
                                    if membership.isCohost {
                                        Text("Co Host").font(.caption)
                                    }
                                    if membership.isPresenter {
                                        Text("Presenter").font(.caption)
                                    }
                                    Spacer()
                                }.frame(alignment: .leading)
                            }.frame(alignment: .leading)
                            .swipeActions(edge: .trailing) {
                                if membership.isSelf
                                {
                                    Button(action: {
                                        showHostKeyAlert()
                                    }) {
                                        Text("Reclaim Host")
                                    }.tint(.green).accessibilityIdentifier("reclaimHost")
                                } else {
                                    Button(action: {
                                        viewModel.makeHost(participantId: membership.personId ?? "")
                                    }) {
                                        Text("Make Host")
                                    }.tint(.green).accessibilityIdentifier("makeHost")
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("In Lobby")) {
                        ForEach(viewModel.inLobby, id: \.personId) { membership in
                            Text(membership.displayName ?? "")
                        }
                    }
                    
                    Section(header: Text("Not in Meeting")) {
                        ForEach(viewModel.notInMeeting, id: \.personId) { membership in
                            Text(membership.displayName ?? "")
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !(viewModel.call?.isCUCMCall ?? false || viewModel.call?.isWebexCallingOrWebexForBroadworks  ?? false) {
                            Button(action: {
                                showInviteParticipantAlert()
                            }) {
                                Image(systemName: "person.crop.circle.fill.badge.plus")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 35, height: 35)
                                    .cornerRadius(17.5)
                                    .foregroundColor(.blue)
                            }.accessibilityIdentifier("inviteParticipant")
                        }
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .navigationBarTitle("Participant List", displayMode: .inline)
            }
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("Ok") {
            }
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert(isPresented: $showingReclaimHostAlert, title: "Enter HostKey", textFieldValue: $hostKey, buttonText: "Reclaim Host") {
            viewModel.reclaimHost(hostKey: hostKey)
        }
        .alert(isPresented: $showingInviteParticipantAlert, title: "Enter Participant Id/EmailId", textFieldValue: $participant, buttonText: "Invite Participant") {
            viewModel.inviteParticipant(participant: participant)
        }

    }
    
    func showHostKeyAlert() {
        showingReclaimHostAlert = true
    }
    
    func showInviteParticipantAlert() {
        showingInviteParticipantAlert = true
    }
    
    func muteParticipant(participant: CallMembershipKS)
    {
        viewModel.muteParticipant(participant: participant)
    }
}
//
//@available(iOS 16.0, *)
//#Preview {
//    ParticipantList(viewModel: ParticipantListViewModel(joinAddress: "", isPhoneNumber: false))
//}
