import SwiftUI
import WebexSDK
import ReplayKit
import AVKit

enum KSSegmentedControl: CaseIterable, Identifiable {
    case call, history
    
    var id: Self {
        self
    }
    var description: String {
        switch self {
        case .call:
            return "Call"
        case .history:
            return "History"
        }
    }
}

@available(iOS 16.0, *)
struct CallingTabView: View {
    @State var selectedOption: KSSegmentedControl = .call
    
    var body: some View {
        NavigationView {
            VStack {
                    Picker("", selection: $selectedOption) {
                        ForEach(KSSegmentedControl.allCases) { option in
                            Text(String(describing: option.description))
                        }
                    }
                    .pickerStyle(.segmented)
                     SegmentView(segment: selectedOption)
                    .navigationViewStyle(StackNavigationViewStyle())
                    .navigationBarTitle("Calling", displayMode: .inline)
                    .accessibilityIdentifier("callSegment")
                Spacer()
            }
        }
    }
}

@available(iOS 16.0, *)
struct SegmentView: View {
    var segment: KSSegmentedControl
    
    var body: some View {
        switch segment {
        case .call:
            DialControlView(viewModel: DialControlViewModel(), phoneServicesViewModel: UCLoginServicesViewModel())
        case .history:
            HistoryListView()
        }
    }
}

@available(iOS 16.0, *)
struct HistoryListView: View {
    @StateObject private var historyListViewModel = HistoryListViewModel()
     
    var body: some View {
        List {
            ForEach(historyListViewModel.fetchResult()) { result in
                HistoryListRowView(history: result)
                    .accessibilityIdentifier("historyList")
            }
            .onDelete(perform: deleteRows)
        }
        .task {
            await historyListViewModel.fetch()
        }
    }
    
    private func deleteRows(at offsets: IndexSet) {
        historyListViewModel.delete(at: offsets)
    }
}


@available(iOS 16.0, *)
struct HistoryListRowView: View {
    @State var history: CallHistoryRecord
    @State private var showCallingView = false
    
    var body: some View {
        HStack {
            if history.isMissedCall {
                Image("missed-call")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            else if history.callDirection == .outgoing {
                Image("outgoing-call")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            else if history.callDirection == .incoming {
                Image("incoming-call")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            
            VStack {
                Text(history.displayName)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(getFormattedCallDateAndDuration(history))
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            KSIconButton(action: call, image: "phone", foregroundColor: .green)
                .accessibilityIdentifier("dial")
        }
        .fullScreenCover(isPresented: $showCallingView){
            CallingScreenView(callingVM: CallViewModel(joinAddress: history.callbackAddress, isPhoneNumber: history.isPhoneNumber))
        }
    }
    
    /// Calling method
    private func call() {
        self.showCallingView = true
    }
    
    /// Formats and returns the start time and duration of the given call history record as a string.
    private func getFormattedCallDateAndDuration(_ callHistoryRecord: CallHistoryRecord) -> String {
        
        var startTimeAndDuration = ""
        
        let duration = DateUtils.getReadableDuration(durationInSeconds: callHistoryRecord.duration)
        
        if let startDateTime = DateUtils.getReadableDateTime(date: callHistoryRecord.startTime) {
            startTimeAndDuration = startDateTime
        }
        
        if let duration = duration {
            startTimeAndDuration = [startTimeAndDuration, duration].joined(separator: " - ")
        }
        
        return startTimeAndDuration
    }
}


@available(iOS 16.0, *)
class HistoryListViewModel: ObservableObject {
    
    @Published private(set) var callHistory: [CallHistoryRecord] = []
    
    init() {
        // Assign the callback to update this instance directly
        webex.phone.onCallHistoryEvent = { [weak self] event in
            switch event {
            case .syncCompleted:
                self?.refreshCallHistory()
            case .removed(let recordIds):
                self?.removeRecords(with: recordIds)
            case .removeFailed:
                // Handle remove failed if needed
                break
            @unknown default:
                fatalError()
            }
        }
    }
    
    func fetch() async {
        // Initial fetch
        refreshCallHistory()
    }
    
    private func refreshCallHistory() {
        DispatchQueue.main.async {
            self.callHistory = webex.phone.getCallHistory()
        }
    }
    
    /// Fetches the call history from the local property.
    func fetchResult() -> [CallHistoryRecord] {
        return callHistory
    }
    
    /// Deletes call history records at the specified offsets.
    func delete(at offsets: IndexSet) {
        let recordsToDelete = offsets.compactMap{ callHistory[$0].recordId ?? ""}
        webex.phone.removeCallHistoryRecords(recordIds: recordsToDelete)
    }
    
    private func removeRecords(with recordIds: [String]) {
        guard !recordIds.isEmpty else { return }
        DispatchQueue.main.async {
            self.callHistory.removeAll { record in
                if let id = record.recordId {
                    return recordIds.contains(id)
                }
                return false
            }
        }
    }
}

@available(iOS 16.0, *)
struct DailCallControllerView : UIViewControllerRepresentable {
    /// Updates the provided UIKit view controller with new data when there's a change in the corresponding SwiftUI view's state.
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }

    /// Creates and returns a new instance of `DialCallViewController`.
    func makeUIViewController(context: Context) -> some UIViewController {
        return DialCallViewController()
    }
}

extension CallHistoryRecord: Identifiable {}
