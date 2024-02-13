import SwiftUI

@available(iOS 16.0, *)
protocol SearchRowViewProtocol {
    associatedtype ResultType
    var data: ResultType { get }

    init(data: ResultType)
}

@available(iOS 16.0, *)
struct SpaceRowViewCell: View, SearchRowViewProtocol {
    enum ButtonType: Identifiable {
        case message, call
        
        var id: Int {
            hashValue
        }
    }
    
    typealias ResultType = SpaceKS
    
    @State private var buttonType: ButtonType?
    @State var data: SpaceKS
    
    /// Initializes a new instance with the given `SpaceKS` data.
    init(data: SpaceKS) {
        self.data = data
    }

    var body: some View {
        HStack {
            Text(data.name ?? "Not available")
                .font(.headline)
            Spacer()
            KSIconButton(action: showMessageView, image: "bubble.left", foregroundColor: .blue)
            .padding(.trailing)
            KSIconButton(action: showCallView, image: "phone", foregroundColor: .green)
        }
        .sheet(item: $buttonType) { item in
            switch item {
            case .call:
                CallControllerView(space: $data)
            case .message:
                MessageComposerView(space: data)
                Text("")
            }
        }
    }
    
    /// Changes the button type to 'message'. This typically triggers a UI update to display a message view.
    func showMessageView() {
        self.buttonType = .message
    }
    
    /// Function checks, If the data type is 'group', it changes the button type to 'call'.
    func showCallView() {
        self.buttonType = .call
    }
}
