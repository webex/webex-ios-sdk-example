import SwiftUI

@available(iOS 16.0, *)
struct MessagingHomeView: View {

    @ObservedObject var model = MessagingHomeViewModel()
    @ObservedObject var mailVM = MailViewModel()

    @State private var showingProfile = false
    @State private var showingFilter = false
    @State private var showingCreateNewAlert = false
    @State private var name = ""
    @State private var types = ["Spaces", "Teams"]
    @State private var type = "Spaces"

    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    Picker("", selection: $type) {
                        ForEach(types, id: \.self) {
                            Text($0)
                                .font(.subheadline)
                        }
                    }
                    .padding(20)
                    .pickerStyle(.segmented)

                    ZStack {
                        if type == "Teams" {
                            List(model.teams) { team in
                                NavigationLink(destination: TeamSpaceMemberShipView(team: team)) {
                                    VStack(alignment: .leading) {
                                        Text(team.name ?? "")
                                            .font(.headline)
                                        Text(team.created ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
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
                                        }
                                        Text(space.presenceStatus?.title ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(space.presenceStatus?.textColor)
                                    }
                                }
                            }
                        } 
                        HStack {
                            CreateNewButton(action: showAlert)
                        }
                        .alert(isPresented: $showingCreateNewAlert, title: "Enter name for new \(type)", textFieldValue: $name, action: createNew)
                        .alert(isPresented: $model.created) {
                            Alert(title: Text("Successfully created \(type)"))
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
                            }.foregroundColor(.gray)
                        }
                    }
                }
                .alert("Error", isPresented: $model.showError) {
                    Button("Ok") { }
                } message: {
                    Text(model.error)
                }
                .sheet(isPresented: $showingFilter) {
                    FilterSpaceView(model: model)
                }
                .sheet(isPresented: $showingProfile) {
                    SettingsView(model: SettingsViewModel(profile: model.profile ?? ProfileKS(imageUrl: "", name: "", status: ""), messagingVM: model), mailVM: mailVM)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .navigationBarTitle("Messaging", displayMode: .inline)
            }
        }
        .onAppear(perform: {
            getMe()
            showListOfSpaces()
        })
        .onDisappear(perform: stopWatchingPresence)
        .fullScreenCover(isPresented: $model.isLoggedOut, content: {
            LoginView()
        })

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
        MessagingHomeView()
            .previewDevice("iPhone 14 Pro Max")
    }
}
