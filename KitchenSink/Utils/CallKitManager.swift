import UIKit
import CallKit
import AVFoundation
import WebexSDK


protocol CallKitManagerDelegate : AnyObject {
    // these delegate functions will be called when user perform actions on native callkit interface
    func oldCallEnded()
    func callDidEnd(call: Call)
    func callDidHold(call: Call, isOnHold: Bool)
    func callDidFail()
    func muteButtonToggle(call: Call)
}

class CallKitManager: NSObject, CXProviderDelegate {

    var provider : CXProvider?
    var callController : CXCallController?
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
        self.sender = sender
        print("push uuuid: \(uuid.uuidString)")
        let update = CXCallUpdate()
        update.supportsGrouping = true
        update.supportsUngrouping = true
        update.supportsHolding = true
        update.hasVideo = false
        update.remoteHandle = CXHandle.init(type: CXHandle.HandleType.phoneNumber, value: sender)
        weak var weakSelf = self
        provider?.reportNewIncomingCall(with: uuid, update: update, completion: { (error : Error?) in
            if error != nil {
                weakSelf?.delegate?.callDidFail()
                print("reportNewIncomingCall error \(error?.localizedDescription ?? "")")
            }
            else {
                print("reportNewIncomingCall success" )
            }
            completion()
        })
    }
    
    func reportEndCall(uuid: UUID) {
        print("endCallreported")
        provider?.reportCall(with: uuid, endedAt: Date(), reason: .remoteEnded)
    }
    
    func updateCall(call: Call, voipUUID: UUID? = nil) {
        print("update call \(String(describing: call.callId))")
        self.call = call
        if let voipUUID = voipUUID
        {
            print("update voipUUID: \(voipUUID)")
            call.uuid = voipUUID
        }
        let otherCall = getOtherActiveWxcCall()
        if let otherCall = otherCall {
            webexCallStatesProcess(call: otherCall)
        }
        webexCallStatesProcess(call: call)
        if self.sender != call.title {
            self.sender = call.title ?? self.sender
            let cxUpdate = CXCallUpdate()
            cxUpdate.supportsGrouping = true
            cxUpdate.supportsUngrouping = true
            cxUpdate.supportsHolding = true
            cxUpdate.hasVideo = true
            cxUpdate.localizedCallerName = call.title ?? "Webex Call updated"
            provider?.reportCall(with: call.uuid, updated: cxUpdate)
        }
    }
    
    func startCall(call: Call) {
        print("start call \(String(describing: call.callId))")
        let handle = CXHandle.init(type: CXHandle.HandleType.phoneNumber, value: call.title ?? "Unknown")
        let startCallAction = CXStartCallAction.init(call: call.uuid, handle: handle)
        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        requestTransaction(transaction: transaction)
    }
    
    func endCall(call: Call) {
        print("end call \(String(describing: call.callId))")
        let endCallAction = CXEndCallAction.init(call: call.uuid)
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)
        requestTransaction(transaction: transaction)
    }
    
    func holdCall(hold : Bool, call: Call) {
        print("hold call \(String(describing: call.callId))")
        let holdCallAction = CXSetHeldCallAction.init(call: call.uuid, onHold: hold)
        let transaction = CXTransaction()
        transaction.addAction(holdCallAction)
        requestTransaction(transaction: transaction)
    }
    
    func requestTransaction(transaction : CXTransaction) {
        callController?.request(transaction, completion: { (error : Error?) in
            if error != nil {
                print("requestTransaction error: \(error?.localizedDescription ?? "error")")
            }
        })
    }

    func getOtherActiveWxcCall() -> Call? {
        var otherCall: Call?
        let activeCalls = CallObjectStorage.self.shared.getAllActiveCalls()
        for call in activeCalls {
            if call.isWebexCallingOrWebexForBroadworks && call.callId != self.call?.callId {
                otherCall = call
                break
            }
        }
        return otherCall
    }

    //MARK: - Setup
    func providerAndControllerSetup() {
        let configuration = CXProviderConfiguration.init(localizedName: "CallKit")
        configuration.supportsVideo = true
        configuration.maximumCallGroups = 2
        configuration.maximumCallsPerCallGroup = 2
        configuration.supportedHandleTypes = [CXHandle.HandleType.phoneNumber]
        provider = CXProvider.init(configuration: configuration)
        provider?.setDelegate(self, queue: nil)
        callController = CXCallController()
    }
    
    //MARK : - CXProviderDelegate
    
    // Called when the provider has been fully created and is ready to send actions and receive updates
    func providerDidReset(_ provider: CXProvider) {
        print("providerDidReset")
    }
    
    // If provider:executeTransaction:error: returned NO, each perform*CallAction method is called sequentially for each action in the transaction
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("CXStartCallAction")
        //todo: configure audio session
        //todo: start network call
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
        provider.reportOutgoingCall(with: action.callUUID, connectedAt: nil)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("CXAnswerCallAction \(String(describing: call?.callId))")
        guard let call = call else {
            reportEndCall(uuid: action.callUUID)
            action.fulfill()
            return
        }

        CallObjectStorage.self.shared.addCallObject(call: call)
        let callVC = CallViewController(space: Space(id: call.spaceId ?? "", title: call.title ?? ""), addedCall: false, currentCallId: call.callId ?? "", incomingCall: true, call: call)
        DispatchQueue.main.async {
            // if CallViewController is already open
            if let callVC = UIApplication.shared.topViewController() as? CallViewController {
                print("Second calll CXAnswerCallAction \(String(describing: call.callId))")
                callVC.currentCallId = call.callId
                callVC.incomingCall = true
                callVC.call = call
                callVC.viewDidLoad()
            } else {
                print("First calll CXAnswerCallAction \(String(describing: call.callId))")
                UIApplication.shared.topViewController()?.present(callVC, animated: true)
            }
        }
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("CXEndCallAction \(String(describing: call?.callId))")
        if let currentCall = CallObjectStorage.shared.getCallObject(uuid: action.callUUID) {
            if currentCall.status == .connected {
                delegate?.callDidEnd(call: currentCall)
            } else {
                action.fail()
                return
            }
        } else {
            if let call = call {
                rejectCall(call: call)
            } else {
                action.fail()
                return
            }
        }
        action.fulfill()
    }

    func rejectCall(call: Call) {
        call.reject(completionHandler: { error in
            if error == nil {
                print("Call rejected: \(call.title ?? "")")
            }
        })
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        if let currentCall = CallObjectStorage.shared.getCallObject(uuid: action.callUUID) {
            delegate?.callDidHold(call: currentCall, isOnHold: action.isOnHold)
        } else {
            reportEndCall(uuid: action.callUUID)
        }
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        if let currentCall = CallObjectStorage.shared.getCallObject(uuid: action.callUUID) {
            delegate?.muteButtonToggle(call: currentCall)
        } else {
            reportEndCall(uuid: action.callUUID)
        }
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        print("CXSetGroupCallAction \(String(describing: call?.callId))")
    }
    
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        print("CXPlayDTMFCallAction \(String(describing: call?.callId))")
    }
    
    // Called when an action was not performed in time and has been inherently failed. Depending on the action, this timeout may also force the call to end. An action that has already timed out should not be fulfilled or failed by the provider delegate
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        // React to the action timeout if necessary, such as showing an error UI.
    }
    
    /// Called when the provider's audio session activation state changes.
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("didActivate audioSession \(String(describing: call?.callId))")
        call?.updateAudioSession()
        // Start call audio media, now that the audio session has been activated after having its priority boosted.
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("didDeactivate audioSession \(String(describing: call?.callId))")
        /*
         Restart any non-call related audio now that the app's audio session has been
         de-activated after having its priority restored to normal.
         */
    }
    
    func webexCallStatesProcess(call: Call) {
        call.onFailed = { [self] reason in
            print(reason)
            reportEndCall(uuid: call.uuid)
        }
        
        call.onDisconnected = { [self] reason in
            print(reason)
            // We will need to report the call as ended to CallKit no matter what the reason
            reportEndCall(uuid: call.uuid)
            // hide the UI for switching between calls
            if let currentCall = self.call {
                if call.callId != currentCall.callId {
                    delegate?.oldCallEnded()
                }
            }
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


