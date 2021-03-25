import Foundation
import WebexSDK

///Developer should provide own implementation of the SDK Logger protocol for troubleshooting.
public class KitchenSinkLogger: Logger {
    public func log(message: LogMessage) {
        //log level control
        switch message.level {
        case .debug, .warning, .error, .no:
            print(message)
        default:
            break
        }
    }
}
