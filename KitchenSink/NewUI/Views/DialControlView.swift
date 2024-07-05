import SwiftUI

@available(iOS 16.0, *)
struct DialControlView: View {
    @State private var phoneNumber = ""
    @State private var showNumberPad = true
    @State private var isPhoneNumberToggleOn = false
    @State private var isMoveMeetingToggleOn = false
    @State private var showCallingView = false
    @State private var isPhoneServicesOn = false
    @ObservedObject var viewModel: DialControlViewModel
    @ObservedObject var phoneServicesViewModel: UCLoginServicesViewModel

    let numberPad: [[String]] = [
                                 ["1", "2", "3"],
                                 ["4", "5", "6"],
                                 ["7", "8", "9"],
                                 ["+", "0", "#"]
                                ]
    
    var body: some View {
        GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                        VStack {
                            Spacer()
                            if !viewModel.fromCallingScreen && phoneServicesViewModel.isWebexOrCucmCalling() {
                                Toggle("Phone Services:  \(phoneServicesViewModel.uCServerConnectionStatus)", isOn: $isPhoneServicesOn)
                                .frame(width: 300, height: 40)
                                .onChange(of: isPhoneServicesOn) { newValue in
                                        phoneServicesViewModel.togglePhoneServices(isOn: newValue)
                                }
                                .onReceive(phoneServicesViewModel.$phoneServiceConnected) { newValue in
                                    if newValue != isPhoneServicesOn {
                                        isPhoneServicesOn = newValue
                                    }
                                }
                                .accessibilityIdentifier("phoneServicesToggle")
                            }
                            
                            HStack {
                                TextField(self.showNumberPad ? "Dial number" : "Dial email address", text: $phoneNumber)
                                    .font(.title)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 250, height: 60)
                                    .accessibilityIdentifier("dialTextField")
                                
                                if !phoneNumber.isEmpty {
                                    Button(action: {
                                        self.phoneNumber = ""
                                    }) {
                                        Image(systemName: "clear")
                                            .font(.system(size: 20))
                                            .frame(width: 30, height: 30)
                                    }
                                    .accessibilityIdentifier("clearBtn")
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        self.showNumberPad.toggle()
                                    }
                                }) {
                                    Image(self.showNumberPad ? "number-pad" : "keyboard-universal")
                                        .font(.system(size: 20))
                                        .frame(width: 25, height: 25)
                                }.padding(.trailing)
                            }
                            
                            VStack(alignment: .center) {
                                if showNumberPad {
                                    ForEach(0..<numberPad.count, id:\.self) { i in
                                        HStack {
                                            ForEach(0..<self.numberPad[i].count, id:\.self) { j in
                                                Spacer().frame(width:10)
                                                Button(action: {
                                                    self.phoneNumber.append(self.numberPad[i][j])
                                                }) {
                                                    Text(self.numberPad[i][j])
                                                        .font(.title)
                                                        .frame(width: 70, height: 70)
                                                        .foregroundColor(.white)
                                                        .background(Color(UIColor.systemGray2))
                                                        .clipShape(Circle())
                                                    
                                                }
                                                Spacer().frame(width:5)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Spacer().frame(height:20)
                            
                            VStack(spacing: 0) {
                                Button(action: {
                                    handleCallAction()
                                }) {
                                    Image(systemName: "phone.arrow.up.right")
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.white)
                                        .font(.system(size: 30))
                                        .frame(width: 70, height: 70)
                                        .background(Color.green)
                                        .clipShape(Circle())
                                }
                                .accessibilityIdentifier("call")
                                
                                ToggleButtonWithText(isOn: $isPhoneNumberToggleOn, text: "Dial Phone Number ?").padding()
                                    .bold()
                                ToggleButtonWithText(isOn: $isMoveMeetingToggleOn, text: "Move Meeting ?")
                                    .bold()
                            }
                            Spacer()
                    }
                }
                
                .frame(width: geometry.size.width, height: geometry.size.height)
                .padding(.top, geometry.safeAreaInsets.top)
                .fullScreenCover(isPresented: $viewModel.showCallingView) {
                    CallingScreenView(callingVM: viewModel.callViewModel ?? CallViewModel(joinAddress: phoneNumber, isPhoneNumber: isPhoneNumberToggleOn, isMoveMeeting: isMoveMeetingToggleOn)).equatable()
                }
                .sheet(isPresented: $phoneServicesViewModel.showUCLoginServicesNonSSOScreen) {
                    UCLoginNonSSOLoginView(viewModel: phoneServicesViewModel)
                }
                .onAppear(perform: phoneServicesViewModel.setUCLoginDelegateAndStartUCServices)
                Spacer()
            }
    }
    
    /// Handle call action
    func handleCallAction() {
        self.viewModel.handleCallAction(phoneNumber: phoneNumber, isPhoneNumberToggleOn: isPhoneNumberToggleOn, isMoveMeetingToggleOn: isMoveMeetingToggleOn)
    }
}

@available(iOS 15.0, *)
struct ToggleButtonWithText: View {
    @Binding var isOn: Bool
    var text: String
    
    var body: some View {
        HStack {
            Text(text)
                .font(.headline)
                .foregroundColor(.primary)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .accessibilityIdentifier("dialNumberToggle")
        }
        .frame(width: 300, height: 50)
    }
}

@available(iOS 16.0, *)
#Preview {
    DialControlView(viewModel: DialControlViewModel(), phoneServicesViewModel: UCLoginServicesViewModel())
}
