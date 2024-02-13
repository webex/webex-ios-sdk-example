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
                MessagingHomeView()
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Image(systemName: "bubble.left")
                        Text("Messaging")
                    }.tag(0)
                SearchView<SearchSpaceListViewModel>(searchViewModel: searchSpaceViewModel)
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }.tag(1)
                CallingTabView()
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Image(systemName: "phone")
                        Text("Calling")
                    }.tag(2)
                MeetingsHomeView()
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Meetings")
                    }.tag(3)
            }
            .toolbarBackground(.visible, for: .tabBar)
        }.onAppear(perform: registerDevice)
    }

    func registerDevice() {
        Task {
            await model.deviceRegistration()
        }
    }
}

@available(iOS 16.0, *)
#Preview {
    MainTabView()
}
