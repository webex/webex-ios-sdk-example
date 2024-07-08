import SwiftUI

@available(iOS 16.0, *)
struct CreateNewButton: View {

    var action: (() -> Void)
    var systemImage: String

    /// Initializes a new instance with the given action and system image.
    init(action: @escaping (() -> Void), systemImage: String = "plus") {
        self.action = action
        self.systemImage = systemImage
    }

    var body: some View {
        Spacer()
        Button(action: action)
        {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding(10)
                .foregroundColor(Color.white)
                .background(Color.blue)
                .clipShape(Circle())
        }
        .tint(.blue)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 20)
        .padding(.trailing, 25)
        .accessibilityIdentifier("createNewButton")
    }
}
