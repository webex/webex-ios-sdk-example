import SwiftUI

class Throttler {
    private var workItem: DispatchWorkItem?
    private var previousRun: Date = Date.distantPast
    private let queue: DispatchQueue
    private let minimumDelay: TimeInterval

    init(minimumDelay: TimeInterval, queue: DispatchQueue = DispatchQueue.main) {
        self.minimumDelay = minimumDelay
        self.queue = queue
    }

    func throttle(_ block: @escaping () -> Void) {
        // Cancel any existing work item if it has not yet executed
        workItem?.cancel()

        // Re-assign workItem with the new block task, resetting the previousRun time when it executes
        workItem = DispatchWorkItem() {
            [weak self] in
            self?.previousRun = Date()
            block()
        }

        // If the time since the last run is more than the minimum delay
        // => execute the block immediately
        // Else, delay the execution of the block
        let delay = Date().timeIntervalSince(previousRun) > minimumDelay ? 0 : minimumDelay

        // Execute the work item after delay
        queue.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
}
