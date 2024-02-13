import SwiftUI

@available(iOS 16.0, *)
struct FilterSpaceView: View {

    @Environment(\.dismiss) var dismiss

    @State private var spaceValueType = "Space"
    @State private var max: String = ""
    @State private var teamId: String = ""
    @State private var spaceType: String = "Space Type"
    @State private var sortBy: String = "Sort By"
    @State private var spaceTypeSelected: Bool = false
    @State private var sortBySelected: Bool = false
    @State private var spaceTypeValue: SpaceTypeKS?
    @State private var sortByValue: SortTypeKS?

    var model: MessagingHomeViewModel
    var spaceValueTypes = ["Space", "Read Status"]

    var body: some View {
        VStack {
            HStack {
                Text("Filter Spaces")
                    .font(.largeTitle)
                    .padding(.leading, 15)
                Spacer()
            }

            Picker("", selection: $spaceValueType) {
                ForEach(spaceValueTypes, id: \.self) {
                    Text($0)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 20)
            .pickerStyle(.segmented)

            HStack {
                GroupBox {
                    DisclosureGroup(spaceType, isExpanded: $spaceTypeSelected) {
                        Button("Direct", action: {
                            withAnimation {
                                spaceType = "Direct"
                                spaceTypeValue = .direct
                                spaceTypeSelected.toggle()
                            }
                        })
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        Button("Group", action: {
                            withAnimation {
                                spaceType = "Group"
                                spaceTypeValue = .group
                                spaceTypeSelected.toggle()
                            }
                        })
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                }
                .padding(20)

                Spacer()
                GroupBox {
                    DisclosureGroup(sortBy, isExpanded: $sortBySelected) {
                        Button("Id", action: {
                            withAnimation {
                                sortBy = "Id"
                                sortByValue = .id
                                sortBySelected.toggle()
                            }
                        })
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        Button("Created", action: {
                            withAnimation {
                                sortBy = "Created"
                                sortByValue = .created
                                sortBySelected.toggle()
                            }
                        })
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        Button("Last Activity", action: {
                            withAnimation {
                                sortBy = "Last Activity"
                                sortByValue = .lastActivity
                                sortBySelected.toggle()
                            }
                        })
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                }
                .padding(20)
            }

            TextField("Max number of Spaces", text: $max) {
                endEditing()
            }
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 20)
                .keyboardType(.numberPad)

            TextField("Team Id", text: $teamId) {
                endEditing()
            }
                .textFieldStyle(.roundedBorder)
                .padding(20)

            HStack {
                KSButton(isSmall: true, text: "Clear", action: {
                    resetForm()
                })
                .padding(20)
                Spacer()
                KSButton(isSmall: true, text: "Done", didTap: true, action: {
                    filterSpace()
                })
                .padding(20)
            }
            .padding(.top, 30)
            Spacer()
        }.onTapGesture {
            self.endEditing()
        }
    }

    /// Ends editing for the current text field or text view.
    private func endEditing() {
        UIApplication.shared.endEditing()
    }

    /// Resets the the UI components to default values
    private func resetForm() {
        spaceValueType = "Space"
        max = ""
        teamId = ""
        spaceType = "Space Type"
        sortBy = "Sort By"
        spaceTypeSelected = false
        sortBySelected = false
        spaceTypeValue = nil
        sortByValue = nil
    }

    /// Filters the space based on the set criteria.
    private func filterSpace() {
        if spaceValueType == "Read Status" {
            model.showSpaceReadStatus()
        } else {
            model.filterSpace(teamId: teamId == "" ? nil : teamId, max: max == "" ? nil : Int(max), typeOfSpace: spaceTypeValue, sortBy: sortByValue)
        }
        dismiss()
    }
}

extension UIApplication {
    /// This function is used to end the current editing session
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

@available(iOS 16.0, *)
struct FilterSpaceView_Previews: PreviewProvider {
    static var previews: some View {
        FilterSpaceView(model: MessagingHomeViewModel())
            .previewDevice("iPhone 14 Pro Max")
    }
}
