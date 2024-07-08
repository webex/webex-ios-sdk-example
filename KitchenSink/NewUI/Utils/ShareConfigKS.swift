import WebexSDK

public enum ShareOptimizeTypeKS {
    case Default
    case OptimizeVideo
    case OptimizeText
    
    static func convertToShareOptimizeType(_ optimizeTypeKS: ShareOptimizeTypeKS) -> ShareOptimizeType {
        switch optimizeTypeKS {
        case .Default:
            return .Default
        case .OptimizeVideo:
            return .OptimizeVideo
        case .OptimizeText:
            return .OptimizeText
        }
    }
}


public struct ShareConfigKS {
    public let shareType: ShareOptimizeTypeKS

    public let enableAudio: Bool
    
    var selectedOption = "Default"
    var isSendingAudio = false

    public init(shareType: ShareOptimizeTypeKS, enableAudio: Bool) {
        self.shareType = shareType
        self.enableAudio = enableAudio
    }
    
    internal init(chShareConfig: CHShareConfig)
    {
        switch chShareConfig.shareType {
        case .default:
            self.shareType = .Default
        case .optimizeText:
            self.shareType = .OptimizeText
        case .optimizeVideo:
            self.shareType = .OptimizeVideo
        default:
            self.shareType = .Default
        }
        self.enableAudio = chShareConfig.enableAudio
    }
    
    func toCHShareConfig() -> CHShareConfig {
        var type: CHShareOptimizeType = .default
        switch self.shareType {
        case .Default:
            type = .default
        case .OptimizeText:
            type = .optimizeText
        case .OptimizeVideo:
            type = .optimizeVideo
        }
        return CHShareConfig(shareType: type, enableAudio: self.enableAudio)
    }
    
    func toString() -> String
    {
        return "enableAudio: \(enableAudio) shareType: \(shareType)"
    }
    
    public func getSelectedConfig() -> ShareConfigKS
    {
        var shareType: ShareOptimizeTypeKS = .Default
        switch selectedOption
        {
        case "Default":
            shareType = .Default
        case "Optimize for text and images":
            shareType = .OptimizeText
        case "Optimize for motion and video":
            shareType = .OptimizeVideo
        default:
            shareType = .Default
        }
        return ShareConfigKS(shareType: shareType, enableAudio: isSendingAudio)
    }
}
