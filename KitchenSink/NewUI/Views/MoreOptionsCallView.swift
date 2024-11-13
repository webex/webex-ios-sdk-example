import SwiftUI

@available(iOS 16.0, *)
struct MoreOptionsCallView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var callingVM: CallViewModel
    @State private var receivingVideo = false
    @State private var receivingAudio = false
    @State private var receivingScreenShare = false
    @State private var speechEnhancement = false
    //@State private var isVirtualBGListPresent = false
    @State private var externalCamera = false
    var isVirtualBGListPresent: Bool {
        return callingVM.showVirtualBGViewInCall
    }
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Common Calling Features")) {
                    if callingVM.isExternalCameraConnected {
                        Toggle("Use External Camera  ", isOn: $externalCamera)
                            .onChange(of: externalCamera) { newValue in
                                callingVM.connectCamera(isExternal: newValue)
                            }
                            .onReceive(callingVM.$isExternalCameraEnabled) { newValue in
                                if newValue != externalCamera {
                                    externalCamera = newValue
                                }
                            }
                            .accessibilityIdentifier("externalCameraToggle")
                    }
                    Button(action: {
                        callingVM.handleHoldCallAction()
                    }) {
                        Text(callingVM.isOnHold ? "Resume Call" : "Hold Call")
                            .foregroundStyle(Color.primary)
                    }.frame(alignment: .center)
                    .accessibilityIdentifier("resumeCall")
                    
                    Toggle("Receiving Audio Flag  ", isOn: $receivingAudio)
                        .onChange(of: receivingAudio) { newValue in
                            callingVM.handleReceivingAudioAction(isOn: newValue)
                        }
                        .onReceive(callingVM.$receivingAudio) { newValue in
                            if newValue != receivingAudio {
                                receivingAudio = newValue
                            }
                        }
                        .accessibilityIdentifier("isReceivingAudioToggle")
                    
                    Toggle("Receiving Video Flag  ", isOn: $receivingVideo)
                        .onChange(of: receivingVideo) { newValue in
                            callingVM.handleReceivingVideoAction(isOn: newValue)
                        }
                        .onReceive(callingVM.$receivingVideo) { newValue in
                            if newValue != receivingVideo {
                                receivingVideo = newValue
                            }
                        }
                        .accessibilityIdentifier("isReceivingVideoToggle")
                    
                    Toggle("Receiving ScreenShare Flag  ", isOn: $receivingScreenShare)
                        .onChange(of: receivingScreenShare) { newValue in
                            callingVM.handleReceivingScreenShareAction(isOn: newValue)
                        }
                        .onReceive(callingVM.$receivingScreenShare) { newValue in
                            if newValue != receivingScreenShare {
                                receivingScreenShare = newValue
                            }
                        }
                        .accessibilityIdentifier("receivingScreenShareToggle")

                    Toggle("Speech Enhancement  ", isOn: $speechEnhancement)
                        .onChange(of: speechEnhancement) { newValue in
                            callingVM.handleSpeechEnhancement(isOn: newValue)
                        }
                        .onReceive(callingVM.$speechEnhancement) { newValue in
                            if newValue != speechEnhancement {
                                speechEnhancement = newValue
                            }
                        }
                        .accessibilityIdentifier("speechEnhancementToggle")
                }
                
                if callingVM.isCUCMOrWxcCall {
                    Section(header: Text("WxC/CUCUM Calling")) {
                        
                        if callingVM.addedCall {
                                Button(action: {
                                    callingVM.transferCall()
                                }) {
                                    Text("Transfer Call")
                                        .foregroundStyle(Color.primary)
                                }.accessibilityIdentifier("transferCall")
                                
                                Button(action: {
                                    callingVM.mergeCall()
                                }) {
                                    Text("Merge Call")
                                        .foregroundStyle(Color.primary)
                                }
                                .accessibilityIdentifier("mergeCall")
                        } else {
                            Button(action: {
                                callingVM.showDialScreenForAddCall()
                            }) {
                                Text("Add Call")
                                    .foregroundStyle(Color.primary).frame(alignment: .center)
                            }
                            .accessibilityIdentifier("addCall")
                            
                            Button(action: {
                                callingVM.showDialScreenForDirectTransferCall()
                            }) {
                                Text("Direct Transfer Call")
                                    .foregroundStyle(Color.primary).frame(alignment: .center)
                            }
                            .accessibilityIdentifier("directTransferCall")
                            
                            Button(action: {
                                callingVM.switchTheCallToVideoOrAudio()
                            }) {
                                Text(callingVM.isAudioOnly ? "Switch to Video Call" : "Switch to Audio Call")
                                    .foregroundStyle(Color.primary)
                            }.frame(alignment: .center)
                            .accessibilityIdentifier("toggleSwitchToVideoCallBtn")
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        callingVM.showMoreOptions = false
                        callingVM.startScreenShare()
                    }) {
                        Text("Share Screen")
                            .foregroundStyle(Color.primary).frame(alignment: .center)
                    }
                    .accessibilityIdentifier("startShareScreen")
             
                    Button(action: {
                        callingVM.showMoreOptions = false
                        callingVM.showMultiStreamAlert()
                    }) {
                        Text("Multi Stream Options")
                            .foregroundStyle(Color.primary).frame(alignment: .center)
                    }
                    .accessibilityIdentifier("multiStreamOptions")
                } header: {
                    Text("Meeting Options")
                }
                
                Button(action: {
                    callingVM.mediaQualityInfoChanged()
                }) {
                    Text("receive MediaQualityInfoChangedCallback- \(callingVM.showBadNetworkIcon ? "true" : "false")")
                        .font(.system(size: 15))
                }
                if let breakout = callingVM.breakout {
                    if (breakout.allowJoinLater) {
                        ForEach(callingVM.sessions, id: \.self) { session in
                            Button(action: {
                                callingVM.showMoreOptions = false
                                callingVM.currentCall?.joinBreakoutSession(breakoutSession: session)
                            }) {
                                Text("Join Breakout Session \(session.name)")
                                    .accessibilityIdentifier("joinBreakoutSession\(session.name)")
                            }
                        }
                    }
                    
                    if breakout.allowReturnToMainSession {
                        Button(action: {
                            callingVM.showMoreOptions = false
                            callingVM.currentCall?.returnToMainSession()
                        }) {
                            Text("Return To Main Session")
                                .accessibilityIdentifier("returnToMainSession")
                        }
                    }
                }
              
                if callingVM.isClosedCaptionAllowed {
                    Button(action: {
                        callingVM.showClosedCaptionsView = true
                        dismiss()
                    }) {
                        Text("ClosedCaption Options")
                            .accessibilityIdentifier("")
                    }
                }
                
                if callingVM.isWXAEnabled {
                    Button(action: {
                        callingVM.showTranscriptions.toggle()
                        dismiss()
                    }) {
                        Text("\(callingVM.showTranscriptions ? "Hide" : "Show") Transcriptions")
                            .accessibilityIdentifier("")
                    }
                    
                    if callingVM.canControlWXA {
                        Button(action: {
                            callingVM.updateWebexAssistant()
                            dismiss()
                        }) {
                            Text("\(callingVM.isWXAEnabled ? "Disable" : "Enable") WebEx Assistant")
                                .accessibilityIdentifier("")
                        }
                    }
                    else {
                        Button(action: {
                        }) {
                            Text("WebEx Assistant \(callingVM.isWXAEnabled ? "enabled" : "disabled")")
                                .accessibilityIdentifier("")
                        }
                        .disabled(!callingVM.canControlWXA)
                    }
                }
                else {
                    Button(action: {
                    }) {
                        Text("WebEx Assistant \(callingVM.isWXAEnabled ? "enabled" : "disabled")")
                            .accessibilityIdentifier("")
                    }
                    .disabled(!callingVM.canControlWXA)
                }

                Button(action: {
                        callingVM.showCustomAlert = true
                        callingVM.showMoreOptions = false
                        callingVM.placeholderText1 = "Enter Authorisation code"
                        callingVM.placeholderText2 = ""
                        callingVM.customAlertTitle = "Enter authorisation code"
                        callingVM.showDTMFControl = true
                }) {
                    Text("Enter authorisation code")
                        .accessibilityIdentifier("authorisationCode")
                }
                
                Button(action: {
                    callingVM.showMoreOptions = false
                    callingVM.setRenderMode(mode: callingVM.renderMode)
                }) {
                    Text("Video Render Mode - \(String(describing: callingVM.renderMode))")
                        .accessibilityIdentifier("videoRenderMode")
                }
                        
                Button(action: {
                    callingVM.showMoreOptions = false
                    callingVM.setTorchMode(mode: callingVM.torchMode)
                }) {
                    Text("Video Torce Mode - \(String(describing: callingVM.torchMode))")
                        .accessibilityIdentifier("videoTorchMode")
                }
                
                Button(action: {
                    callingVM.showMoreOptions = false
                    callingVM.setFlashMode(mode: callingVM.flashMode)
                }) {
                    Text("Video Flash Mode - \(String(describing: callingVM.flashMode))")
                        .accessibilityIdentifier("videoFlashMode")
                }
                
                if !isVirtualBGListPresent {
                    Button(action: {
                        callingVM.showMoreOptions = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let result = callingVM.isCameraOff()
                            if !result {
                                callingVM.showVirtualBGViewInCall = true
                            }
                        }
                    }) {
                        Text("Change Virtual Background")
                            .accessibilityIdentifier("changeVirtualBGButton")
                    }
                } else {
                    Button(action: {
                        callingVM.showMoreOptions = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let result = callingVM.isCameraOff()
                            if !result {
                                callingVM.showImagePicker = true
                            }
                        }
                    }) {
                        Text("Add Virtual Background")
                            .accessibilityIdentifier("addVirtualBGButton")
                    }
                }
                
                Button(action: {
                    callingVM.showMoreOptions = false
                    callingVM.showZoomFactor = true
                    callingVM.placeholderText1 = "Enter Zoom value"
                    callingVM.placeholderText2 = ""
                    callingVM.customAlertTitle = "Camera Zoom Factor"
                    callingVM.showCustomAlert = true
                }) {
                    Text("Camera Zoom Factor: Zoom- \(callingVM.zoomFactor)")
                        .accessibilityIdentifier("cameraZoomFactor")
                }
                
                Button(action: {
                    callingVM.placeholderText2 = ""
                    callingVM.showMoreOptions = false
                    callingVM.showAutoExposure = true
                    callingVM.placeholderText1 = "Enter Target Bias value"
                    callingVM.placeholderText2 = ""
                    callingVM.customAlertTitle = "Custom Auto Exposure"
                    callingVM.showCustomAlert = true
                }) {
                    Text("Auto Exposure: Target Bias- \(Float(callingVM.cameraTargetBias?.current ?? 0.0))")
                        .accessibilityIdentifier("autoExposureTargetBias")
                }
                Button(action: {
                    
                    callingVM.showMoreOptions = false
                    callingVM.showCustomExposure = true
                    callingVM.placeholderText1 = "Enter Duration value"
                    callingVM.placeholderText2 = "Enter ISO value"
                    callingVM.customAlertTitle = "Camera Custom Exposure"
                    callingVM.showCustomAlert = true
                }) {
                    Text("Custom Exposure: Duration- \(UInt64(callingVM.cameraDuration?.current ?? 0)) ISO- \(Float(callingVM.cameraISO?.current ?? 0))")
                        .font(.system(size: 15))
                        .accessibilityIdentifier("customExposureDurationAndISO")
                }
                Button(action: {
                    callingVM.showMoreOptions = false
                    callingVM.showCameraFocus = true
                    callingVM.placeholderText1 = "Enter point X value"
                    callingVM.placeholderText2 = "Enter point Y value"
                    callingVM.customAlertTitle = "Camera Focus"
                    callingVM.showCustomAlert = true
                }) {
                    Text("Set Camera Focus")
                        .accessibilityIdentifier("setCameraFocus")
                }
                Button(action: {
                    callingVM.showMoreOptions = false
                    callingVM.takePhoto()
                }) {
                    Text("Take Photo")
                        .accessibilityIdentifier("takePhoto")
                }
            }
        }
    }
    
    private func updateSettings() {
        callingVM.showCustomAlert = true
        callingVM.showMoreOptions = false
    }
}

@available(iOS 16.0, *)
#Preview {
    MoreOptionsCallView(callingVM: CallViewModel(joinAddress: "", isPhoneNumber: false))
}
