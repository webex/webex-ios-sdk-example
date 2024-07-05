import SwiftUI
import WebexSDK

fileprivate enum SpaceSegmentControl: Identifiable, CaseIterable {
    case showSpace, showSpaceReadStatus
    
    var id: Self {
        self
    }
    
    var description: String {
        switch self {
        case .showSpace: return "Space Members"
        case .showSpaceReadStatus: return "Members with Read Status"
        }
    }
}

@available(iOS 16.0, *)
struct SpaceSegmentView: View {
    fileprivate var segment: SpaceSegmentControl
    fileprivate var space: SpaceKS
    fileprivate var viewModel: SpaceDetailViewModel
    var body: some View {
        switch segment {
        case .showSpace:
            SpaceMembershipView(space: space, viewModel: viewModel)
        case .showSpaceReadStatus:
            SpaceReadStatusMembershipView(space: space, viewModel: viewModel)
        }
    }
}

@available(iOS 16.0, *)
struct SpaceDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedSearchItem = PersonKS()
    @State private var selectedOption: SpaceSegmentControl = .showSpace
    @State private var isAlertPresented = false
    @State private var messageViewPresented = false
    @State private var updateAlertPresented = false
    @State private var deleteAlertPresented = false
    @State private var newMessageViewPresented = false
    @State private var isSearchViewPresented = false
    @State private var isSearchViewItemSelected = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var spaceName = ""
    @State var space: SpaceKS
    
    @ObservedObject var spaceDetailVM = SpaceDetailViewModel()
        
    var body: some View {
        VStack(alignment: .leading) {
            HStack{
                Text(space.name ?? "")
                    .font(.title)
                    .foregroundColor(.primary)
            }
            VStack(alignment: .leading) {
                HStack {
                    Text("Space Id: \(space.id ?? "")\nTeamId: \(space.teamId ?? "--")\nSpace Type: \(space.type?.description ?? "")\nCreated date: \(space.created ?? "")\nLast Activity: \(space.lastActivityTime ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
            Divider()
            HStack {
                Text("Space Membership")
                    .font(.title)
                    .foregroundColor(.primary)
                Spacer()
                if selectedOption == .showSpace {
                    Button {
                        isSearchViewPresented = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .accessibilityIdentifier("addMembershipToSpaceButton")
                    }
                    
                }
            }
            Picker("", selection: $selectedOption) {
                ForEach(SpaceSegmentControl.allCases) { option in
                    Text(String(describing: option.description))
                }
            }
            .pickerStyle(.segmented)
            SpaceSegmentView(segment: selectedOption, space: space, viewModel: spaceDetailVM)
        }
        .overlay {
            HStack {
                Spacer()
                CreateNewButton(action: {
                    newMessageViewPresented = true
                }, systemImage: "plus.bubble")
            }
        }
        .sheet(isPresented: $newMessageViewPresented, content: {
            MessageComposerView(space: space)
        })
        .padding([.leading, .trailing])
        .navigationTitle("Space Detail")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        fetchSpacebyId(spaceId: space.id ?? "")
                    }) {
                        Text("Fetch Space by Id")
                    }
                    .accessibility(identifier: "fetchSpaceByIdButton")
                    Button(action: {
                        fetchMeetingSpaceInfo(spaceId: space.id ?? "")
                    }) {
                        Text("Get Space Meeting Info")
                    }
                    .accessibility(identifier: "getSpaceMeetingInfoButton")
                    Button(action: {
                        fetchSpaceReadStatus(spaceId: space.id ?? "")
                    }) {
                        Text("Fetch Space Read Status")
                    }
                    .accessibility(identifier: "fetchSpaceReadStatusButton")
                    Button(action: {
                        self.messageViewPresented = true
                    }) {
                        Text("Show Messages in Space")
                    }
                    .accessibility(identifier: "showMessageInSpaceButton")
                    Button(action: {
                        self.updateAlertPresented = true
                    }) {
                        Text("Update Space Title")
                    }
                    .accessibility(identifier: "updateSpaceTitleButton")
                    Button(action: {
                        self.deleteAlertPresented = true
                    }) {
                        Text("Delete Space")
                    }
                    .accessibility(identifier: "spaceDeleteButton")
                    Button(action: {
                        markSpaceRead(spaceId: space.id ?? "")
                    }) {
                        Text("Mark Space Read")
                    }
                    .accessibility(identifier: "markSpaceReadButton")
                } label: {
                    Label("Menu", systemImage: "ellipsis.circle")
                        .accessibility(identifier: "spacesMenuButton")
                    
                }
                .sheet(isPresented: $messageViewPresented, content: {
                    MessageListView(space: space)
                })
                .alert(alertTitle, isPresented: $isAlertPresented) {
                    Button("Dismiss") { }
                        .accessibility(identifier: "dismissButton")
                } message: {
                    Text(self.alertMessage)
                }
                .alert("Update Space Title", isPresented: $updateAlertPresented) {
                    TextField("", text: $spaceName)
                    Button("Update", action: updateSpaceTitle)
                        .accessibility(identifier: "updateSpaceTitleButton")
                    Button("Cancel", role: .cancel) { }
                        .accessibility(identifier: "updateSpaceTitleCancelButton")
                } message: {
                    Text("Enter the new title of the Space")
                }
                .alert("Please Confirm", isPresented: $deleteAlertPresented) {
                    Button("Delete", action: deleteSpace)
                        .accessibility(identifier: "deleteSpaceAlertButton")
                    Button("Cancel", role: .cancel) { }
                        .accessibility(identifier: "deleteSpaceCancelButton")
                } message: {
                    Text("This action will delete space: \(space.name ?? "")")
                }
                .alert("Error", isPresented: $spaceDetailVM.showError) {
                    Button("Ok") { }
                        .accessibility(identifier: "errorOKButton")
                } message: {
                    Text(spaceDetailVM.error)
                }
                .sheet(isPresented: $isSearchViewPresented) {
                    SpaceMembershipListSearchView<SpaceMembershipListSearchViewModel>(searchViewModel: SpaceMembershipListSearchViewModel(), searchItemSelectAction : { (person, isSelected)  in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            selectedSearchItem = person
                            isSearchViewItemSelected = isSelected
                        }
                    })
                }
                .confirmationDialog("Membership Actions", isPresented: $isSearchViewItemSelected) {
                    Button("By Person Id") {
                        createMembership(personId: selectedSearchItem.id ?? "", spaceId: space.id ?? "", personDisplayName: selectedSearchItem.displayName ?? "")
                    }
                    .accessibility(identifier: "createMembershipPersonIdButton")
                    Button("By Email Address") {
                       addTeamMembershipWithEmail()
                    }
                    .accessibility(identifier: "createMembershipPersonEmailButton")
                }
            }
        }
    }
    
    /// Fetches and updates the list of members in the space using the space detail view model.
    private func refreshMembershipList() {
        spaceDetailVM.getMembershipList(spaceId: space.id ?? "")
    }
    
    /// Creates a new membership with the given person ID, space ID, and person display name using the space detail view model.
    private func createMembership(personId: String, spaceId: String, personDisplayName: String) {
        spaceDetailVM.createMembership(personId: personId, spaceId: spaceId, personDisplayName: personDisplayName) { (alertTitle, alertMessage) in
                self.alertMessage = alertMessage
                self.alertTitle = alertTitle
                isAlertPresented = true
                refreshMembershipList()
        }
        
    }
    
    /// Adds a team membership with the given email, space ID, and person display name using the space detail view model.
    private func addTeamMembershipWithEmail() {
        guard let  email = selectedSearchItem.emails?.first, let personDisplayName = selectedSearchItem.displayName , let spaceId = space.id else { return }
        spaceDetailVM.addTeamMembership(withEmail: email, spaceId: spaceId, personDisplayName: personDisplayName) { (alertTitle, alertMessage) in
            self.alertMessage = alertMessage
            self.alertTitle = alertTitle
            isAlertPresented = true
            refreshMembershipList()
        }
    }
    /// Fetches the meeting space information for the space with the given ID using the space detail view model.
    private func fetchMeetingSpaceInfo(spaceId: String) {
        spaceDetailVM.fetchSpaceMeetingInfo(id: spaceId) { result in
            self.alertMessage = result
            alertTitle = "Meeting Information"
            isAlertPresented = true
        }
    }

    /// Fetches the space with the given ID using the space detail view model.
    private func fetchSpacebyId(spaceId: String) {
        spaceDetailVM.fetchSpaceById(spaceId: spaceId) { result in
            self.alertMessage = result
            alertTitle = "Space Found"
            isAlertPresented = true
        }
    }
    
    /// Fetches the read status for the space with the given ID using the space detail view model.
    private func fetchSpaceReadStatus(spaceId: String) {
        spaceDetailVM.fetchSpaceReadStatus(byId: spaceId) { result in
            self.alertMessage = result
            alertTitle = "Space Read Status"
            isAlertPresented = true
        }
    }
    
    /// Marks the space with the given ID as read using the space detail view model.
    private func markSpaceRead(spaceId: String) {
        spaceDetailVM.markSpaceAsRead(spaceId: spaceId) { result in
            self.alertMessage = result
            alertTitle = "Result"
            isAlertPresented = true
        }
    }

    /// Updates the title of the space with the given ID using the space detail view model.
    private func updateSpaceTitle() {
        guard let spaceId = space.id else { return }
        spaceDetailVM.updateSpaceTitle(spaceId: spaceId, title: spaceName) { result in
            self.alertMessage = result
            alertTitle = "Result"
            isAlertPresented = true
        }
    }
    
    /// Deletes the space with the given ID using the space detail view model.
    private func deleteSpace() {
        guard let spaceId = space.id else { return }
        spaceDetailVM.deleteSpace(spaceId: spaceId) { result in
            self.alertMessage = result
            alertTitle = "Result"
            isAlertPresented = true
            dismiss()
        }
    }
}

@available(iOS 16.0, *)
struct SpaceMembershipView: View {
    @ObservedObject var spaceDetailViewModel: SpaceDetailViewModel
    var space: SpaceKS
    @State private var selectedItem: MembershipKS?
    @State private var deleteMembershipAlertPresented = false
    @State private var showConfirmDialog = false
    @State private var isAlertPresented = false
    @State private var showAllSpaceAndPersonId = false
    @State private var showAllSpaceAndPersonEmail = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    /// Initializes a new instance with the given space and space detail view model.
    init(space: SpaceKS, viewModel: SpaceDetailViewModel) {
        self.space = space
        self.spaceDetailViewModel = viewModel
        getMembershipDetails()
    }
    
    var body: some View {
            List {
                ForEach(spaceDetailViewModel.membershipResults) { membership in
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Display Name:")
                            Text(membership.personDisplayName ?? "")
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        
                        Text("Space ID: \(membership.spaceId ?? "--")\nEmail: \(membership.personEmail?.toString() ?? "--")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityIdentifier("Email-\(membership.personEmail?.toString() ?? "")")
                    .onTapGesture {
                        selectedItem = membership
                        showConfirmDialog.toggle()
                    }
                }
                .onDelete { indexSet in
                    if let deletedItem = indexSet.first.map({ spaceDetailViewModel.membershipResults[$0] }) {
                        selectedItem = deletedItem
                        deleteMembershipAlertPresented = true
                    }
                }
        }
        .accessibilityIdentifier("spaceMembershipListView")
        .confirmationDialog("Membership Actions", isPresented: $showConfirmDialog, titleVisibility: .visible) {
            Button("Fetch Membership by Id") {
                fetchMembership(membershipId: selectedItem?.id ?? "")
            }
            .accessibility(identifier: "fetchMembershipByIdButton")
            Button("Show All Memberships For This Space and PersonId") {
                showAllMembershipForSpaceAndPersonId()
            }
            .accessibility(identifier: "showAllMembershipPersonIdButton")
            Button("Show All Memberships For This Space and PersonEmail") {
                showAllMembershipForSpaceAndPersonEmail()
            }
            .accessibility(identifier: "showAllMembershipPersonEmailButton")
            let isModerator = selectedItem?.isModerator ?? false
            Button(isModerator ? "Remove Moderator" : "Set Moderator") {
                setModerator(membershipId: selectedItem?.id ?? "", isModerator: !isModerator)
            }
            .accessibility(identifier: isModerator ? "removeModeratorButton" : "setModeratorButton")
        }
        .alert(alertTitle, isPresented: $isAlertPresented) {
            Button("Dismiss") { }
            .accessibility(identifier: "dismissButton")
        } message: {
            Text(self.alertMessage)
        }
        .alert("Please Confirm", isPresented: $deleteMembershipAlertPresented) {
            Button("Delete", action: deleteMembership)
                .accessibility(identifier: "deleteMembershipButton")
            Button("Cancel", role: .cancel) { }
                .accessibility(identifier: "deleteMembershipCancelButton")
        } message: {
            Text("This action will delete the membership")
        }
        .sheet(isPresented: $showAllSpaceAndPersonId, content: {
            SpaceAllMembershipListView(spaceDetailVM: spaceDetailViewModel, spaceId: space.id, personId: selectedItem?.personId, personEmail: nil)
        })
        .sheet(isPresented: $showAllSpaceAndPersonEmail, content: {
            SpaceAllMembershipListView(spaceDetailVM: spaceDetailViewModel, spaceId: space.id, personId: nil, personEmail: selectedItem?.personEmail)
        })
        .listStyle(.plain)
        .overlay {
            if spaceDetailViewModel.loading {
                ActivityIndicatorView()
            }
        }
    }

    /// Fetches the membership with the given ID using the space detail view model.
    private func fetchMembership(membershipId: String) {
        spaceDetailViewModel.fetchMembershipById(membershipId: membershipId) { result in
            DispatchQueue.main.async {
                alertTitle = "Fetch Membership"
                alertMessage = result
                isAlertPresented = true
            }
        }
    }
    
    /// Sets the moderator status of the membership with the given ID using the space detail view model.
    private func setModerator(membershipId : String, isModerator: Bool) {
        spaceDetailViewModel.setModerator(membershipId: membershipId, isModerator: isModerator) { result in
            DispatchQueue.main.async {
                self.alertMessage = result
                self.alertTitle = isModerator ? "Set Moderator" : "Remove Moderator"
                isAlertPresented = true
            }
        }
    }
    
    /// Deletes the selected membership using the space detail view model.
    private func deleteMembership() {
        spaceDetailViewModel.deleteMembership(membershipId: selectedItem?.id ?? "") { result in
            DispatchQueue.main.async {
                alertTitle = result
                isAlertPresented = true
                getMembershipDetails()
            }
        }
    }
    
    /// Fetches and updates the list of memberships for the space with the given ID using the space detail view model.
    private func getMembershipDetails() {
        spaceDetailViewModel.getMembershipList(spaceId: space.id ?? "")
    }
    
    /// Sets the flag to show all memberships for the space and person ID to true.
    private func showAllMembershipForSpaceAndPersonId() {
        showAllSpaceAndPersonId = true
    }
    
    /// Sets the flag to show all memberships for the space and person email to true.
    private func showAllMembershipForSpaceAndPersonEmail() {
        showAllSpaceAndPersonEmail = true
    }
}

@available(iOS 16.0, *)
struct SpaceReadStatusMembershipView: View {
    @ObservedObject var spaceDetailViewModel: SpaceDetailViewModel
    var space: SpaceKS
    
    /// Initializes a new instance with the given space and space detail view model.
    init(space: SpaceKS, viewModel: SpaceDetailViewModel) {
        self.space = space
        self.spaceDetailViewModel = viewModel
        getReadStatusMembershipDetails()
    }
    
    var body: some View {
        List {
            ForEach(spaceDetailViewModel.membershipReadStatusResults) { result in
                VStack(alignment: .leading) {
                    Text("Read Status")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(result.displayValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if spaceDetailViewModel.loading {
                ActivityIndicatorView()
            }
        }
    }
    
    /// Fetches and updates the list of memberships with read status for the given space ID using the space detail view model.
    private func getReadStatusMembershipDetails() {
        spaceDetailViewModel.getMembershipListWithReadStatus(spaceId: space.id ?? "")
    }
}

@available(iOS 16.0, *)
struct SpaceAllMembershipListView: View {
    @ObservedObject var spaceDetailViewModel: SpaceDetailViewModel
    var spaceId: String?
    var personId: String?
    var personEmail: EmailAddress?
    
    /// Initializes a new instance with the given space detail view model, space ID, person ID, and person email.
    init(spaceDetailVM: SpaceDetailViewModel, spaceId: String? = nil, personId: String? = nil, personEmail: EmailAddress? = nil) {
        self.spaceDetailViewModel = spaceDetailVM
        getListForAllMebership(spaceId: spaceId, personId: personId, emailAddress: personEmail)
    }
    
    var body: some View {
        List {
            ForEach(spaceDetailViewModel.membershipResults) { membership in
                VStack(alignment: .leading) {
                    HStack {
                        Text("Display Name:")
                        Text(membership.personDisplayName ?? "")
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    
                    Text("Space ID: \(membership.spaceId ?? "--")\nEmail: \(membership.personEmail?.toString() ?? "--")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityIdentifier("spaceAllMembershipListView")
        .listStyle(.plain)
    }
    
    /// Fetches and updates the list of all memberships associated with the provided space ID, person ID, and person email using the space detail view model.
    private func getListForAllMebership(spaceId: String? = nil, personId: String? = nil , emailAddress: EmailAddress? = nil) {
        spaceDetailViewModel.getMembershipList(spaceId: spaceId, personId: personId, personEmail: emailAddress)
    }
}
