import SwiftUI

@available(iOS 16.0, *)
public struct ImagePickerView: UIViewControllerRepresentable {

    private let sourceType: UIImagePickerController.SourceType
    private let onImagePickedInfo: ([UIImagePickerController.InfoKey: Any]) -> Void
    @Environment(\.presentationMode) private var presentationMode

    /// Initializes a new instance with the given image picker source type
    public init(sourceType: UIImagePickerController.SourceType, onImagePickedInfo: @escaping ([UIImagePickerController.InfoKey: Any]) -> Void) {
        self.sourceType = sourceType
        self.onImagePickedInfo = onImagePickedInfo
    }

    /// Creates and returns a new `UIImagePickerController`
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = self.sourceType
        picker.delegate = context.coordinator
        return picker
    }

    /// Updates the provided `UIImagePickerController` with new data.
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    /// Creates and returns a new `Coordinator`
    public func makeCoordinator() -> Coordinator {
        Coordinator(
            onDismiss: { self.presentationMode.wrappedValue.dismiss() },
            onImagePickedInfo: self.onImagePickedInfo
        )
    }
    
    /// The `Coordinator` class is a delegate for `UIImagePickerController`.
    final public class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

        private let onDismiss: () -> Void
        private let onImagePickedInfo: ([UIImagePickerController.InfoKey: Any]) -> Void

        /// Initializes a new instance
        init(onDismiss: @escaping () -> Void, onImagePickedInfo: @escaping ([UIImagePickerController.InfoKey: Any]) -> Void) {
            self.onDismiss = onDismiss
            self.onImagePickedInfo = onImagePickedInfo
        }

        /// This function is called when an image is picked.
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            self.onImagePickedInfo(info)
            self.onDismiss()
        }
        
        /// This function is called when the picker is cancelled.
        public func imagePickerControllerDidCancel(_: UIImagePickerController) {
            self.onDismiss()
        }

    }
}
