import SwiftUI
import Combine

@available(iOS 16.0, *)
struct ClosedCaptionsListView: View {
    @ObservedObject var callingVM: CallViewModel
    
    init(callingVM: CallViewModel) {
        self.callingVM = callingVM
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(callingVM.captionItems.map { callingVM.convertToCaptionKS(caption: $0) }, id: \.id) { item in
                    VStack(alignment: .leading) {
                        Text("\(item.displayName)").font(.system(size: 16))
                        Text("\(item.content)").font(.system(size: 14))
                    }
                }
            }
            .navigationTitle("Closed Captions")
            .onAppear {
                self.callingVM.showCaptionsListView()
            }
        }
    }
}


@available(iOS 16.0, *)
struct CaptionTextView: View {
    @ObservedObject var callingVM: CallViewModel
    var isRTLLanguage: Bool = false
    
    var showCaptionView: Bool {
        return callingVM.showCaptionTextView && !callingVM.closedCaptionsTextDisplay.isEmpty
    }
    var body: some View {
        VStack {
            GeometryReader { geometry in
                Text(callingVM.closedCaptionsTextDisplay)
                    .frame(width: geometry.size.width)
                    .multilineTextAlignment(isRTLLanguage ? .trailing : .leading)
                    .padding(.all)
                    .opacity(1.0)
            }
        }
    }
}

@available(iOS 16.0, *)
struct CaptionsControlView : View {
    @ObservedObject var callingVM: CallViewModel
    
    init(callingVM: CallViewModel) {
        self.callingVM = callingVM
        self.callingVM.updateCaptionControls()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.gray.opacity(0.2).edgesIgnoringSafeArea(.all)
                VStack {
                    Text("Closed Captions")
                        .frame(width: geometry.size.width * 0.7, height: 30)
                        .font(.title)
                        .padding(.all, 10)
                    Toggle("Enable",isOn: $callingVM.closedCaptionsToggle)
                        .padding()
                        .onChange(of: callingVM.closedCaptionsToggle) { value in
                            callingVM.toggleClosedCaptions(isOn: value)
                            callingVM.showCaptionTextView = value
                        }
                    
                    if callingVM.closedCaptionsToggle {
                        HStack {
                            Text("Spoken Language: ")
                            Spacer()
                            Button {
                                callingVM.showSpokenLanguageList()
                            } label: {
                                HStack {
                                    Text(callingVM.spokenLanguageButton)
                                    Image(systemName: "chevron.right")
                                }
                            }.disabled(callingVM.canChangeSpokenLanguage)
                        }
                        .padding(.all, 10)
                        
                        HStack {
                            Text("Translation Language: ")
                            Spacer()
                            
                            Button {
                                callingVM.showTranslationLanguageList()
                            } label: {
                                HStack {
                                    Text(callingVM.translationLanguageButton)
                                    Image(systemName: "chevron.right")
                                }
                            }
                        }
                        .padding(.all, 10)
                        
                        HStack {
                            Text("Show Captions")
                            Spacer()
                            Button {
                                callingVM.showCaptionsList = true
                            } label: {
                                HStack {
                                    Image(systemName: "chevron.right")
                                }
                            }
                        }
                        .padding(.all, 10)
                    } else {
                        Rectangle().frame(width: geometry.size.width * 0.7, height: 150)
                            .foregroundColor(.clear)
                    }
                    
                    Button("Close") {
                        callingVM.showClosedCaptionsView = false
                        callingVM.showTextCaptionView()
                    }
                    .frame(minWidth:100, maxWidth: 100)
                    .padding(.all)
                    .foregroundColor(.white)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .accessibilityIdentifier("closeButton")
                }
                .frame(width: geometry.size.width * 0.7, height: 400)
                .background(Color.white)
                .cornerRadius(20)
                .padding()
                .shadow(radius: 20)
                .opacity(1.0)
                .animation(.easeInOut)
            }
        }
    }
}


@available(iOS 16.0, *)
struct TranscriptionListView: View {
    @ObservedObject var callingVM: CallViewModel
    @State private var scrollToBottom = false
    
    var body: some View {
        List {
            Section(header: Text("Transcriptions")) {
                ForEach(callingVM.transcriptionItems.map { callingVM.convertToTranscriptionKS(transcription: $0) }, id: \.id) { transcription in
                    VStack(alignment: .leading) {
                        Text("\(transcription.personName) \(transcription.timestamp)").font(.system(size: 16))
                        Text("\(transcription.content)").font(.system(size: 14))
                    }
                }
            }
            .onChange(of: callingVM.transcriptionItems) { _ in
                scrollToBottom = true
            }
        }
        .onAppear {
            scrollToBottom = true
        }
        .onChange(of: scrollToBottom) { value in
            if value {
                withAnimation {
                    scrollToBottom = false
                }
            }
        }
        .onChange(of: callingVM.transcriptionItems) { _ in
            if scrollToBottom {
                DispatchQueue.main.async {
                    withAnimation {
                        scrollToBottom = false
                    }
                }
            }
        }
    }
}

 
@available(iOS 16.0, *)
struct LanguagesListView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var  callingVM: CallViewModel
    var isSpokenLanguage: Bool = false
    
    init(callingVM: CallViewModel, isSpokenLanguage: Bool) {
        self.callingVM = callingVM
        self.isSpokenLanguage = isSpokenLanguage
    }
    var body: some View {
        NavigationView {
            List {
                if let items = callingVM.info?.spokenLanguages, isSpokenLanguage {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(item.languageTitle)").font(.system(size: 16))
                                Text("\(item.languageTitleInEnglish)").font(.system(size: 14))
                            }
                            Spacer()
                            if callingVM.selectedLanguage == item {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            callingVM.selectedLanguage = item
                            callingVM.isSpokenItemSelected = true
                            dismiss()
                        }
                    }
                }
                else {
                    if let items = callingVM.info?.translationLanguages {
                        ForEach(items, id: \.self) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(item.languageTitle)").font(.system(size: 14))
                                    Text("\(item.languageTitleInEnglish)").font(.system(size: 12))
                                }
                                Spacer()
                                if callingVM.selectedLanguage == item {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                callingVM.selectedLanguage = item
                                callingVM.isTranslationItemSelected = true
                                dismiss()
                            }
                        }
                    }
                }
            }.navigationTitle("Select Language")
        }
    }
}
