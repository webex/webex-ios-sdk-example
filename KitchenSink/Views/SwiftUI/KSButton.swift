import SwiftUI

@available(iOS 15.0, *)
struct KSButton: View {

    @Environment(\.colorScheme) var colorScheme

    let text: String
    let action: (() -> Void)
    var didTap: Bool

    init(text: String, didTap: Bool = false, action: @escaping (() -> Void )) {
        self.text = text
        self.action = action
        self.didTap = didTap
    }

    var body: some View {
        if colorScheme == .dark {
            Button(action: action, label: {
                Text(text)
                    .padding(.vertical, 12)
                    .padding(.horizontal, -3)
                    .frame(maxWidth: UIScreen.main.bounds.width - 30)
                    .foregroundColor(.black)
            })
            .font(.subheadline)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 15))
            .tint(didTap ? .blue : .white)
        } else {
            Button(action: action, label: {
                Text(text)
                    .padding(.vertical, 10)
                    .padding(.horizontal, -3)
                    .tint(didTap ? .blue : .black)
                    .frame(maxWidth: UIScreen.main.bounds.width - 30)

            })
            .padding(.all, 7.0)
            .font(.subheadline)
            .background(.white)
            .buttonStyle(.borderless)
            .buttonBorderShape(.roundedRectangle(radius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(didTap ? .blue : .black, lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
            .tint(.white)
        }
    }
}

@available(iOS 15.0, *)
struct DarkButtonView_Previews: PreviewProvider {
    static var previews: some View {
        KSButton(text: "FedRAMP Enabled", didTap: false, action: printText)
    }
}

func printText() {
    print("Hello Button Tapped")
}
