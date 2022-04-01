import Foundation
import WebexSDK
final class CallObjectStorage {
    static let shared = CallObjectStorage()
    let serialQueue = DispatchQueue(label: "com.call.addCallObject")
    private var callObjects: [Call] = []
    
    func registerCallObjectsFromStorage(onScheduleChanged: @escaping ((Call) -> Void), updateSchedule: ((Call) -> Void), completion: (() -> Void)) {
        serialQueue.sync {
            for call in callObjects {
                call.onScheduleChanged = onScheduleChanged
                updateSchedule(call)
            }
            completion()
        }
    }
    
    func addCallObject(call: Call) {
        let callObj = getCallObject(callId: call.callId ?? "")
        serialQueue.sync {
            if callObj == nil {
                callObjects.append(call)
            }
        }
    }
    
    func removeCallObject(callId: String) {
        serialQueue.sync {
            guard let callIdToRemove = callObjects.firstIndex(where: { $0.callId == callId }) else { return }
            callObjects.remove(at: callIdToRemove)
        }
    }
    
    func getCallObject(callId: String) -> Call? {
        var callObj: Call?
        serialQueue.sync {
            for call in self.callObjects where call.callId == callId {
                callObj = call
            }
        }
        if let callObj = callObj {
            return callObj
        }
        return nil
    }
    
    func getCallsSize() -> Int {
        var count = 0
        serialQueue.sync {
            count = callObjects.count
        }
        return count
    }
    
    func clearStorage() {
        serialQueue.sync {
            callObjects.removeAll()
        }
    }
}
