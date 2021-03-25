import Foundation
import WebexSDK

protocol ScreenShareServiceProtocol: AnyObject {
    func start()
}

class ScreenShareService: ScreenShareServiceProtocol {
    private enum State {
        case idle
        case sharing(ShareSessionProtocol)
        
        var isIdle: Bool { return !isSharing }
        var isSharing: Bool {
            guard case .sharing = self else { return false }
            return true
        }
    }
    private let server: BroadcastServerProtocol
    private let callId: String
    private let connectionServer: LLBSDConnectionServer
    private let inCallShareSessionLifecycle: InCallShareSessionLifecycle
    private var state = State.idle {
        didSet {
            print("old: \(oldValue), new: \(state)")
        }
    }
    
    init(callId: String) {
        self.callId = callId
        let path = Bundle.main.path(forResource: "Info", ofType: "plist")
        let keys = NSDictionary(contentsOfFile: path ?? "")
        let groupId = keys?["GroupIdentifier"] as? String ?? ""
        connectionServer = LLBSDConnectionServer(applicationGroupIdentifier: groupId, connectionIdentifier: ScreenShareConnectionIdentifier)
        server = BroadcastServer(connectionServer: BroadcastConnectionServerAdapter(connectionServer: connectionServer))
        inCallShareSessionLifecycle = InCallShareSessionLifecycle(callId: callId)
    }
    
    deinit {
        server.stop()
    }
    
    func start() {
        server.start { error in
            guard error == nil else { return print("failed to start \(String(describing: error))") }
            self.registerHandlers()
        }
    }
    
    private func registerHandlers() {
        server.onWillAcceptConnection = { [weak self] in
            guard let self = self else { return }
            self.handleWillAcceptConnection()
        }
        server.onDidReceiveData = { [weak self] data in
            guard let self = self else { return }
            self.handleDidReceiveData(data)
        }
    }
    
    private func handleWillAcceptConnection() {
        guard state.isIdle else {
            server.broadcast(.fatal)
            return print("already in an active share session.")
        }
        let session = ShareSession(shareSessionLifecycle: inCallShareSessionLifecycle)
        start(session)
    }
    
    private func start(_ session: ShareSessionProtocol) {
        do {
            try session.start()
            state = .sharing(session)
            print("starting new share session.")
        } catch let error as ShareSessionError {
            print("failed to create start session \(error)")
            return server.broadcast(error.value)
        } catch {
            print("unknown error \(error) when starting session.")
            return server.broadcast(.fatal)
        }
    }
    
    private func handleDidReceiveData(_ data: Data) {
        guard case .sharing(let session) = state else { return print("no active session.") }
        session.onFrame(data)
    }
    
    func onSharingStateChanged(call: Call) {
        if !call.sendingScreenShare {
            state = .idle
        }
        inCallShareSessionLifecycle.onSharingStateChanged(call: call)
    }
}
