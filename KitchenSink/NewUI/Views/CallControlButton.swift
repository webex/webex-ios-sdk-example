import SwiftUI

@available(iOS 16.0, *)
struct CallControlButton: View {


    var action: (() -> Void)
    var systemImage: String
    var backgroundColor: Color
    var foregroundColor: Color
    var paddingSpace: CGFloat
    var imageWidth: CGFloat
    var imageHeight: CGFloat
    var accessibilityIdentifier: String
    init(action: @escaping (() -> Void), systemImage: String = "plus", foregroundColor: Color = Color.black, backgroundColor: Color = Color.white, paddingSpace: CGFloat = 15, imageWidth: CGFloat = 20, imageHeight: CGFloat = 20, accessibilityIdentifier: String = "callingBtn") {
        self.action = action
        self.systemImage = systemImage
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.paddingSpace = paddingSpace
        self.imageHeight = imageHeight
        self.imageWidth = imageWidth
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var body: some View {
        Button(action: action)
        {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: imageWidth, height: imageHeight)
                .padding(paddingSpace)
                .foregroundColor(foregroundColor)
                .background(backgroundColor)
                .clipShape(Circle()).overlay(Circle().stroke(.gray, lineWidth: 0.5))
        }
        .tint(backgroundColor)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}
