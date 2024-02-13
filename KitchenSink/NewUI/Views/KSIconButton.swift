import SwiftUI

@available(iOS 16.0, *)
struct KSIconButton: View {

    var action: (() -> Void)
    var image: String
    var color: Color
    
    /// Initializes a new instance.
    init(action: @escaping (() -> Void), image: String, foregroundColor: Color) {
        self.action = action
        self.image = image
        self.color = foregroundColor
    }

    var body: some View {
        Button(action: action)
        {
            Image(systemName: image)
                .frame(width: 40, height: 40)
                .foregroundColor(color)
        }
    }
}
