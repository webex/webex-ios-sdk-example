import SwiftUI
import WebexSDK

@available(iOS 16.0, *)
public struct MediaRenderViewKS: View, Hashable {
    @ObservedObject var callViewModel: CallViewModel
    var renderView = MediaRenderView()    
    var isSelfVideo: Bool
    
    init(callViewModel: CallViewModel, isSelfVideo: Bool = false) {
        self.callViewModel = callViewModel
        self.isSelfVideo = isSelfVideo
    }
    public var body: some View {
        VStack {
            ZStack {
                MediaRenderViewRepresentable(renderVideoView: renderView)
                if isSelfVideo {
                    Button {
                        swapCameraAction()
                    } label: {
                        Image("swap-camera")
                    }
                    .opacity(!callViewModel.isLocalVideoMuted ? 1.0 : 0.0)
                    .accessibilityIdentifier("swapCameraBtn")
                }
            }
        }
    }
    
    public static func == (lhs: MediaRenderViewKS, rhs: MediaRenderViewKS) -> Bool {
        return lhs.isSelfVideo == rhs.isSelfVideo
        && lhs.renderView == rhs.renderView        
    }
    
    public func hash(into hasher: inout Hasher) {
            hasher.combine(isSelfVideo)
            hasher.combine(renderView)
    }
    
    private func swapCameraAction() {
        callViewModel.handleSwapCameraAction()
    }
}

struct MediaRenderViewRepresentable: UIViewRepresentable, Hashable {
    var renderVideoView = MediaRenderView()
    
    func makeUIView(context: Context) -> MediaRenderView  {
        return renderVideoView
    }
    
    func updateUIView(_ uiView: MediaRenderView, context: Context) {
        // Update the view.
    }
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(renderVideoView)
    }
    
    static func == (lhs: MediaRenderViewRepresentable, rhs: MediaRenderViewRepresentable) -> Bool {
        return lhs.renderVideoView == rhs.renderVideoView
    }
}
