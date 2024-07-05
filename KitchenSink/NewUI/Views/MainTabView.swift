import SwiftUI

@available(iOS 16.0, *)
struct MainTabView: View {

    @Environment(\.colorScheme) var colorScheme
    @State private var selection = 0
    @StateObject private var searchSpaceViewModel = SearchSpaceListViewModel()
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model = MainTabViewModel()

    var body: some View {
        TabView(selection: $selection) {
            Group {
                MessagingHomeView(model: MessagingHomeViewModel())
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Image(systemName: "bubble.left")
                        Text("Messaging")
                            .accessibilityIdentifier("messagingTab")
                    }.tag(0)
                SearchView<SearchSpaceListViewModel>(searchViewModel: searchSpaceViewModel)
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                            .accessibilityIdentifier("searchTab")
                    }.tag(1)
                CallingTabView()
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Image(systemName: "phone")
                        Text("Calling")
                            .accessibilityIdentifier("callingTab")
                    }.tag(2)
                MeetingsHomeView()
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Meetings")
                            .accessibilityIdentifier("meetingTab")
                    }.tag(3)
            }
            .toolbarBackground(.visible, for: .tabBar)
        }
        .onAppear(perform: registerDevice)
        .accessibilityIdentifier("mainTab")
    }

    func registerDevice() {
        Task {
            await model.deviceRegistration()
        }
    }
}

@available(iOS 16.0, *)
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .previewDevice("iPhone 14 Pro Max")
    }
}
