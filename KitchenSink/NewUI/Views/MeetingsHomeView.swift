import SwiftUI

@available(iOS 16.0, *)
struct MeetingsHomeView: View {

    @ObservedObject var model = MeetingsHomeViewModel()
    @State var showActionSheet = false
    @State var showCallView = false
    @State var showCallingView = false
    @State var meetingInfo = ""
    @State var moveMeeting = false

    var body: some View {
        ZStack {
            VStack {
                NavigationView {
                    List(model.meetings) { meeting in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(meeting.title)
                                    .font(.headline)

                                Spacer()
                                Button(action: {
                                    showActionSheet = true
                                }) {
                                    Text(meeting.isOngoingMeeting ? "Move Meeting here" : "JOIN")
                                }
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.roundedRectangle)
                                .tint(.green)
                                .frame(width: meeting.isOngoingMeeting ? 175 : 80, height: 10, alignment: .trailing)
                            }
                            Text("\(meeting.start.description) - \(meeting.end.description)")
                                .font(.subheadline)
                        }
                        .actionSheet(isPresented: $showActionSheet) {
                            ActionSheet(
                                title: Text("Join Meeting"),
                                buttons: [
                                    .default(Text("Join by Meeting Id"), action: {
                                        moveMeeting = meeting.isOngoingMeeting && model.isMoveMeetingAllowed(meetingId: meeting.id)
                                        meetingInfo = meeting.id
                                        showCallView = true
                                    }),
                                    .default(Text("Join by Meeting Link"), action: {
                                        moveMeeting = meeting.isOngoingMeeting && model.isMoveMeetingAllowed(meetingId: meeting.id)
                                        meetingInfo = meeting.link
                                        showCallView = true
                                    }),
                                    .default(Text("Join by Meeting Number"), action: {
                                        moveMeeting = meeting.isOngoingMeeting && model.isMoveMeetingAllowed(meetingId: meeting.id)
                                        meetingInfo = meeting.sipUrl
                                        showCallView = true
                                    }),
                                    .cancel()
                                ])
                        }
                        .alert("Error", isPresented: $model.showError) {
                            Button("Ok") { }
                        } message: {
                            Text(model.error)
                        }
                    }
                    .navigationBarTitle("Meetings")
                    .navigationViewStyle(StackNavigationViewStyle())
                }
            }
            if model.isCallIncoming {
                IncomingCallView(isShowing: $model.isCallIncoming, call: model.incomingCall, showCallingView: $showCallingView)
            }
        }.onAppear(perform: {
            syncMeetings()
            registerIncomingCallListener()
        })
        .fullScreenCover(isPresented: $showCallView, content: {
            CallingScreenView(callingVM: CallViewModel(joinAddress: meetingInfo, isMoveMeeting: moveMeeting))
        })
        .fullScreenCover(isPresented: $showCallingView){
            CallingScreenView(callingVM: CallViewModel(call: model.incomingCall))
        }
    }

    /// Registers for incoming call event
    func registerIncomingCallListener() {
        model.registerIncomingCall()
    }

    /// Updates the meetings in the model.
    func syncMeetings() {
        model.updateMeetings()
    }

}

@available(iOS 16.0, *)
struct MeetingsHomeView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingsHomeView()
            .previewDevice("iPhone 14 Pro Max")
    }
}

@available(iOS 16.0, *)
struct CallViewControllerView : UIViewControllerRepresentable {
    var callInviteAddress: String
    
    /// Updates the state of the view controller with new data when there's a change in the corresponding SwiftUI view's state.
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }

    /// Creates and returns an instance of `CallViewController` with the provided call invite address.
    func makeUIViewController(context: Context) -> some UIViewController {
        return CallViewController(callInviteAddress: callInviteAddress)
    }
}
