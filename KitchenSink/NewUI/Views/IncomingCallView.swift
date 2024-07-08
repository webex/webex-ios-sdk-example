import SwiftUI

@available(iOS 16.0, *)
struct IncomingCallView: View {
    @Environment(\.colorScheme) var colorScheme

    @Binding var isShowing: Bool
    var call: CallKS?
    @Binding var showCallingView: Bool

    var body: some View {

        HStack() {
            VStack {
                Text("Incoming Call..")
                    .font(.callout)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .accessibilityIdentifier("incomingCallAlert")

                HStack {
                    Text(call?.title ?? "Unknown Caller")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .light ? .black : .white)
                        .padding(.horizontal, 5)

                    Button(action: {
                        print("Call rejected")
                        self.isShowing = false
                        rejectCall()
                    }) {
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding()
                    }
                    .accessibilityIdentifier("rejectBtn")
                    .padding(.all, 5)
                    .background(Color.red)
                    .clipShape(Circle())

                    Button(action: {
                        print("Call accepted")
                        self.isShowing = false
                        self.showCallingView = true
                    }) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding()
                    }
                    .accessibilityIdentifier("acceptBtn")
                    .background(Color.green)
                    .clipShape(Circle())
                }
            }
            .frame(width: 300, height: 150)
            .background(colorScheme == .light ? .white : .black)
            .cornerRadius(20)
            .shadow(radius: 20)
            .transition(.slide)
        }
    }
    
    /// Rejects the incoming call
    func rejectCall() {
        guard let call = call else {
            print("Call is nil")
            return
        }
        call.reject(completionHandler: { error in
            if error == nil {
                print("Incoming call rejected")
            }
            else {
                print("error: \(String(describing: error))")
            }
        })
    }
}
