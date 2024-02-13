import SwiftUI
import WebexSDK

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
            DailCallControllerView()
        case .history:
            HistoryListView()
        }
    }
}

@available(iOS 16.0, *)
struct HistoryListView: View {
    @ObservedObject private var historyListViewModel = HistoryListViewModel()
     
    var body: some View {
        List {
            ForEach(historyListViewModel.fetchResult()) { result in
                HistoryListRowView(history: result)
            }
        }
    }
}


@available(iOS 16.0, *)
struct HistoryListRowView: View {
    @State var history: CallHistoryRecord
    
    var body: some View {
        HStack {
            VStack {
                Text(history.displayName)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(getFormattedCallDateAndDuration(history))
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            KSIconButton(action: call, image: "phone", foregroundColor: .green)
        }
    }
    
    /// Calling method
    private func call() {
        print("Calling ")
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
    
    /// Fetches the call history from Webex phone call history.
    func fetchResult() -> [CallHistoryRecord] {
        return webex.phone.getCallHistory()
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
