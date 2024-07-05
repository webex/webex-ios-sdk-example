import SwiftUI
@available(iOS 16.0, *)
class DialControlViewModel: ObservableObject
{
    var callViewModel: CallViewModel?
    @Published var showCallingView = false
    @Published var fromCallingScreen = false
    init(callViewModel: CallViewModel? = nil, fromCallingScreen: Bool = false) {
        self.callViewModel = callViewModel
        self.fromCallingScreen = fromCallingScreen
    }
    
    func handleCallAction(phoneNumber: String, isPhoneNumberToggleOn: Bool, isMoveMeetingToggleOn: Bool) {
        if callViewModel?.showDialScreenFromAddCall == true {
            callViewModel?.startAssociatedCall(address: phoneNumber)
        } else if callViewModel?.showDialScreenFromDirectTransfer == true {
            callViewModel?.directTransferCall(toPhoneNumber: phoneNumber)
        } else {
            callViewModel?.joinAddress = phoneNumber
            callViewModel?.isPhoneNumber = isPhoneNumberToggleOn
            callViewModel?.isMoveMeeting = isMoveMeetingToggleOn
            DispatchQueue.main.async { [weak self] in
                self?.showCallingView = true
            }
        }
    }
}
