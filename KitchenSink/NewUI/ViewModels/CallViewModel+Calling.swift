import SwiftUI

// WxC/CUCM calling related API's and  API calls

@available(iOS 16.0, *)
extension CallViewModel
{
    // Shows dial screen to add call.
    func showDialScreenForAddCall() {
        DispatchQueue.main.async { [weak self] in
            self?.showMoreOptions = false
            self?.showDialScreenFromAddCall = true
        }
    }
    
    // Shows dial screen to direct transfer call (blind transfer)
    func showDialScreenForDirectTransferCall() {
        DispatchQueue.main.async { [weak self] in
            self?.showMoreOptions = false
            self?.showDialScreenFromDirectTransfer = true
        }
    }
    
    // Switches to Audio/Video call.
    func switchTheCallToVideoOrAudio()
    {
        isAudioOnly ? currentCall?.switchToVideoCall { result in } : currentCall?.switchToAudioCall { result in }
    }
    
    // Starts the associated call with the given address.
    func startAssociatedCall(address: String) {
        DispatchQueue.main.async { [weak self] in
            self?.addedCall = true
            self?.associatedCallTitle = self?.callTitle ?? ""
            self?.callTitle = address
            self?.callingLabel = "Calling..."
            self?.showDialScreenFromAddCall = false
        }
        
        currentCall?.startAssociatedCall(dialNumber: address, associationType: .Transfer, isAudioCall: true, completionHandler: { [weak self] result in
            switch result {
            case .success(let call):
                self?.currentCallAssociatedCall = self?.currentCall
                self?.currentCall = call
                self?.updateNameLabels(connected: false)
                self?.registerForCallStatesCallbacks(call: self?.currentCall)
            case .failure(let error):
                self?.showError("addCall failed" , "\(error)")
            }
        })
    }
    
    // Merges the call with the other call.
    func mergeCall() {
        DispatchQueue.main.async { [weak self] in
            self?.showMoreOptions = false
        }
        self.currentCall?.mergeCall(targetCallId: currentCallAssociatedCall?.callId ?? "")
    }
    
    // Transfers the call to the other call and current call.(consult Transfer)
    func transferCall() {
        self.currentCallAssociatedCall?.transferCall(toCallId: currentCall?.callId ?? "")
        DispatchQueue.main.async { [weak self] in
            self?.showMoreOptions = false
            self?.addedCall = false
        }
    }
    
    // Blind transfers the call to the other call and ends the current call.
    func directTransferCall(toPhoneNumber: String) {
        DispatchQueue.main.async { [weak self] in
            self?.showDialScreenFromDirectTransfer = false
        }
        currentCall?.directTransferCall(toPhoneNumber: toPhoneNumber, completionHandler: { [weak self] error in
            if error == nil
            {
                // need not do anything. Internally it will trigger callDisconnected
            }
            else {
                self?.showError("direct Transfer Call", "\(String(describing: error))")
            }
        })
    }
    
    // Resumes the other call and puts the current call on hold.
    func resumeCall(fromAssociatedCall: Bool = false) {
        currentCall?.holdCall(putOnHold: true)
        if fromAssociatedCall && currentCallAssociatedCall != nil{
            (currentCall, currentCallAssociatedCall) = (currentCallAssociatedCall, currentCall)
        } else {
            (currentCall, secondCall) = (secondCall, currentCall) // swap call objects
            (currentCallAssociatedCall, secondCallAssociatedCall) = (currentCallAssociatedCall, secondCallAssociatedCall) // swap associated call objects
        }
        self.updateNameLabels(connected: true)
        registerForCallStatesCallbacks(call: secondCall)
        registerForCallStatesCallbacks(call: currentCall)
        currentCall?.holdCall(putOnHold: false)
        let addedCall = self.addedCall
        DispatchQueue.main.async { [weak self] in
            self?.addedCall = !addedCall
            self?.addedCall = addedCall
        }
    }
    
    // Hold the current call and accepts the incoming call
    func holdAndAcceptSecondIncomingCall(call: CallProtocol) {
        registerForCallStatesCallbacks(call: call)
        self.secondCall = self.currentCall
        self.currentCall = call
        self.currentCall?.answer(selfVideoView: nil, remoteVideoViewRepresentable: nil, screenShareView: nil, isMoveMeeting: false) { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.secondIncomingCall = true
                }
            }
            else {
                self.currentCall =  self.secondCall
                self.secondCall = nil
                AppDelegate.shared.callKitManager?.reportEndCall(uuid: call.uuid)
            }
        }
    }
}
