import SwiftUI
import AVKit

// Mark: CallingControlsView
@available(iOS 16.0, *)
struct CallingControlsView: View {
    @ObservedObject var callingVM: CallViewModel
    @State private var isAudioRoutePickerActive = false
    init(callingVM: CallViewModel) {
        self.callingVM = callingVM
    }
    
    var body: some View {
        HStack {
            let spaceBetweenButtons = 15.0
            CallControlButton(action: updateAudioMuteState, systemImage: self.callingVM.isLocalAudioMuted ? "mic.slash.fill" : "mic.fill", foregroundColor: self.callingVM.isLocalAudioMuted ? Color.red : Color.white, backgroundColor: self.callingVM.isLocalAudioMuted ? Color.white : Color.blue, accessibilityIdentifier: "audioToggleBtn")
            Spacer().frame(width: spaceBetweenButtons)
            CallControlButton(action: updateVideoMuteState, systemImage: self.callingVM.isLocalVideoMuted ? "video.slash.fill" : "video.fill", foregroundColor: self.callingVM.isLocalVideoMuted ? Color.red : Color.white, backgroundColor: self.callingVM.isLocalVideoMuted ? Color.white : Color.blue, accessibilityIdentifier: "videoToggleBtn")
            Spacer().frame(width: spaceBetweenButtons)
            ZStack {
                AudioRoutePicker(isActive: isAudioRoutePickerActive).frame(width: 35, height: 35)
                CallControlButton(action: speakerAction, systemImage: "speaker.wave.1.fill", foregroundColor: Color.white, backgroundColor: .blue, accessibilityIdentifier: "speakerBtn")
            }
            Spacer().frame(width: spaceBetweenButtons)
            CallControlButton(action: moreOptionsAction, systemImage: "ellipsis",foregroundColor: Color.black, backgroundColor: Color.white, accessibilityIdentifier: "moreBtn")
            Spacer().frame(width: spaceBetweenButtons)
            CallControlButton(action: handleEndCall, systemImage: "xmark", foregroundColor: Color.white, backgroundColor: Color.red, accessibilityIdentifier: "endCallBtn")
        }
    }
    
    /// Handles call end action
    func handleEndCall() {
        callingVM.handleEndCall()
    }
    
    /// Handles  call audio state
    func updateAudioMuteState() {
        callingVM.handleMuteCallAction()
    }
    
    /// Handles call video state
    func updateVideoMuteState() {
        callingVM.handleToggleVideoCallAction()
    }
    
    func speakerAction() {
        self.isAudioRoutePickerActive.toggle()
    }
    
    /// Handles to show more option during call
    func moreOptionsAction() {
        callingVM.handleMoreClickAction()
    }
}

@available(iOS 16.0, *)
#Preview {
    CallingControlsView(callingVM: CallViewModel(joinAddress: "", isPhoneNumber: false))
}
