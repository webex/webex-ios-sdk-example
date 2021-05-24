import UIKit

class CallButton: UIButton {
    enum ActionType {
        case connectCall, endCall, muteCall, mutedCall, holdCall, addCall, transferCall, audioRoute, showParticipants, toggleVideo, mergeCall, screenShare, more
        
        var imageName: String {
            switch self {
            case .connectCall: return "audio-call"
            case .endCall: return "end-call"
            case .muteCall: return "microphone"
            case .mutedCall: return "microphone-muted"
            case .holdCall: return "call-hold"
            case .addCall: return "call-add"
            case .mergeCall: return "call-merge"
            case .transferCall: return "call-swap"
            case .audioRoute: return "audio-route"
            case .showParticipants: return "participants"
            case .toggleVideo: return "audio-video"
            case .screenShare: return "screen-share"
            case .more: return "more"
            }
        }
        
        var color: UIColor {
            switch self {
            case .connectCall: return .momentumGreen40
            case .endCall: return .systemRed
            case .muteCall: return .systemGray2
            case .mutedCall: return .systemGray6
            case .holdCall: return .systemGray2
            case .addCall: return .systemGray2
            case .mergeCall: return .systemGray2
            case .transferCall: return .systemGray2
            case .audioRoute: return .systemGray2
            case .showParticipants: return .systemGray2
            case .toggleVideo: return .systemGray2
            case .screenShare: return .systemGray2
            case .more: return .systemGray2
            }
        }
    }
    
    enum Style {
        case cta, outlined
    }
    
    enum Size {
        case small, medium
        
        var cgSize: CGSize {
            switch self {
            case .small: return CGSize(width: 22, height: 22)
            case .medium: return CGSize(width: 26, height: 26)
            }
        }
    }
    
    init(style: Style, size: Size, type: ActionType) {
        super.init(frame: .zero)
    
        let callIcon = UIImage(named: type.imageName)?.resizedImage(for: size.cgSize)
        switch style {
        case .cta:
            setImage(callIcon, for: .normal)
            backgroundColor = type.color
            clipsToBounds = true
            
        case .outlined:
            setImage(callIcon?.withRenderingMode(.alwaysTemplate), for: .normal)
            imageView?.tintColor = type.color
        }
    }
    
    init(frame: CGRect, style: Style, size: Size, type: ActionType) {
        super.init(frame: frame)
    
        let callIcon = UIImage(named: type.imageName)?.resizedImage(for: size.cgSize)
        switch style {
        case .cta:
            setImage(callIcon, for: .normal)
            backgroundColor = type.color
            clipsToBounds = true
            
        case .outlined:
            setImage(callIcon?.withRenderingMode(.alwaysTemplate), for: .normal)
            imageView?.tintColor = type.color
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let diameter = min(bounds.width, bounds.height)
        layer.cornerRadius = diameter / 2
    }
}
