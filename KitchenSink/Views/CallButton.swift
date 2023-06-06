import UIKit

class CallButton: UIButton {
    enum ActionType {
        case connectCall, endCall, muteCall, mutedCall, holdCall, addCall, transferCall, audioRoute, showParticipants, toggleVideo, mergeCall, screenShare, more, qualityIndicator, pin, noiseRemoval

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
            case .qualityIndicator: return "quality-Indicator"
            case .pin: return "pin"
            case .noiseRemoval: return "noise-detected-filled"
            }
        }
        
        var color: UIColor {
            switch self {
            case .connectCall: return .momentumGreen40
            case .mutedCall: if #available(iOS 13.0, *) {
                return .systemGray6
            } else {
                return .systemGray
            }
            case .muteCall, .holdCall, .addCall, .mergeCall, .transferCall, .audioRoute, .showParticipants,  .toggleVideo, .screenShare, .more, .noiseRemoval:
                if #available(iOS 13.0, *) {
                    return .systemGray2
                } else {
                    return .systemGray
                }
            case .endCall: return .systemRed
            case .qualityIndicator: return .systemGreen
            case .pin: return .systemRed
            }
        }
    }
    
    enum Style {
        case cta, outlined
    }
    
    enum Size {
        case small, medium, large

        var cgSize: CGSize {
            switch self {
            case .small: return CGSize(width: 22, height: 22)
            case .medium: return CGSize(width: 26, height: 26)
            case .large: return CGSize(width: 40, height: 40)
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
