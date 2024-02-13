import SwiftUI
import WebexSDK
import Combine

@available(iOS 16.0, *)
struct TeamSpaceMemberShipView: View {
    @ObservedObject var teamMemberShipViewModel = TeamSpaceMemberShipViewModel()
    @StateObject var teamSpaceMemberSearchViewModel = TeamSpaceMemberSearchViewModel()
    @State private var selectedItem: TeamMembershipKS?
    @State private var selectedSearchItem = PersonKS()
    @State private var isAlertPresented = false
    @State private var showConfirmDialog = false
    @State private var updateAlertPresented = false
    @State private var addSpaceAlertPresented = false
    @State private var isSearchViewPresented = false
    @State private var isSearchViewItemSelected = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var spaceName = ""
    @State private var teamTitle = ""

    private var emptyData = false
    var team: TeamKS

    /// Initializes a new instance with the given team.
    init(team: TeamKS) {
        self.team = team
        getTeamMemberShipList()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(team.name ?? "")
                    .font(.title)
                    .foregroundColor(.primary)
            }
            VStack(alignment: .leading) {
                HStack {
                    Text("Team Id: \(team.id ?? "")\nCreated Date: \(team.created ?? "")")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Divider()
            HStack {
                Text("Team Membership")
                    .font(.title)
                    .foregroundColor(.primary)
                Spacer()
                Button {
                    isSearchViewPresented = true
                } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                }
                
            }
            List {
                ForEach(teamMemberShipViewModel.teamMembershipResults) { membership in
                    VStack(alignment: .leading) {
                        Text("Display Name: \(membership.personDisplayName ?? "")")
                            .foregroundColor(.primary)
                            .font(.subheadline)
                        Text("Email: \(membership.personEmail?.toString() ?? "--")")
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .onTapGesture {
                                selectedItem = membership
                                showConfirmDialog.toggle()
                            }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Team Detail")
            .confirmationDialog("Membership Actions", isPresented: $showConfirmDialog, titleVisibility: .visible) {
                Button("Fetch Membership by Id") {
                    fetchTeamMembership(byId: selectedItem?.id ?? "")
                }
                let isModerator = selectedItem?.isModerator ?? false
                Button(isModerator ? "Remove Moderator" : "Set Moderator") {
                    setModerator(byId: selectedItem?.id ?? "", isModerator: !isModerator)
                }
            }
            .alert(alertTitle, isPresented: $isAlertPresented) {
                Button("Dismiss") { }
            } message: {
                Text(self.alertMessage)
            }
            .alert("Update Team Title", isPresented: $updateAlertPresented) {
                TextField("", text: $teamTitle)
                Button("Update", action: updateTeamTitle)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter the new name of the Team")
            }
            
            .alert("Add Space", isPresented: $addSpaceAlertPresented) {
                TextField("", text: $spaceName)
                Button("Add", action: addSpaceToTeam)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter the name of the new Space")
            }
            .sheet(isPresented: $isSearchViewPresented) {
                TeamSpaceMemberSearchView<TeamSpaceMemberSearchViewModel>(searchViewModel: teamSpaceMemberSearchViewModel,  searchItemSelectAction: { (person, isSelected)  in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        selectedSearchItem = person
                        isSearchViewItemSelected = isSelected
                    }
                })
            }
            .confirmationDialog("Membership Actions", isPresented: $isSearchViewItemSelected) {
                Button("By Person Id") {
                    createTeamMembership(personId: selectedSearchItem.id ?? "", teamId: selectedItem?.teamId ?? "", personDisplayName: selectedSearchItem.displayName ?? "")
                }
                Button("By Email Address") {
                    addTeamMembershipWithEmail()
                }
            }
            .overlay {
                    if teamMemberShipViewModel.isLoading {
                        ActivityIndicatorView()
                    }
             }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            addSpaceAlertPresented = true
                        }) {
                            Text("Add Space to Team")
                        }
                        Button(action: {
                            fetchTeamById(teamId: team.id ?? "")
                        }) {
                            Text("Fetch Team by Id")
                        }
                        Button(action: {
                            updateAlertPresented = true
                        }) {
                            Text("Update Team Name")
                        }
                    } label: {
                        Label("Team Actions", systemImage: "ellipsis.circle")
                    }
                }
            }
    }
    
    /// Fetches the team membership list for the given team ID using the team membership view model.
    private func getTeamMemberShipList(){
        teamMemberShipViewModel.teamMembershipList(byId: team.id ?? "")
    }
 
    /// Adds a space to the team with the given team ID using the team membership view model.
    private func addSpaceToTeam() {
        guard let teamId = team.id else { return }
        teamMemberShipViewModel.addSpaceToTeam(title: spaceName, teamId: teamId) { alertTitle, alertMessage in
            self.alertMessage = alertMessage
            self.alertTitle = alertTitle
            isAlertPresented = true
        }
    }
    
    /// Fetches the team with the given team ID using the team membership view model.
    private func fetchTeamById(teamId: String) {
        guard let teamId = team.id else { return }
        teamMemberShipViewModel.fetchTeamById(teamId: teamId) { alertTitle, alertMessage in
            self.alertMessage = alertMessage
            self.alertTitle = alertTitle
            isAlertPresented = true
        }
    }
    
    /// Updates the title of the team with the given team ID using the team membership view model.
    private func updateTeamTitle() {
        guard let teamId = team.id else { return }
        teamMemberShipViewModel.updateTeamName(teamId: teamId, title: teamTitle) { (alertTitle, alertMessage) in
            self.alertMessage = alertMessage
            self.alertTitle = alertTitle
            isAlertPresented = true
        }
    }
    
    /// Fetches the team membership with the given ID using the team membership view model.
    private func fetchTeamMembership(byId id: String) {
        teamMemberShipViewModel.fetchTeamMemberShip(byId: id) { result in
            self.alertMessage = result
            self.alertTitle = "Fetch Team Membership"
            isAlertPresented = true
        }
    }
    
    /// Sets the moderator status of the team membership with the given ID using the team membership view model.
    private func setModerator(byId id: String, isModerator: Bool) {
        teamMemberShipViewModel.setModerator(teamMembershipId: id, isModerator: isModerator) { result in
            self.alertMessage = result
            self.alertTitle = isModerator ? "Set Moderator" : "Remove Moderator"
            isAlertPresented = true
        }
    }
    
    /// Creates a new team membership with the given person ID, team ID, and person display name using the team membership view model.
    private func createTeamMembership(personId: String, teamId: String, personDisplayName: String) {
        teamMemberShipViewModel.createTeamMembership(withPersonId: personId, teamId: teamId, personDisplayName: personDisplayName) { (alertTitle, alertMessage) in
            self.alertMessage = alertMessage
            self.alertTitle = alertTitle
            isAlertPresented = true
        }
        refreshList()
    }
    
    /// Adds a team membership with the given email, team ID, and person display name using the team membership view model.
    private func addTeamMembershipWithEmail() {
        guard let  email = selectedSearchItem.emails?.first, let personDisplayName = selectedSearchItem.displayName , let teamId = team.id else { return }
        teamMemberShipViewModel.addTeamMembership(withEmail: email, teamId: teamId, personDisplayName: personDisplayName) { (alertTitle, alertMessage) in
            self.alertMessage = alertMessage
            self.alertTitle = alertTitle
            isAlertPresented = true
        }
        refreshList()
    }
    
    /// Refreshes the team membership list by fetching it again.
    private func refreshList() {
        getTeamMemberShipList()
    }
}
