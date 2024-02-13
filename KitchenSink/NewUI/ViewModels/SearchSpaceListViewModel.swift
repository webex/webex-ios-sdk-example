import SwiftUI
import Combine
import WebexSDK

@available(iOS 16.0, *)
public protocol SearchViewModelProtocol: ObservableObject {
    associatedtype ResultType:Identifiable
    
    var results: [ResultType] { get }
    var searchString: String { get set }

    func filter(for searchString: String)
}

@available(iOS 16.0, *)
class SearchSpaceListViewModel: SearchViewModelProtocol {
    typealias ResultType = SpaceKS

    @Published var results = [SpaceKS]()
    @Published var searchString: String = ""
    
    var webexSearchType = WebexSpaces()
    
    /// Filters the list of spaces based on the given search string
    func filter(for searchString: String) {
        self.results = []
        self.webexSearchType.filterSpaces(filter: searchString) { [weak self] searchResults in
            for space in searchResults {
                DispatchQueue.main.async {
                    self?.results.append(SpaceKS(id: space.id, name: space.title, created: space.created?.description, type: space.type == .group ? .group : .direct))
                }
            }
        }
    }
    
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
}
