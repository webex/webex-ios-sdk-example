import ReplayKit

// can be deleted once we drop support for iOS 11.

protocol BroadcastUIHelperProtocol: AnyObject {
    func showBroadcastPickerView(sourceView: UIView)
}

protocol BroadcastUIHelperFactoryProtocol {
    func makeBroadcastUIHelper() -> BroadcastUIHelperProtocol
}

class BroadcastUIHelper: BroadcastUIHelperProtocol {
    private lazy var broadcastPickerView = makeBroadcastPickerView()
    
    func showBroadcastPickerView(sourceView: UIView) {
        guard let broadcastPickerView = broadcastPickerView else { return print("broadcastPickerView is nil.") }
        sourceView.addSubview(broadcastPickerView)
        broadcastPickerView.preferredExtension = "com.webex.sdk.KitchenSinkv3.KitchenSinkBroadcastExtension"
        defer { broadcastPickerView.removeFromSuperview() }
        if #available(iOS 13.0, *) {
            broadcastPickerView.subviews.compactMap { $0 as? UIButton }.first?.sendActions(for: .touchUpInside)
        } else {
            broadcastPickerView.subviews.compactMap { $0 as? UIButton }.first?.sendActions(for: .touchDown)
        }
    }
    
    private func makeBroadcastPickerView() -> RPSystemBroadcastPickerView? {
        #if targetEnvironment(simulator)
        return nil
        #else
        guard #available(iOS 13.0, *) else { return nil }
        return RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        #endif
    }
}

class BroadcastUIHelperFactory: BroadcastUIHelperFactoryProtocol {
    func makeBroadcastUIHelper() -> BroadcastUIHelperProtocol {
        return BroadcastUIHelper()
    }
}
