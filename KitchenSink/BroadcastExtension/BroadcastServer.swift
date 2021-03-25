import WebexSDK

protocol BroadcastServerProtocol: AnyObject {
    var onWillAcceptConnection: (() -> Void)? { get set }
    var onDidReceiveData: ((Data) -> Void)? { get set }
    
    func start(completion: @escaping (Error?) -> Void)
    func broadcast(_ error: ScreenShareError)
    func stop()
}

class BroadcastServer: BroadcastServerProtocol {
    var onWillAcceptConnection: (() -> Void)?
    var onDidReceiveData: ((Data) -> Void)?

    private let connectionServer: BroadcastConnectionServerProtocol
    
    init(connectionServer: BroadcastConnectionServerProtocol) {
        self.connectionServer = connectionServer
        connectionServer.delegate = self
    }
    
    func start(completion: @escaping (Error?) -> Void) {
        connectionServer.start(completion: completion)
    }
    
    func stop() {
        connectionServer.invalidate()
    }
    
    func broadcast(_ error: ScreenShareError) {
        var message = FeedbackMessage(error: error)
        let data = Data(bytes: &message, count: MemoryLayout<FeedbackMessage>.size)
        connectionServer.broadcast(data) { error in
            if let error = error {
                print("failed to send feedback message \(error)")
            }
        }
    }
}

extension BroadcastServer: BroadcastConnectionServerDelegate {
    func broadcastConnectionServerWillAcceptConnection(_ server: BroadcastConnectionServerProtocol) {
        onWillAcceptConnection?()
    }
    
    func broadcastConnectionServer(_ server: BroadcastConnectionServerProtocol, didReceive data: Data) {
        onDidReceiveData?(data)
    }
}
