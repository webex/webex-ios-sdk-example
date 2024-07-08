import SwiftUI
import MessageUI
import WebexSDK
    
class MailViewModel: ObservableObject {
    @Published var isShowing: Bool = false
    var feedback: Feedback = .reportBug
}

struct MailView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: MailViewModel
    
    /// Creates a UIViewController for sending mails with the MFMailComposeViewController
    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([Feedback.recipient])
        
        if let logFileUrl = webex.getLogFileUrl(), let fileContents = NSData(contentsOf: logFileUrl), viewModel.feedback == .reportBug {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .long
            
            let fileName = "webex-sdk-ios-logs-" + dateFormatter.string(from: Date()) + ".zip"
            controller.addAttachmentData(fileContents as Data, mimeType: "application/zip", fileName: fileName)
        }

        return controller
    }
    
    /// Updates the provided UIViewController
    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: UIViewControllerRepresentableContext<MailView>) {
    }

    /// Creates a Coordinator for the UIViewControllerRepresentable
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailView

        /// Initializes a new instance of the MailView parent class
        init(_ parent: MailView) {
            self.parent = parent
        }

        /// Handles the result of the mail composition operation
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            parent.viewModel.isShowing = false
            controller.dismiss(animated: true)
        }
    }
}

