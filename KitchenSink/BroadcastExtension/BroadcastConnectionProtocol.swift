import Foundation

public protocol BroadcastConnectionClientDelegate: AnyObject {
    func broadcastConnectionClient(_ client: BroadcastConnectionClientProtocol, didReceive data: Data)
    func broadcastConnectionClient(_ client: BroadcastConnectionClientProtocol, didFailToReceive error: Error)
}

public protocol BroadcastConnectionClientProtocol: AnyObject {
    var delegate: BroadcastConnectionClientDelegate? { get set }
    func start(completion: @escaping (Error?) -> Void)
    func send(_ message: Data, completion: @escaping (Error?) -> Void)
}

public protocol BroadcastConnectionServerDelegate: AnyObject {
    func broadcastConnectionServerWillAcceptConnection(_ server: BroadcastConnectionServerProtocol)
    func broadcastConnectionServer(_ server: BroadcastConnectionServerProtocol, didReceive data: Data)
}

public protocol BroadcastConnectionServerProtocol: AnyObject {
    var delegate: BroadcastConnectionServerDelegate? { get set }
    func start(completion: @escaping (Error?) -> Void)
    func invalidate()
    func broadcast(_ message: Data, completion: @escaping (Error?) -> Void)
}

public class BroadcastConnectionClientAdapter: NSObject, BroadcastConnectionClientProtocol {
    public weak var delegate: BroadcastConnectionClientDelegate? {
        didSet {
            connectionClient.delegate = delegate != nil ? self : nil
        }
    }
    
    private let connectionClient: LLBSDConnectionClient
    
    public init(connectionClient: LLBSDConnectionClient) {
        self.connectionClient = connectionClient
    }
    
    public func start(completion: @escaping (Error?) -> Void) {
        connectionClient.start(completion)
    }
    
    public func send(_ message: Data, completion: @escaping (Error?) -> Void) {
        let data = message.withUnsafeBytes({ DispatchData(bytes: $0) }) as __DispatchData
        connectionClient.sendMessage(data, completion: completion)
    }
}

extension BroadcastConnectionClientAdapter: LLBSDConnectionDelegate {
    public func connection(_ connection: LLBSDConnection, didFailToReceiveMessageWithError error: Error) {
        delegate?.broadcastConnectionClient(self, didFailToReceive: error)
    }
    
    public func connection(_ connection: LLBSDConnection, didReceiveMessage message: __DispatchData, fromProcess processInfo: pid_t) {
        guard let data = (message as AnyObject) as? Data else { fatalError("unable to do something") }
        delegate?.broadcastConnectionClient(self, didReceive: data)
    }
}

public class BroadcastConnectionServerAdapter: NSObject, BroadcastConnectionServerProtocol {
    public weak var delegate: BroadcastConnectionServerDelegate? {
        didSet {
            connectionServer.delegate = delegate != nil ? self : nil
        }
    }
    
    private let connectionServer: LLBSDConnectionServer
    
    public init(connectionServer: LLBSDConnectionServer) {
        self.connectionServer = connectionServer
    }
    
    public func start(completion: @escaping (Error?) -> Void) {
        connectionServer.start(completion)
    }
    
    public func invalidate() {
        connectionServer.invalidate()
    }
    
    public func broadcast(_ message: Data, completion: @escaping (Error?) -> Void) {
        let data = message.withUnsafeBytes({ DispatchData(bytes: $0) }) as __DispatchData
        connectionServer.broadcastMessage(data, completion: completion)
    }
}

extension BroadcastConnectionServerAdapter: LLBSDConnectionServerDelegate {
    public func server(_ server: LLBSDConnectionServer, shouldAcceptNewConnection processInfo: pid_t) -> Bool {
        delegate?.broadcastConnectionServerWillAcceptConnection(self)
        return true
    }
    
    public func connection(_ connection: LLBSDConnection, didReceiveMessage message: __DispatchData, fromProcess processInfo: pid_t) {
        guard let data = (message as AnyObject) as? Data else { return }
        delegate?.broadcastConnectionServer(self, didReceive: data)
    }
}
