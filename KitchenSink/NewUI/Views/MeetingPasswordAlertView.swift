import SwiftUI

@available(iOS 16.0, *)
struct MeetingPasswordAlertView: View {
    @ObservedObject var viewModel: CallViewModel
    var remoteVideoView: RemoteVideoViewRepresentable!
    var selfVideoView:  MediaRenderViewKS!
    var screenShareView: MediaRenderViewKS!
    
    init(viewModel: CallViewModel, selfVideoView: MediaRenderViewKS, remoteVideoView: RemoteVideoViewRepresentable, screenShareView: MediaRenderViewKS) {
        self.viewModel = viewModel
        self.selfVideoView = selfVideoView
        self.remoteVideoView = remoteVideoView
        self.screenShareView = screenShareView
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.gray.opacity(0.2).edgesIgnoringSafeArea(.all)
                    Form {
                        Section(header: Text(viewModel.captchaViewTitle).font(.headline).bold()) {
                            Text(viewModel.captchaViewMessage)
                                .background(.clear)
                                .font(.subheadline)
                            if viewModel.showCaptchaView {
                                HStack {
                                    if let image = viewModel.captchaImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 60)
                                    }
                                    Spacer()
                                    Button(action: {
                                        viewModel.handleCaptchaAudioButtonAction()
                                    }) {
                                        Image(systemName: "speaker.wave.2.fill")
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .accessibilityIdentifier("captchaSpeakerButton")
                                    
                                    Button(action: {
                                        viewModel.handleCaptchaRefreshAction()
                                    }) {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .accessibilityIdentifier("captchaRefreshButton")
                                }
                                .padding(.vertical)
                                
                                TextField("Enter Captcha", text: $viewModel.captchaCode)
                                    .accessibilityIdentifier("captchaCodeTextField")
                            }
                        }
                        
                        Section {
                            TextField("Meeting Password", text: $viewModel.meetingPinOrPassword)
                                .accessibilityIdentifier("pinOrPasswordTextField")
                            TextField("Host Key", text: $viewModel.hostKey)
                                .accessibilityIdentifier("hostKeyTestField")
                        }
                        
                        Section {
                            HStack(alignment: .center) {
                                Spacer()
                                Button("Cancel") {
                                }
                                .onTapGesture {
                                    viewModel.handleEndCall()
                                    viewModel.showMeetingPasswordView = false
                                }
                                .frame(minWidth: 0, maxWidth: 250)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .accessibilityIdentifier("cancelButton")
                                
                                Spacer(minLength: 20)
                                
                                Button("OK") {
                                }
                                .onTapGesture {
                                    if !viewModel.hostKey.isEmpty {
                                        viewModel.meetingPinOrPassword = viewModel.hostKey
                                        viewModel.isModerator = true
                                    }
                                    viewModel.connectCall(selfVideoView: selfVideoView, remoteVideoViewRepresentable: remoteVideoView, screenShareView: screenShareView)
                                    viewModel.showMeetingPasswordView = false
                                }
                                .frame(minWidth: 0, maxWidth: 250)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .clipShape(Capsule())
                                .accessibilityIdentifier("okButton")
                                Spacer()
                            }
                            .background(Color.clear)
                            .listRowInsets(EdgeInsets())
                        }
                        .background(Color.clear)
                        .listRowBackground(Color.clear)
                    }
                    .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.7)
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding()
                    .shadow(radius: 20)
                    .opacity(viewModel.showMeetingPasswordView ? 1 : 0)
                    .animation(.easeInOut)
                    Spacer()
            }
            .onAppear {
                if let captcha = viewModel.captcha {
                    viewModel.updateCaptcha(captcha: captcha)
                }
            }
        }
    }
    
    func updateCaptchaData() {
        if viewModel.showCaptchaView,  let captcha = viewModel.captcha  {
                viewModel.updateCaptcha(captcha: captcha)
        }
    }
}

@available(iOS 16.0, *)
struct CustomAlertView: View {
    @ObservedObject var viewModel: CallViewModel
    let onSaveSettings: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.gray.opacity(0.2).edgesIgnoringSafeArea(.all)
                Form {
                    Section(header: Text(viewModel.customAlertTitle).font(.headline).bold().foregroundStyle(.primary)) {
                        TextField(viewModel.placeholderText1, text: $viewModel.customAlertTextfield1)
                        if !viewModel.placeholderText2.isEmpty {
                            TextField(viewModel.placeholderText2 , text: $viewModel.customAlertTextfield2)
                        }
                    }
                    Section {
                        HStack(alignment: .center) {
                            Spacer()
                            Button("Cancel") {
                                viewModel.showCustomAlert = false
                            }
                            .frame(minWidth: 0, maxWidth: 250)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .accessibilityIdentifier("cancelButton")
                            
                            Spacer(minLength: 20)
                            
                            Button("OK") {
                                onSaveSettings()
                                viewModel.showCustomAlert = false
                            }
                            .frame(minWidth: 0, maxWidth: 250)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .accessibilityIdentifier("okButton")
                            Spacer()
                        }
                        .background(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                    .background(Color.clear)
                    .listRowBackground(Color.clear)
                }
                .frame(width: 310, height: viewModel.placeholderText2.isEmpty ? 210 : 250)
                .background(Color.white)
                .cornerRadius(20)
                .padding()
                .shadow(radius: 20)
                .opacity(viewModel.showCustomAlert ? 1 : 0)
                .animation(.easeInOut)
                .scrollDisabled(true)
                Spacer()
            }
        }
    }
}
