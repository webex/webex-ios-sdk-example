import SwiftUI
import WebexSDK

@available(iOS 16.0, *)
struct WaitingCallView : UIViewControllerRepresentable {

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }

    func makeUIViewController(context: Context) -> some UIViewController {
        return IncomingCallViewController()
    }
}
