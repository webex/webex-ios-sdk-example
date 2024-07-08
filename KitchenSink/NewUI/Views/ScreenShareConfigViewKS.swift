import SwiftUI
import AVKit
import ReplayKit

@available(iOS 16.0, *)
struct ScreenShareConfigViewKS: View {
    @State private var isAlertPresented = false
    @State private var selection = "Default"
    @State private var enableAudio = false
    @ObservedObject var callingVM: CallViewModel
    
    init(callingVM: CallViewModel) {
        self.callingVM = callingVM
    }
    
    let pickerOptions = ["Default", "Optimise for text and images", "Optimise for motion and video"]
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(Color.gray) // apply border if needed
            .background(.background)
            .overlay(
                VStack {
                    Spacer()
                    Text("Screenshare Config")
                        .fontWeight(.bold)
                        .font(.subheadline)
                    Picker("Options", selection: $selection) {
                        ForEach(0 ..< pickerOptions.count, id:\.self) {
                            Text(self.pickerOptions[$0]).tag($0)
                                .font(.system(size: 16))
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    
                    
                    Toggle("Enable Audio", isOn: $enableAudio)
                        .padding(.bottom,10)
                        .padding(.horizontal,40)
                    Spacer(minLength: 20)
                        HStack {
                            Spacer()
                            Button(action: {
                                callingVM.shareConfig.isSendingAudio = enableAudio
                                callingVM.shareConfig.selectedOption = selection
                                callingVM.shouldShowScreenConfig = false
                                callingVM.updateScreenShareConfig()
                            }) {
                                Text("OK")
                                    .padding(10)
                                    .foregroundColor(.white)
                                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.blue))
                            }
                            .accessibilityIdentifier("okBtn")
                            .frame(height: 30)

                            Spacer()
                            Button(action: {
                                callingVM.shouldShowScreenConfig = false
                            }) {
                                Text("Cancel")
                                    .padding(10)
                                    .foregroundColor(.white)
                                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.red))
                            }
                            .accessibilityIdentifier("cancelBtn")
                            .frame(height: 30)
                            
                            Spacer()
                        }
                     Spacer(minLength: 20)
                }
            )
    }
}


@available(iOS 16.0, *)
struct BroadcastScreenShareView: UIViewRepresentable {
    class Coordinator {
        var broadcastPicker: RPSystemBroadcastPickerView?
        
        func buttonTap() {
            DispatchQueue.main.async { [weak self] in
                if let button = self?.broadcastPicker?.subviews.compactMap({ $0 as? UIButton }).first {
                    button.sendActions(for: .touchUpInside)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
            var broadcastBundleId = ""
            if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
               let keys = NSDictionary(contentsOfFile: path) as? [String: String] {
                broadcastBundleId = keys["broadcastBundleId"] ?? ""
            }
            
            let broadcastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            broadcastPicker.preferredExtension = broadcastBundleId
            broadcastPicker.showsMicrophoneButton = false
            
            context.coordinator.broadcastPicker = broadcastPicker
            
            return broadcastPicker
    }
    
    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            context.coordinator.buttonTap()
        }
    }
}
