import WebexSDK

// enum to represent the CallAssociationType
public enum CallAssociationTypeKS {
    /// The calls are merged into one
    case Merge
    /// The call is transferred to another call
    case Transfer
    
    init(type: CallAssociationType)
    {
        switch type
        {
        case .Merge:
            self = .Merge
        case .Transfer:
            self = .Transfer
        }
    }
    
    func toCallAssociationType() -> CallAssociationType {
        switch self {
        case .Merge:
            return CallAssociationType.Merge
        case .Transfer:
            return CallAssociationType.Transfer
        }
    }
}