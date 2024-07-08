import SwiftUI
import WebexSDK
import Combine

@available(iOS 16.0, *)
struct SpaceMembershipListSearchView<ViewModel: SearchViewModelProtocol>: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @ObservedObject var searchViewModel: ViewModel
    var onSearchItemSelected: (PersonKS, Bool) -> Void
    
    /// Initializes a new instance with a given search view model that conforms to `SearchViewModelProtocol`.
    init(searchViewModel: any SearchViewModelProtocol, searchItemSelectAction: @escaping (PersonKS, Bool)-> Void) {
        self.searchViewModel = searchViewModel as! ViewModel
        onSearchItemSelected = searchItemSelectAction
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(searchViewModel.results) { item in
                        let data = getType(item: item)
                        VStack(alignment: .leading) {
                            Text(data.displayName ?? "")
                                .font(.title3)
                                .foregroundColor(.primary)
                            Text(data.emails?.first?.toString() ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .accessibilityIdentifier("\(data.emails?.first?.toString() ?? "")")
                        }.onTapGesture {
                            onSearchItemSelected(data,true)
                            dismiss()
                        }
                    }
                }
                .accessibilityIdentifier("spaceMembershipSearchView")
                .listStyle(.plain)
                .onAppear {
                    searchViewModel.searchString = searchText
                }
            }
            .searchable(text: $searchText, prompt: "Search by name or email")
            .accessibilityIdentifier("searchTextField")
            .navigationTitle("Search Contacts")
            .onChange(of: searchText) { newValue in
                searchViewModel.searchString = newValue
            }
        }
       }
    
    /// Takes an item of any type and attempts to cast it as a `PersonKS` object.
    private func getType(item: Any) -> PersonKS {
        if let person = item as? PersonKS {
            return person
        }
       return PersonKS()
    }
}
