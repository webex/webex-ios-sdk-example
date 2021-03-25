import CoreMedia
import UIKit

protocol SampleBufferQueueDelegate: AnyObject {
    func sampleBufferQueue(_ sampleBufferQueue: SampleBufferQueue, didPopSampleBuffer sampleBuffer: CMSampleBuffer)
}

class SampleBufferQueue {
    private weak var delegate: SampleBufferQueueDelegate?
    private let maxSamplesPerSecond: Double
    private let queue = DispatchQueue.global(qos: .userInitiated)
    private var sampleBuffer: CMSampleBuffer?
    private var nextFrameTime: TimeInterval = 0
    private var ready = true
    
    init(delegate: SampleBufferQueueDelegate, maxSamplesPerSecond: Double) {
        self.delegate = delegate
        self.maxSamplesPerSecond = maxSamplesPerSecond
    }
    
    func push(sampleBuffer: CMSampleBuffer) {
        synchronized(lock: self) {
            self.sampleBuffer = sampleBuffer
            guard let result = pop() else { return }
            queue.async { [weak self] in 
                self?.notify(sampleBuffer: result)
            }
        }
    }
    
    private func pop() -> CMSampleBuffer? {
        var result: CMSampleBuffer?
        synchronized(lock: self) {
            let now = CACurrentMediaTime()
            guard nextFrameTime < now && sampleBuffer != nil && ready else { return }
            nextFrameTime = now + (maxSamplesPerSecond > 0 ? 1 / maxSamplesPerSecond : 0)
            result = sampleBuffer
            sampleBuffer = nil
            ready = false
        }
        
        return result
    }
    
    private func notify(sampleBuffer: CMSampleBuffer) {
        var nextSampleBuffer: CMSampleBuffer? = sampleBuffer
        while true {
            guard let sampleBuffer = nextSampleBuffer else { break }
            delegate?.sampleBufferQueue(self, didPopSampleBuffer: sampleBuffer)
            synchronized(lock: self) {
                ready = true
                nextSampleBuffer = pop()
            }
        }
        
        queue.asyncAfter(deadline: .now() + nextFrameTime - CACurrentMediaTime()) { [weak self] in
            guard let self = self, let result = self.pop() else { return }
            self.notify(sampleBuffer: result)
        }
    }
}

private func synchronized<T: Any>(lock: T, block: () throws -> Void) rethrows {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    
    return try block()
}
