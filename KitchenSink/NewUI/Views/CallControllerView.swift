import SwiftUI
import WebexSDK

@available(iOS 16.0, *)
struct CallControllerView : UIViewControllerRepresentable {
    @Binding var space: SpaceKS
    
    /// Updates the provided UIKit view controller with new data when there's a change in the corresponding SwiftUI view's state. Currently, this function does nothing.
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
    
    /// Creates and returns a new instance of `CallViewController` with the provided space ID.
    func makeUIViewController(context: Context) -> some UIViewController {
        return CallViewController(space: Space(id: space.id))
    }
}
