import SwiftUI
import WebexSDK

@available(iOS 16.0, *)
struct SearchView<ViewModel: SearchViewModelProtocol>: View {
    @State private var searchText = ""
    @ObservedObject var searchViewModel: ViewModel
    @State var showCallingView = false

    /// Initializes a new instance and fetches the list of spaces.
    init(searchViewModel: any SearchViewModelProtocol) {
        self.searchViewModel = searchViewModel as! ViewModel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    List(){
                        ForEach(searchViewModel.results) { item in
                            SpaceRowViewCell(data: item as! SpaceKS)
                        }
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        searchViewModel.searchString = searchText
                        registerIncomingCallListener()
                    }
                }
                if searchViewModel.isCallIncoming {
                    IncomingCallView(isShowing: $searchViewModel.isCallIncoming, call: CallKS(call: searchViewModel.incomingCall!), showCallingView: $showCallingView)
                }
            }
            .searchable(text: $searchText, prompt: "Webex")
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationTitle("Search")
            .fullScreenCover(isPresented: $showCallingView){
                CallingScreenView(callingVM: CallViewModel(call: CallKS(call: searchViewModel.incomingCall!)))
            }
        }
        .onChange(of: searchText) { newValue in
            searchViewModel.searchString = newValue
        }
    }

    /// Registers for incoming call event
    func registerIncomingCallListener() {
        searchViewModel.registerIncomingCall()
    }
}
