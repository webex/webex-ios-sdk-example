import SwiftUI

@available(iOS 16.0, *)
struct MeetingsHomeView: View {

    @ObservedObject var model = MeetingsHomeViewModel()
    @State var showActionSheet = false
    @State var showCallView = false
    @State var meetingInfo = ""

    var body: some View {
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
                                Text("JOIN")
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.roundedRectangle)
                            .tint(.green)
                            .frame(width: 80, height: 10, alignment: .trailing)
                        }
                        Text("\(meeting.start.description) - \(meeting.end.description)")
                            .font(.subheadline)
                    }
                    .actionSheet(isPresented: $showActionSheet) {
                        ActionSheet(
                            title: Text("Join Meeting"),
                            buttons: [
                                .default(Text("Join by Meeting Id"), action: {
                                    showCallView = true
                                    meetingInfo = meeting.id
                                }),
                                .default(Text("Join by Meeting Link"), action: {
                                    showCallView = true
                                    meetingInfo = meeting.link
                                }),
                                .default(Text("Join by Meeting Number"), action: {
                                    showCallView = true
                                    meetingInfo = meeting.sipUrl
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
        }.onAppear(perform: syncMeetings)
            .sheet(isPresented: $showCallView, content: {
                CallViewControllerView(callInviteAddress: meetingInfo)
            })
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
