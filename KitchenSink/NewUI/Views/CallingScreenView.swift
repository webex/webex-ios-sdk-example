import SwiftUI
import AVKit
import ReplayKit
import Combine
import WebexSDK

@available(iOS 16.0, *)
// Mark: CallingScreenView
struct CallingScreenView: View, Equatable {
    @ObservedObject var callingVM: CallViewModel
    @ObservedObject var cameraSettingsVM: CameraSettingViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showParticipantList = false
    var remoteVideoViewRepresentable: RemoteVideoViewRepresentable!
    var selfVideoView:  MediaRenderViewKS!
    var screenShareView: MediaRenderViewKS!
    var isDialScreenSheetPresented: Bool {
        return callingVM.showDialScreenFromAddCall || callingVM.showDialScreenFromDirectTransfer
    }
    var showMeetingPasswordAlertView: Bool {
        return callingVM.showMeetingPasswordView
    }
    @State var remoteViewWidth = 0.0
    @State var remoteViewHeight = 0.0
    @State var selfViewWidth = 0.0
    @State var selfViewHeight = 0.0
    @State var screenShareViewWidth = 0.0
    @State var screenShareViewHeight = 0.0
    @State var streamContainerViewWidth = 0.0
    @State var streamContainerViewHeight = 0.0
    @State private var geometryReader: GeometryProxy?
    
    @State private var isCallControlViewVisible: Bool = true
    @State private var lastUserInteractionTime = Date()
    @State private var timer: AnyCancellable?
    let timerInterval: TimeInterval = 5
    
    @State var isMultiStreamOptionAlertPresented = false
    @State var selectedCategory: MultiStreamCategory = .categoryA
    
    init(callingVM : CallViewModel) {
        self.callingVM = callingVM
        self.cameraSettingsVM = CameraSettingViewModel()
        let remoteVideoView = MediaStreamView()
        self.selfVideoView = MediaRenderViewKS(callViewModel: callingVM, isSelfVideo: true)
        self.screenShareView = MediaRenderViewKS(callViewModel: callingVM, isSelfVideo: false)
        self.remoteVideoViewRepresentable = RemoteVideoViewRepresentable(remoteVideoView: remoteVideoView)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer().frame(height: 10)
                VStack {
                    GeometryReader { geometry in
                        ZStack(alignment: .bottomTrailing) {
                            
                            if !callingVM.isReceivingScreenShared  {
                                if callingVM.auxViews.count > 0 {
                                    CallingScreenWithMultiStreamNoScreenShare(callingVM: callingVM, geometry: geometry, remoteVideoViewRepresentable: self.remoteVideoViewRepresentable, selfVideoView: self.selfVideoView)
                                        .zIndex(1)
                                }
                                else {
                                    CallingScreenNoScreeShareView(callingVM: callingVM, geometry: geometry, remoteVideoViewRepresentable: self.remoteVideoViewRepresentable, selfVideoView: self.selfVideoView)
                                        .zIndex(1)
                                }
                            }
                            
                            else if callingVM.isReceivingScreenShared {
                                if callingVM.auxViews.count > 0 {
                                    CallingScreenWithMultiStreamWithScreenShare(callingVM: callingVM, geometry: geometry, remoteVideoViewRepresentable: self.remoteVideoViewRepresentable, selfVideoView: self.selfVideoView, screenShareView: self.screenShareView)
                                        .zIndex(1)
                                }
                                else {
                                    CallingScreenWithScreeShareView(callingVM: callingVM, geometry: geometry, remoteVideoViewRepresentable: self.remoteVideoViewRepresentable, selfVideoView: self.selfVideoView, screenShareView: self.screenShareView)
                                        .zIndex(1)
                                }
                            }
                            
                            // Text
                            VStack(alignment: .center) {
                                if callingVM.secondIncomingCall {
                                    HStack{
                                        Text(callingVM.secondCallTitle)
                                        
                                        Button("Resume"){
                                            callingVM.resumeCall()
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .buttonBorderShape(.roundedRectangle)
                                        .tint(.green)
                                        .frame(width: 150, height: 20, alignment: .trailing)
                                        
                                    }.padding()
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                                }
                                if callingVM.addedCall {
                                    HStack{
                                        Text(callingVM.associatedCallTitle)
                                        
                                        Button("Resume"){
                                            callingVM.resumeCall(fromAssociatedCall: true)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .buttonBorderShape(.roundedRectangle)
                                        .tint(.green)
                                        .frame(width: 150, height: 20, alignment: .trailing)
                                        
                                    }.padding()
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                                }
                                
                                VStack {
                                    Text(callingVM.durationLabel).font(.subheadline)
                                        .accessibilityIdentifier("durationLabel")
                                        .foregroundColor(.orange)
                                        .opacity(callingVM.showDurationLabel ? 1.0 : 0.0)
                                        .multilineTextAlignment(.center)
                                        .bold()
                                }
                                HStack{
                                    Spacer()
                                    VStack(alignment: .center){
                                        Text(callingVM.callingLabel).padding(.top, 5)
                                            .accessibilityIdentifier("onCallLabel")
                                        Text(callingVM.callTitle).font(.title)
                                            .accessibilityIdentifier("nameLabel")
                                    }
                                    
                                    Button(action: {
                                    }) {
                                        Image(systemName:"chart.bar")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(callingVM.badNetworkIconColor)
                                            .opacity(callingVM.showBadNetworkIcon ? 1.0 : 0.0)
                                    }
                                    .accessibilityIdentifier("badNetworkIcon")
                                    .padding(.trailing, 10)
                                    
                                    Button(action: {
                                        self.handleNoiseRemovalAction()
                                    }) {
                                        callingVM.noiseRemovalButtonImage
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50)
                                            .opacity(callingVM.showNoiseRemovalButtonIcon ? 1.0 : 0.0)
                                    }
                                    .accessibilityIdentifier("noiseRemovalButton")
                                    .padding(.trailing, 20)
                                    Spacer()
                                }
                                Spacer()
                                VStack {
                                    if callingVM.showTranscriptions {
                                        TranscriptionListView(callingVM: callingVM)
                                            .frame(width: geometry.size.width, height: 150)
                                        
                                    }
                                    if callingVM.showCaptionTextView {
                                        CaptionTextView(callingVM: callingVM)
                                            .frame(width: geometry.size.width, height: 80)
                                            .background(.gray)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                        }
                        .frame(height: isCallControlViewVisible ? geometry.size.height : geometry.size.height)
                    }.animation(.default, value: isCallControlViewVisible)
                   
                    if callingVM.showVirtualBGViewInCall {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 20) {
                                ForEach(cameraSettingsVM.backgrounds.indices, id: \.self) { index in
                                    let background = cameraSettingsVM.backgrounds[index]
                                    VirtualBackgroundCell(background: background, deleteAction: {
                                        cameraSettingsVM.deleteItem(item: background)
                                    })
                                    .overlay(content: {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(background.isActive ? Color.blue : Color.clear, lineWidth: background.isActive ? 4 : 0)
                                    })
                                    .onTapGesture {
                                        applyVirtualBackground(background)
                                    }
                                    .accessibilityIdentifier("VirtualBackgroundCell_\(index)")
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 5)
                        }
                        .frame(height: 80)
                    }// virtual backgrounds list
                }
                .contentShape(Rectangle())
                
                // Calling controls i.e. mute, speaker etc. visible state
                if isCallControlViewVisible {
                    Spacer().frame(height: 30)
                    CallingControlsView(callingVM: callingVM).frame(height: 40)
                    .transition(.move(edge: .bottom))
                    Spacer().frame(height: 10)
                }
                
            } .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showParticipantList.toggle()
                    }) {
                        Image(systemName: "person.2.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                            .cornerRadius(17.5)
                            .overlay(Circle()
                            .stroke(.green, lineWidth: 2))// Adjust the size as needed
                            .foregroundColor(.blue)
                        
                    }.accessibilityIdentifier("showParticipantList")
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .onTapGesture {
            self.lastUserInteractionTime = Date() // Update the time of the last interaction
            self.showCallControlView()
        }
        .onAppear(perform: {
            self.startTimer()
            self.connectCall()
        })
        .onDisappear {
            self.timer?.cancel()
        }
        .sheet(isPresented: Binding.constant(isDialScreenSheetPresented), onDismiss: {
                callingVM.showDialScreenFromAddCall = false
                callingVM.showDialScreenFromDirectTransfer = false
        }) {
            DialControlView(viewModel: DialControlViewModel(callViewModel: callingVM, fromCallingScreen: true), phoneServicesViewModel: UCLoginServicesViewModel())
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .alert(callingVM.alertTitle, isPresented: $callingVM.showAlert) {
            if callingVM.showNoiseRemovalAlert {
                Button("Cancel", role: .cancel) { }
            }            
            Button("Ok") {
                if callingVM.showNoiseRemovalAlert {
                    self.enableReceivingNoiseRemoval(shouldEnable: true)
                } else {
                    callingVM.checkAndDismissCallingScreenView()
                }
            }
        } message: {
            Text(callingVM.alertMessage)
        }
        .confirmationDialog("Multi Stream Options", isPresented: $callingVM.showMultiStreamOptionsAlert  , titleVisibility: .visible) {
            Button(MultiStreamCategory.categoryA.title) {
                self.showCategoryView(category: .categoryA)
            }
            Button(MultiStreamCategory.categoryB.title) {
                self.showCategoryView(category: .categoryB)
            }
            Button(MultiStreamCategory.removeCategoryA.title) {
                selectedCategory = .removeCategoryA
                self.removeCategory(category: .categoryA)
            }
            Button(MultiStreamCategory.removeCategoryB.title) {
                self.removeCategory(category: .categoryB)
            }
        }
        
        .confirmationDialog("Set Category C options", isPresented: $callingVM.showMultiStreamCategoryCAlert  , titleVisibility: .visible) {
            if let isPinned = callingVM.mediaStream?.isPinned, isPinned {
                Button("Remove Category C") {
                    self.removeCategory(category: .categoryC)
                }
            } else {
                Button("Pin Stream") {
                    self.showCategoryView(category: .categoryC)
                }
            }
        }
        .onReceive(callingVM.$dismissCallingScreenView) { dismiss in
            if dismiss {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onReceive(callingVM.$shouldUpdateView) { _ in
            updateView()
        }
        .onReceive(callingVM.$selectedLanguage) {  _ in
            updateSelectedLanguage()
        }
        
        .sheet(isPresented: $callingVM.showMoreOptions) {
            MoreOptionsCallView(callingVM: callingVM)
        }
        .sheet(isPresented: $showParticipantList) {
            ParticipantList(viewModel: ParticipantListViewModel(call: callingVM.currentCall))
        }
        .sheet(isPresented: $callingVM.showSpokenLanguagesList) {
            LanguagesListView(callingVM: callingVM, isSpokenLanguage: true)
        }
        .sheet(isPresented: $callingVM.showTranslationsLanguagesList) {
            LanguagesListView(callingVM: callingVM, isSpokenLanguage: false)
        }
        .sheet(isPresented: $callingVM.showCaptionsList) {
            ClosedCaptionsListView(callingVM: callingVM)
        }
        .onReceive(callingVM.$isReceivingScreenShared) { _ in
            updateScreenShare()
        }
        .onReceive(callingVM.$showMultiStreamOptionsAlert) { isPresent in
            if isPresent {
                showMultiStreamCategoryAlert()
            }
        }
        .onReceive(callingVM.$updateRemoteViewMultiStream) { value in
            if value {
                updateRemoteViewMultiStream()
                updateRemoteViewInfoMultiStream()
            }
        }
        .onReceive(callingVM.$showVirtualBGViewInCall) { value in
            if value {
                updateVirtualBackground()
            }
        }
        .onReceive(callingVM.$updateRemoteViewInfoMultiStream) { value in
            if value {
                updateRemoteViewInfoMultiStream()
            }
        }
        .overlay {
            if callingVM.shouldShowScreenConfig {
                ScreenShareConfigViewKS(callingVM: callingVM).frame(width: 250,height: 350)
                .cornerRadius(20)
                .opacity(1.0)
            }
        }
        .overlay {
            if callingVM.showScreenShareControl {
                BroadcastScreenShareView()
                .frame(width: 1, height: 1)
            }
        }
        .overlay {                
                if showMeetingPasswordAlertView {
                    MeetingPasswordAlertView(viewModel: callingVM, selfVideoView: selfVideoView, remoteVideoView: remoteVideoViewRepresentable, screenShareView: screenShareView)
            }
        }
        .overlay {
            if callingVM.showMultiStreamCategoryView {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            callingVM.showMultiStreamCategoryView = false
                        }
                    }
                    .transition(.opacity)
            }
            
            if callingVM.showMultiStreamCategoryView {
                withAnimation {
                    MultiStreamCategoryView(callingVM: callingVM, category: selectedCategory)
                        .transition(.scale)
                }
            }
        }
        .overlay {
            if callingVM.showSlideInMessage {
                SlideInMessageView(message: callingVM.messageText)
                    .zIndex(1)
            }
        }
        .overlay {
            if callingVM.showCustomAlert {
                if callingVM.showZoomFactor {
                    CustomAlertView(viewModel: callingVM) {
                        updateZoomFactor(factor: callingVM.customAlertTextfield1)
                    }
                }
                
                if callingVM.showAutoExposure {
                    CustomAlertView(viewModel: callingVM) {
                        updateCameraAutoExposure(targetBias: callingVM.customAlertTextfield1)
                    }
                }
                
                if callingVM.showCustomExposure {
                    CustomAlertView(viewModel: callingVM) {
                        setCameraCustomExposure(duration: callingVM.customAlertTextfield1, iso: callingVM.customAlertTextfield2)
                    }
                }
                
                if callingVM.showCameraFocus {
                    CustomAlertView(viewModel: callingVM) {
                        setCameraFocusAtPoint(pointX: callingVM.customAlertTextfield1 , pointY: callingVM.customAlertTextfield2)
                    }
                }
                
                if callingVM.showDTMFControl {
                    CustomAlertView(viewModel: callingVM) {
                        sendDTMFAuthCode(code: callingVM.customAlertTextfield1)
                    }
                }
            }
        }
        .overlay {
            if callingVM.showSelfPhoto {
                SelfPhotoView(callingVM: callingVM)
            }
        }
        .overlay {
            if callingVM.showClosedCaptionsView {
                CaptionsControlView(callingVM: callingVM)
            }
        }
        .overlay {
            if cameraSettingsVM.showSlideInMessage {
                SlideInMessageView(message: cameraSettingsVM.messageText)
                    .zIndex(1)
            }
        }
        .sheet(isPresented: $callingVM.showImagePicker) {
            ImagePicker { image in
                callingVM.showVirtualBGViewInCall = true
                cameraSettingsVM.addVirtualBackground(image: image)
            }
        }
    }
    
    func applyVirtualBackground(_ background: Phone.VirtualBackground) {
        self.cameraSettingsVM.isPreview = false
        self.cameraSettingsVM.applyVirtualBackground(background: background)
        self.callingVM.showVirtualBGViewInCall = false
        self.callingVM.showImagePicker = false
    }
    
    func updateVirtualBackground() {
        self.cameraSettingsVM.updateVirtualBackgrounds()
    }
    
    // Function to start the timer
    private func startTimer() {
        // Cancel any existing timer
        self.timer?.cancel()
        
        // Start a new timer
        self.timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect().sink { _ in
            // Check the time elapsed since the last user interaction
            if -self.lastUserInteractionTime.timeIntervalSinceNow > self.timerInterval {
                self.hideCallControlView()
            }
        }
    }

    // Function to hide the cyan view
    private func hideCallControlView() {
        withAnimation {
            self.isCallControlViewVisible = false
        }
    }

    // Function to show the cyan view
    private func showCallControlView() {
        withAnimation {
            self.isCallControlViewVisible = true
        }
        // Restart the timer
        self.startTimer()
    }
    
    static func == (lhs: CallingScreenView, rhs: CallingScreenView) -> Bool {
        return  lhs.selfVideoView != rhs.selfVideoView
    }
    
    func setCameraFocusAtPoint(pointX: String, pointY: String) {
       callingVM.setCameraFocusAtPoint(pointX: Float(pointX) ?? 0.0 , pointY: Float(pointY) ?? 0.0)
        callingVM.customAlertTextfield1 = ""
        callingVM.customAlertTextfield2 = ""
    }
    
    func updateZoomFactor(factor: String) {
        callingVM.updateZoomFactor(factor: Float(factor) ?? 1.0)
        callingVM.customAlertTextfield1 = ""
    }
    
    func updateCameraAutoExposure(targetBias: String) {
        callingVM.setCameraAutoExposure(targetBias: Float(targetBias) ?? 0.0)
        callingVM.customAlertTextfield1 = ""
    }
    
    func setCameraCustomExposure(duration: String, iso:  String) {
        callingVM.setCameraCustomExposure(duration: UInt64(duration) ?? 0, iso: Float(iso) ?? 0.0)
        callingVM.customAlertTextfield1 = ""
        callingVM.customAlertTextfield2 = ""
    }
            
    func connectCall() {
        callingVM.connectCall(selfVideoView: selfVideoView, remoteVideoViewRepresentable: remoteVideoViewRepresentable, screenShareView: screenShareView)
    }
    
    func showCategoryView(category: MultiStreamCategory) {
        selectedCategory = category
        callingVM.showMultiStreamCategoryView  = true
    }
    
    func showMultiStreamCategoryAlert() {
        DispatchQueue.main.async {
            self.isMultiStreamOptionAlertPresented = true
        }
    }
    /// Updates render views i.e. self video, remote video views
    func updateView() {
        DispatchQueue.main.async {
            callingVM.currentCall?.videoRenderViews = (self.selfVideoView.renderView, remoteVideoViewRepresentable.remoteVideoView.mediaRenderView)
        }
    }
    
    /// Update screen share view render state
    func updateScreenShare() {
        DispatchQueue.main.async {
            callingVM.currentCall?.screenShareView = self.screenShareView.renderView
        }
    }
    
    func updateRemoteViewMultiStream() {
        DispatchQueue.main.async {
            self.remoteVideoViewRepresentable.remoteVideoView.updateView(with: callingVM.currentCall?.mediaStream)
        }
    }
    
    func updateRemoteViewInfoMultiStream() {
        DispatchQueue.main.async {
            self.remoteVideoViewRepresentable.remoteVideoView.updateView(with: callingVM.currentCall?.infoMediaStream)
        }
    }
    
    func removeCategory(category: MultiStreamCategory) {
        if category == .categoryA {
            callingVM.removeMediaStreamCategoryA()
        } else if category == .categoryB {
            callingVM.removeMediaStreamCategoryB()
        } else if category == .categoryC {
            callingVM.removeMediaStreamCategoryC()
        }
    }
    
    func enableReceivingNoiseRemoval(shouldEnable: Bool) {
        callingVM.enableReceivingNoiseRemoval(shouldEnable: shouldEnable)
    }
    
    func handleNoiseRemovalAction() {
        callingVM.handleNoiseRemovalAction()
    }
    
    func updateSelectedLanguage() {
        callingVM.updateSelectedLanguage()
    }
    
    func sendDTMFAuthCode(code: String) {
        callingVM.sendDTMFAuthCode(code: code)
        callingVM.customAlertTextfield1 = ""
    }
}


// Mark:RemoteVideoView
public struct RemoteVideoViewRepresentable: UIViewRepresentable {
    var remoteVideoView: MediaStreamView

    public func makeUIView(context: Context) -> MediaStreamView {
        let mediaView = remoteVideoView
        mediaView.frame = UIScreen.main.bounds
        return mediaView
    }

    public func updateUIView(_ uiView: MediaStreamView, context: Context) {
        // Update the view
        uiView.contentMode = .scaleToFill
    }
}

@available(iOS 16.0, *)
#Preview {
    CallingScreenView(callingVM: CallViewModel(joinAddress: "", isPhoneNumber: false))
}

struct AudioRoutePicker: UIViewRepresentable {
    var isActive: Bool

    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.isHidden = true
        return routePickerView
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        if isActive {
            uiView.isHidden = false
            uiView.isUserInteractionEnabled = true
            // Find the button within the AVRoutePickerView and simulate a tap.
            if let button = uiView.subviews.first(where: { $0 is UIButton }) as? UIButton {
                button.sendActions(for: .touchUpInside)
            }
            uiView.isHidden = true
            uiView.isUserInteractionEnabled = false
        }
    }
}
