import SwiftUI
import Combine
import WebexSDK


@available(iOS 16.0, *)
class TeamSpaceMemberSearchViewModel: SearchViewModelProtocol {
    typealias ResultType = PersonKS
    @Published var isLoading = false
    @Published var results = [PersonKS]()
    @Published var searchString: String = ""
        
    let webexPeople = WebexPeople()
    var isCallIncoming: Bool = false
    var incomingCall: Call?
    func registerIncomingCall() {}

    /// Holds all subscriptions for Combine publishers to manage the memory and prevent premature deallocation.
    var subscriptions = Set<AnyCancellable>()
    
    /// Initializes the view model, sets up a subscription to the `searchString` publisher, and triggers a filter operation when the `searchString` changes and after a debounce period. The subscription is stored in the `subscriptions` set.
    init() {
        $searchString
            .removeDuplicates()
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.filter(for: value)
            }.store(in: &subscriptions)
    }
    
    /// Filters the list of people based on the given search string, updates the list of results with the filtered people, and sets the `isLoading` status.
    func filter(for searchString: String) {
        self.results = []
        self.isLoading = true
        webexPeople.searchPeopleList(searchString: searchString) { results in
            self.isLoading = false
            self.results = results
        }
    }
}
