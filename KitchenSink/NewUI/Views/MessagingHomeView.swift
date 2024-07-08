import SwiftUI

@available(iOS 16.0, *)
struct MessagingHomeView: View {

    @ObservedObject var model: MessagingHomeViewModel

    @State private var showingProfile = false
    @State private var showingFilter = false
    @State private var showingCallView = false
    @State private var showingCreateNewAlert = false
    @State private var name = ""
    @State private var types = ["Spaces", "Teams"]
    @State private var type = "Spaces"
    var body: some View {
        ZStack {
            VStack {
                NavigationView {
                    VStack {
                        Picker("", selection: $type) {
                            ForEach(types, id: \.self) {
                                Text($0)
                                    .font(.subheadline)
                                    .accessibility(identifier: "segment\($0)")
                            }
                        }
                        .padding(20)
                        .pickerStyle(.segmented)

                        ZStack {
                            if type == "Teams" {
                                List {
                                    ForEach(model.teams) { team in
                                        NavigationLink(destination: TeamSpaceMemberShipView(team: team)) {
                                            VStack(alignment: .leading) {
                                                Text(team.name ?? "")
                                                    .font(.headline)
                                                    .accessibilityIdentifier("listRow-\(String(describing: team.name ?? ""))")
                                                Text(team.created ?? "")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }.onDelete(perform: deleteItems)
                                }.onAppear(perform: showListOfTeams)
                            } else if type == "Spaces" {
                                List(model.spaces) { space in
                                    NavigationLink(destination: SpaceDetailView(space: space)) {
                                        VStack(alignment: .leading) {
                                            HStack {
                                                if space.presenceStatus?.image != "" {
                                                    Image(systemName: space.presenceStatus?.image ?? "person.3.fill")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 30, height: 30)
                                                }
                                                Text(space.name ?? "")
                                                    .font(.headline)
                                                    .accessibilityIdentifier("listRow-\(String(describing: space.name ?? ""))")
                                            }
                                            Text(space.presenceStatus?.title ?? "")
                                                .font(.subheadline)
                                                .foregroundColor(space.presenceStatus?.textColor)
                                        }
                                    }
                                }
                                .accessibilityIdentifier("spacesList")
                            }
                            HStack {
                                CreateNewButton(action: showAlert)
                            }
                            .alert(isPresented: $showingCreateNewAlert, title: "Enter name for new \(type)", textFieldValue: $name, action: createNew)
                            .alert("Success", isPresented: $model.created) {
                                Button("OK") {}
                                    .accessibilityIdentifier("alertOkBtn")
                            } message: {
                                Text("Successfully created \(type)")
                            }
                            
                            if model.showLoading {
                                ActivityIndicatorView()
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                showingProfile.toggle()
                            }) {
                                AsyncImage(url: URL(string: model.profile?.imageUrl ?? "")) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                }
                                .frame(width: 35, height: 35)
                                .cornerRadius(17.5)
                                .overlay(Circle()
                                    .stroke(.green, lineWidth: 2))
                            }
                            .accessibilityIdentifier("settingsButton")
                        }
                        if type == "Spaces" {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    showingFilter.toggle()
                                }) {
                                    Image(systemName: "slider.horizontal.3")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .accessibilityIdentifier("filterSpacesButton")
                                }.foregroundColor(.gray)
                            }
                        }
                    }
                    .alert("Error", isPresented: $model.showError) {
                        Button("Ok") { }
                            .accessibilityIdentifier("errorOkButton")
                    } message: {
                        Text(model.error)
                    }
                    .sheet(isPresented: $showingFilter) {
                        FilterSpaceView(model: model)
                    }
                    .sheet(isPresented: $showingProfile, onDismiss: {
                        showingProfile = false
                    }) {
                        SettingsView(model: SettingsViewModel(profile: model.profile ?? ProfileKS(imageUrl: "", name: "", status: ""), messagingVM: model, mailVM: model.mailVM), phoneServicesViewModel: UCLoginServicesViewModel())
                    }
                    .alert(model.alertTitle , isPresented: $model.showAlert) {
                        if model.shouldDeleteTeam {
                            Button("OK") { model.deleteTeam() }
                                .accessibilityIdentifier("alertOkBtn")
                            Button("Cancel") { }
                                .accessibilityIdentifier("alertCancelButton")
                        }
                        else {
                            Button("Dismiss") {}
                                .accessibilityIdentifier("dismissButton")
                        }
                    } message: {
                        Text(model.alertMessage)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .navigationBarTitle("Messaging", displayMode: .inline)
                }
            }
            if model.isCallIncoming {
                IncomingCallView(isShowing: $model.isCallIncoming, call: model.incomingCall, showCallingView: $showingCallView)
            }
        }
        .onAppear(perform: {
            showListOfSpaces()
            registerIncomingCallListener()
            getMe()
        })
        .onDisappear(perform: stopWatchingPresence)
        .fullScreenCover(isPresented: $showingCallView){
            CallingScreenView(callingVM: CallViewModel(call: model.incomingCall!))
        }

    }
    
    func deleteItems(at offsets: IndexSet) {
        var theItem: TeamKS?
        for index in offsets.makeIterator() {
            theItem = model.teams[index]
        }
        guard let selectedTeam = theItem else { return }
        model.shouldDeleteTeam = true
        model.showAlert(alertTitle: "Please Confirm", alertMessage: "This action will delete the Team", selectedTeam: selectedTeam)
    }
            
    /// Registers for incoming call event
    func registerIncomingCallListener() {
        model.registerIncomingCall()
    }

    /// Fetches and updates the list of spaces using the model.
    func showListOfSpaces() {
        model.getListOfSpaces()
    }

    /// Fetches and updates the list of teams using the model.
    func showListOfTeams() {
        model.getListOfTeams()
    }

    /// Triggers the display of an alert for creating a new item.
    func showAlert() {
        showingCreateNewAlert = true
    }

    /// Creates a new team or space with the given name using the model, depending on the type, and then clears the name.
    func createNew() {
        if type == "Teams" {
            model.createNewTeam(title: name)
        } else {
            model.createNewSpace(title: name)
        }
        name = ""
    }

    /// Fetches and updates the details of the current user using the model.
    func getMe() {
        model.getMe()
    }

    /// Stops watching the presence of the current user using the model.
    func stopWatchingPresence() {
        model.stopWatchingPresence()
    }
}

@available(iOS 16.0, *)
struct MessagingHomeView_Previews: PreviewProvider {
    static var previews: some View {
        MessagingHomeView(model: MessagingHomeViewModel())
            .previewDevice("iPhone 14 Pro Max")
    }
}
