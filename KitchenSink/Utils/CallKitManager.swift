import UIKit
import CallKit
import AVFoundation
import WebexSDK


protocol CallKitManagerDelegate : AnyObject {
    // these delegate functions will be called when user perform actions on native callkit interface
    func callDidEnd()
    func callDidHold(isOnHold : Bool)
    func callDidFail()
    func muteButtonToggle()
}

class CallKitManager: NSObject, CXProviderDelegate {

    var provider : CXProvider?
    var callController : CXCallController?
    var currentCall : UUID?
    var call: Call?
    var sender: String = ""
    weak var delegate : CallKitManagerDelegate?
    
    override init() {
        super.init()
        providerAndControllerSetup()
    }
    
    deinit {
        provider?.invalidate()
    }
    
    
    func reportIncomingCallFor(uuid: UUID, sender: String, completion: @escaping () -> Void ) {
        currentCall = uuid
        self.sender = sender
        print("push uuuid: \(currentCall?.uuidString ?? "")")
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle.init(type: CXHandle.HandleType.phoneNumber, value: sender)
        weak var weakSelf = self
        provider?.reportNewIncomingCall(with: uuid, update: update, completion: { (error : Error?) in
            if error != nil {
                weakSelf?.delegate?.callDidFail()
                print("reportNewIncomingCall error \(error?.localizedDescription ?? "")")
            }
            else {
                print("reportNewIncomingCall success" )
                weakSelf?.currentCall = uuid
            }
            completion()
        })
    }
    
    func reportEndCall() {
        if let unwrappedCurrentCall = currentCall {
            provider?.reportCall(with: unwrappedCurrentCall, endedAt: Date(), reason: .remoteEnded)
        }
    }
    
    func updateCall(title: String) {
        let cxUpdate = CXCallUpdate()
        cxUpdate.localizedCallerName = title
        provider?.reportCall(with: currentCall ?? UUID(), updated: cxUpdate)
    }
    
    func updateCall(call: Call) {
        self.call = call
        webexCallStatesProcess(call: call)
        if self.sender != call.title {
            self.sender = call.title ?? self.sender
            let cxUpdate = CXCallUpdate()
            cxUpdate.localizedCallerName = call.title ?? "Webex Call updated"
            provider?.reportCall(with: currentCall ?? UUID(), updated: cxUpdate)
        }
       
    }
    
    func startCallWithPhoneNumber(phoneNumber : String) {
        currentCall = UUID()
        if let unwrappedCurrentCall = currentCall {
        let handle = CXHandle.init(type: CXHandle.HandleType.phoneNumber, value: phoneNumber)
        let startCallAction = CXStartCallAction.init(call: unwrappedCurrentCall, handle: handle)
        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        requestTransaction(transaction: transaction)
        }
    }
    
    func endCall() {
        if let unwrappedCurrentCall = currentCall {
        let endCallAction = CXEndCallAction.init(call: unwrappedCurrentCall)
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)
        requestTransaction(transaction: transaction)
        }
    }
    
    func holdCall(hold : Bool) {
        if let unwrappedCurrentCall = currentCall {
            let holdCallAction = CXSetHeldCallAction.init(call: unwrappedCurrentCall, onHold: hold)
            let transaction = CXTransaction()
            transaction.addAction(holdCallAction)
            requestTransaction(transaction: transaction)
        }
    }
    
    func requestTransaction(transaction : CXTransaction) {
        weak var weakSelf = self
        callController?.request(transaction, completion: { (error : Error?) in
            if error != nil {
                print("\(error?.localizedDescription ?? "requestTransaction error")")
                weakSelf?.delegate?.callDidFail()
            }
        })
    }
    
    //MARK: - Setup
    func providerAndControllerSetup() {
        let configuration = CXProviderConfiguration.init(localizedName: "CallKit")
        configuration.supportsVideo = true
        configuration.maximumCallsPerCallGroup = 1;
        configuration.supportedHandleTypes = [CXHandle.HandleType.phoneNumber]
        provider = CXProvider.init(configuration: configuration)
        provider?.setDelegate(self, queue: nil)
        callController = CXCallController()
    }
    
    //MARK : - CXProviderDelegate
    
    // Called when the provider has been fully created and is ready to send actions and receive updates
    func providerDidReset(_ provider: CXProvider) {
    }
    
    // If provider:executeTransaction:error: returned NO, each perform*CallAction method is called sequentially for each action in the transaction
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        
        //todo: configure audio session
        //todo: start network call
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
        provider.reportOutgoingCall(with: action.callUUID, connectedAt: nil)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        
        configureAudioSession()
        guard let call = call else {
             reportEndCall()
             action.fulfill()
             return
        }

        CallObjectStorage.self.shared.addCallObject(call: call)
        let callVC = CallViewController(space: Space(id: call.spaceId ?? "", title: call.title ?? ""), addedCall: false, currentCallId: call.callId ?? "", incomingCall: true, call: call)
        DispatchQueue.main.async {
            UIApplication.shared.topViewController()?.present(callVC, animated: true)
        }
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        currentCall = nil
        delegate?.callDidEnd()
        call?.reject(completionHandler: { error in
            if error == nil {
               // self.dismiss(animated: true)
            } else {
              //
            }
        })
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        delegate?.callDidHold(isOnHold: action.isOnHold)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        delegate?.muteButtonToggle()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
    }
    
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
    }
    
    // Called when an action was not performed in time and has been inherently failed. Depending on the action, this timeout may also force the call to end. An action that has already timed out should not be fulfilled or failed by the provider delegate
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        // React to the action timeout if necessary, such as showing an error UI.
    }
    
    /// Called when the provider's audio session activation state changes.
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        // Start call audio media, now that the audio session has been activated after having its priority boosted.
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        /*
         Restart any non-call related audio now that the app's audio session has been
         de-activated after having its priority restored to normal.
         */
    }
    
    func configureAudioSession() {
        print("Configuring audio session")
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [])
        } catch (let error) {
            print("Error while configuring audio session: \(error)")
        }
    }
    
    func webexCallStatesProcess(call: Call) {
        call.onFailed = { [self] reason in
            print(reason)
            reportEndCall()
        }
        
        call.onDisconnected = { [self] reason in
            print(reason)
            // We will need to report the call as ended to CallKit no matter what the reason
            reportEndCall()
            switch reason {
            case .callEnded, .remoteLeft, .remoteDecline, .remoteCancel, .otherConnected:
                print(reason)
            case .localLeft, .localDecline, .localCancel, .otherDeclined:
                print(reason)
            case .error(let error):
                print(error)
            @unknown default:
                print(reason)
            }
        }
    }
    
}


