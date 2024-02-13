import SwiftUI
import WebexSDK

@available(iOS 16.0, *)
struct SearchView<ViewModel: SearchViewModelProtocol>: View {
    @State private var searchText = ""
    @ObservedObject var searchViewModel: ViewModel
    
    /// Initializes a new instance and fetches the list of spaces.
    init(searchViewModel: any SearchViewModelProtocol) {
        self.searchViewModel = searchViewModel as! ViewModel
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List(){
                    ForEach(searchViewModel.results) { item in
                        SpaceRowViewCell(data: item as! SpaceKS)
                    }
                }
                .buttonStyle(.plain)
                .onAppear {
                    searchViewModel.searchString = searchText
                }
            }
            .searchable(text: $searchText, prompt: "Webex")
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationTitle("Search")
        }
        .onChange(of: searchText) { newValue in
            searchViewModel.searchString = newValue
        }
    }
}
