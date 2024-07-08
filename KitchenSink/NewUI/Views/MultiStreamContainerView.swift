import SwiftUI
import WebexSDK

@available(iOS 16.0, *)
struct MultiStreamContainerView: View {
    @ObservedObject var callViewModel: CallViewModel
    @State private var currentPage = 0
    
    var body: some View {
         GeometryReader { geometry in
             VStack {
                 TabView(selection: $currentPage) {
                     ForEach(0..<callViewModel.auxViews.count, id: \.self) { index in
                         if index % 2 == 0 {
                             HStack(spacing: 10) {
                                 MultiStreamCellView(callingVM: callViewModel,
                                                   renderView: callViewModel.auxViews[index],
                                                   mediaStream: callViewModel.auxDictNew[callViewModel.auxViews[index]])
                                     .frame(width: 170, height: 180)
                                     .tag(index)

                                 if index + 1 < callViewModel.auxViews.count {
                                     MultiStreamCellView(callingVM: callViewModel,
                                                       renderView: callViewModel.auxViews[index + 1],
                                                       mediaStream: callViewModel.auxDictNew[callViewModel.auxViews[index + 1]])
                                         .frame(width: 170, height: 180)
                                         .tag(index + 1)
                                 } else {
                                     Color.clear
                                         .frame(width: geometry.size.width / 2, height: geometry.size.height)
                                 }
                             }
                         }
                     }
                 }
                 .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                 .frame(width: geometry.size.width, height: geometry.size.height)
             }
         }
         .onAppear {
             currentPage = 0
         }
     }
    
}

@available(iOS 16.0, *)
struct MultiStreamCellView: View {
    @ObservedObject var callingVM: CallViewModel
    let renderView: MediaRenderViewRepresentable?
    let mediaStream: MediaStream?
    
    var body: some View {
        ZStack {
            MediaStreamViewRepresentable(mediaStream: mediaStream)
                .frame(width: 170, height: 170)
                .opacity(1.0)
            VStack {
                HStack {
                    if let stream = mediaStream {
                        Image(systemName: "pin")
                            .frame(width: 25, height: 25)
                        .opacity(stream.isPinned ? 1.0 : 0.0)
                        .foregroundColor(Color.red)
                        .padding(.leading)
                        .padding(.top)
                    }
                    
                    Spacer()
                    
                    if mediaStream != nil {
                        Button(action: {
                            // Perform action for more button
                            moreButton()
                        }) {
                            Image(systemName:"ellipsis")
                                .frame(width: 25, height: 25)
                                .padding(.trailing)
                                .padding(.top)
                        }
                        
                        .accessibilityIdentifier("moreButton")
                    }
                }
                Spacer()
            }
        }
    }
    
    
    func moreButton() {
        callingVM.showMultiStreamCategoryCAlert = true
    }
}

@available(iOS 16.0, *)
struct MediaStreamViewRepresentable: UIViewRepresentable {
    var mediaStream: MediaStream?
    var mediaStreamView = MediaStreamView()
    
    func makeUIView(context: Context) -> MediaStreamView {
        return mediaStreamView
    }
    
    func updateUIView(_ uiView: MediaStreamView, context: Context) {
        if let mediaStream = mediaStream {
            uiView.updateView(with: mediaStream)
            uiView.isOpaque = false
            uiView.layer.opacity = 1.0
            guard let renderView = mediaStream.renderView else {return}
            renderView.frame = CGRect(x: 0, y: 0, width: 170, height: 170)
            uiView.setRenderView(view: renderView)
        }
    }
}


@available(iOS 16.0, *)
struct MultiStreamCategoryView: View {
    @ObservedObject var callingVM: CallViewModel
    var category: MultiStreamCategory
    @State var isDuplicateMultiStream: Bool = false
    @State private var selectedQuality: MediaStreamQualityKS = .LD
    @State private var numberOfStreams: String = "24"
    @State private var participantId: String = ""
    
    init( callingVM: CallViewModel, category: MultiStreamCategory) {
        self.category = category
        self.callingVM = callingVM
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text(category.title)
                    .font(.title2)
                    .padding(.bottom)
                
                if category == .categoryB {
                    HStack(spacing: 20){
                        Text("No. of Streams:")
                            .font(.system(.title3))
                        TextField("", text: $numberOfStreams)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                    }.padding(.horizontal, 20)
                        .padding(.bottom)
                }
                
                
                HStack {
                    Text("Quality")
                        .font(.system(.title3))
                    Spacer()
                    Picker("Quality", selection: $selectedQuality) {
                        ForEach(MediaStreamQualityKS.allCases, id: \.self) { option in
                            Text(String(describing: option.description))
                        }
                    }
                    .frame(width: 150)
                }
                .padding(.horizontal, 20)
                
                if category == .categoryA {
                    HStack(spacing: 20) {
                        Toggle(isOn: $isDuplicateMultiStream) {
                            Text("Duplicate")
                                .font(.system(.title3))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                HStack(spacing: 20) {
                    Spacer()
                    Button("Cancel") {
                        withAnimation {
                            callingVM.showMultiStreamCategoryView = false
                        }
                    }
                    .frame(minWidth: 0, maxWidth: 250)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .accessibilityIdentifier("cancelButton")
                    
                    Spacer(minLength: 20)
                    Button("Save") {
                        if category == .categoryA {
                            setMediaStreamCategoryA(duplicate: isDuplicateMultiStream, quality: selectedQuality)
                        } else if category == .categoryB {
                            guard let numOfStream = Int(numberOfStreams) else { return }
                            setMediaStreamsCategoryB(numStreams: numOfStream, quality: selectedQuality)
                        } else if category == .categoryC {
                            setMediaStreamCategoryC(participantId: callingVM.participantId , quality: selectedQuality)
                        }
                        withAnimation {
                            callingVM.showMultiStreamCategoryView = false
                        }
                    }
                    .frame(minWidth: 0, maxWidth: 250)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .clipShape(Capsule())
                    .accessibilityIdentifier("saveButton")
                    Spacer()
                }
            }
            .frame(width: geometry.size.width * 0.9, height: geometry.size.height/2.5)
            .padding(.horizontal)
            .background(RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green, lineWidth: 5))
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 10)
            .scaleEffect(callingVM.showMultiStreamCategoryView ? 1 : 0.5)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        
        
    }
    
    func setMediaStreamCategoryA(duplicate: Bool, quality: MediaStreamQualityKS) {
        callingVM.setMediaStreamCategoryA(duplicate: duplicate, quality: MediaStreamQualityKS.createMediaStreamQuality(from: quality))
    }
    
    func setMediaStreamsCategoryB(numStreams: Int, quality: MediaStreamQualityKS) {
        callingVM.setMediaStreamsCategoryB(numStreams: numStreams, quality: MediaStreamQualityKS.createMediaStreamQuality(from: quality))
    }
    
    func setMediaStreamCategoryC(participantId: String, quality: MediaStreamQualityKS) {
        callingVM.setMediaStreamCategoryC(participantId: participantId, quality: MediaStreamQualityKS.createMediaStreamQuality(from: quality))
    }
}


enum MultiStreamCategory {
    case categoryA
    case categoryB
    case categoryC
    case removeCategoryA
    case removeCategoryB
    
    var title: String {
        switch self {
        case .categoryA:
            return "Set Category A options"
        case .categoryB:
            return "Set Category B options"
        case .categoryC:
            return "Set Category C options"
        case .removeCategoryA:
            return "Remove Category A"
        case .removeCategoryB:
            return "Remove Category B"
        }
    }
}

enum MediaStreamQualityKS: Identifiable, CaseIterable {
    var id: Self {
        self
    }
    
    case Undefined
    case LD
    case SD
    case HD
    case FHD
    
    var description: String {
        switch self {
        case .Undefined: return "Undefined"
        case .LD: return "LD"
        case .SD: return "SD"
        case .HD: return "HD"
        case .FHD: return "FHD"
        }
    }
    
    static func createMediaStreamQuality(from quality: MediaStreamQualityKS) -> MediaStreamQuality {
        switch quality {
        case .Undefined:
            return MediaStreamQuality.Undefined
        case .LD:
            return MediaStreamQuality.LD
        case .SD:
            return MediaStreamQuality.SD
        case .HD:
            return MediaStreamQuality.HD
        case .FHD:
            return MediaStreamQuality.FHD
        }
    }
}

@available(iOS 16.0, *)
struct CallingScreenNoScreeShareView: View {
    @ObservedObject var callingVM: CallViewModel
    var geometry: GeometryProxy
    var remoteVideoViewRepresentable: RemoteVideoViewRepresentable!
    var selfVideoView:  MediaRenderViewKS!

    init(callingVM: CallViewModel, geometry: GeometryProxy, remoteVideoViewRepresentable: RemoteVideoViewRepresentable!, selfVideoView: MediaRenderViewKS!) {
        self.callingVM = callingVM
        self.geometry = geometry
        self.remoteVideoViewRepresentable = remoteVideoViewRepresentable
        self.selfVideoView = selfVideoView
    }
    
    var body: some View {
        self.remoteVideoViewRepresentable.frame(width: geometry.size.width, height: geometry.size.height)
            .opacity(callingVM.receivingVideo ? 1.0 : 0.0)
            .padding(.bottom, 20)
            .zIndex(0)
        self.selfVideoView.frame(width: geometry.size.width/4, height: geometry.size.height/3.5)
            .opacity(!callingVM.isLocalVideoMuted ? 1.0 : 0.0)
            .cornerRadius(10)
            .offset(x: 0, y: 0 )
            .padding(.bottom, 10)
            .padding(.trailing, 10)

    }
}

@available(iOS 16.0, *)
struct CallingScreenWithScreeShareView: View {
    @ObservedObject var callingVM: CallViewModel
    var geometry: GeometryProxy
    var remoteVideoViewRepresentable: RemoteVideoViewRepresentable!
    var selfVideoView:  MediaRenderViewKS!
    var screenShareView: MediaRenderViewKS!

    init(callingVM: CallViewModel, geometry: GeometryProxy, remoteVideoViewRepresentable: RemoteVideoViewRepresentable!, selfVideoView: MediaRenderViewKS!, screenShareView: MediaRenderViewKS!) {
        self.callingVM = callingVM
        self.geometry = geometry
        self.remoteVideoViewRepresentable = remoteVideoViewRepresentable
        self.selfVideoView = selfVideoView
        self.screenShareView = screenShareView
    }
    
    var body: some View {
        VStack {
            // Top view
            HStack {
                self.remoteVideoViewRepresentable
                    .frame(width: geometry.size.width / 3.5, height: geometry.size.height/3.5)
                    .opacity(callingVM.receivingVideo ? 1.0 : 0.0)
                    .cornerRadius(10)
                    .zIndex(0)
                    //.padding(.leading, 10)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, geometry.safeAreaInsets.top)
            
            Spacer()
            // Center view
            self.screenShareView
                .opacity(callingVM.isReceivingScreenShared ? 1.0 : 0.0)
                .frame(height: geometry.size.height / 2.8)
                .padding(.vertical, 20)
            Spacer()

            
            // Bottom view
            HStack {
                Spacer()
                self.selfVideoView
                    .frame(width: geometry.size.width / 4, height: geometry.size.height/3.5)
                    .opacity(!callingVM.isLocalVideoMuted ? 1.0 : 0.0)
                    .cornerRadius(10)
                    .padding(.trailing, 10)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.bottom, geometry.safeAreaInsets.bottom)
        }
    }
}

@available(iOS 16.0, *)
struct CallingScreenWithMultiStreamWithScreenShare: View {
    @ObservedObject var callingVM: CallViewModel
    var geometry: GeometryProxy
    var remoteVideoViewRepresentable: RemoteVideoViewRepresentable!
    var selfVideoView:  MediaRenderViewKS!
    var screenShareView: MediaRenderViewKS!

    
    init(callingVM: CallViewModel, geometry: GeometryProxy, remoteVideoViewRepresentable: RemoteVideoViewRepresentable!, selfVideoView: MediaRenderViewKS!, screenShareView: MediaRenderViewKS!) {
        self.callingVM = callingVM
        self.geometry = geometry
        self.remoteVideoViewRepresentable = remoteVideoViewRepresentable
        self.selfVideoView = selfVideoView
        self.screenShareView = screenShareView
    }
    
    var body: some View {
        // Bottom views
        VStack {
            self.screenShareView
                .opacity(callingVM.isReceivingScreenShared ? 1.0 : 0.0)
                .background(.cyan)
                .frame(width: geometry.size.width, height: geometry.size.height / 2.8)

            HStack(spacing: 0) {
                self.remoteVideoViewRepresentable
                    .frame(width: geometry.size.width / 2, height: geometry.size.height / 2)
                    .opacity(callingVM.receivingVideo ? 1.0 : 0.0)
                    .cornerRadius(10)
                    .zIndex(0)
                
                self.selfVideoView
                    .frame(width: geometry.size.width / 2, height: geometry.size.height / 2)
                    .opacity(!callingVM.isLocalVideoMuted ? 1.0 : 0.0)
                    .cornerRadius(10)
            }
            .frame(width: geometry.size.width, alignment: .bottom)
            .padding(.bottom, geometry.safeAreaInsets.bottom)
        }
    }
}

@available(iOS 16.0, *)
struct CallingScreenWithMultiStreamNoScreenShare: View {
    @ObservedObject var callingVM: CallViewModel
    var geometry: GeometryProxy
    var remoteVideoViewRepresentable: RemoteVideoViewRepresentable!
    var selfVideoView:  MediaRenderViewKS!
    
    init(callingVM: CallViewModel, geometry: GeometryProxy, remoteVideoViewRepresentable: RemoteVideoViewRepresentable!, selfVideoView: MediaRenderViewKS!) {
        self.callingVM = callingVM
        self.geometry = geometry
        self.remoteVideoViewRepresentable = remoteVideoViewRepresentable
        self.selfVideoView = selfVideoView
    }
    
    var body: some View {
        VStack {
            // Top view
            HStack {
                self.remoteVideoViewRepresentable
                    .frame(width: geometry.size.width / 3.5, height: geometry.size.height/3.5)
                    .opacity(callingVM.receivingVideo ? 1.0 : 0.0)
                    .cornerRadius(10)
                    .zIndex(0)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, geometry.safeAreaInsets.top)
            
            MultiStreamContainerView(callViewModel: callingVM)
                        .opacity(callingVM.auxViews.count > 0 ? 1.0 : 0.0)
                        .frame(height: geometry.size.height / 2.6)
            Spacer()
            
            // Bottom view
            HStack {
                Spacer()
                self.selfVideoView
                    .frame(width: geometry.size.width / 4, height: geometry.size.height/3.5)
                    .opacity(!callingVM.isLocalVideoMuted ? 1.0 : 0.0)
                    .cornerRadius(10)
                    .padding(.trailing, 10)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.bottom, geometry.safeAreaInsets.bottom)
        }
        Spacer()
    }
}

@available(iOS 16.0, *)
struct SelfPhotoView: View {
    @ObservedObject var callingVM: CallViewModel
    init(callingVM: CallViewModel) {
        self.callingVM = callingVM
    }
    
    var body: some View {
        VStack {
            Spacer(minLength: 5)
            Text("Take Photo Result")
                .font(.headline)
            if let selfPhoto = callingVM.selfPhoto {
                Image(uiImage: selfPhoto)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
            }
            Button("Ok") {
                callingVM.showSelfPhoto = false
            }
            .frame(width: 100)
            .padding()
            .foregroundColor(.white)
            .background(Color.red)
            .clipShape(Capsule())
            .accessibilityIdentifier("OkButton")
            Spacer(minLength: 5)
        }
        .frame(width: 250, height: 320)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}
