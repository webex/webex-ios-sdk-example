import SwiftUI
import WebexSDK

@available(iOS 16.0, *)
struct MessageComposerView: View {

    @State var textMode: String = "Plain"
    @State var imagePickerShowing: Bool = false
    @State var showMentionList: Bool = false
    @State var showingTextModes: Bool = false
    @State var selectedItemIndex: Int = 0
    @State var space: SpaceKS

    @ObservedObject var model = MessageComposerViewModel()

    /// Initializes a new instance with the given `SpaceKS` data.
    init(space: SpaceKS) {
        self.space = space
    }

    var body: some View {
        NavigationView {
            ZStack
            {
                VStack
                {
                    HStack {
                        Text(space.name ?? "")
                            .font(.title)
                            .padding(.horizontal)
                        Spacer()
                    }
                    TextEditor(text: $model.text)
                        .accessibilityIdentifier("sendMessageTextfield")
                        .onChange(of: model.text) { newValue in
                            if newValue.last == "@" && !showMentionList {
                                model.text = String(model.text.dropLast())
                                getMentionList(spaceId: space.id ?? "")
                                showMentionList = true
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.primary, lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .frame(height: 150)
                       HStack {
                            KSButton(isSmall: true, text: textMode, didTap: false, action: {
                                showingTextModes = true
                            })
                            .accessibilityIdentifier("messageTypeButton")
                            .padding()
                            KSButton(isSmall: true, text: "Send", didTap: true, action: {
                                sendMessage()
                            })
                            .padding()
                            .accessibilityIdentifier("sendMessageButton")
                        }
                
                    Grid {
                        ScrollView {
                            GridRow {
                                ForEach(0 ..< model.images.count, id:\.self) { i in
                                    Image(uiImage: model.images[i])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: UIScreen.main.bounds.width - 20)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    Spacer()
                }                
                .navigationBarTitle("Send Message", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            imagePickerShowing = true
                        }) {
                            Image(systemName: "photo.artframe")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                        }.foregroundColor(.secondary)
                    }
                }.sheet(isPresented: $imagePickerShowing, content: {
                    ImagePickerView(sourceType: .photoLibrary, onImagePickedInfo: { info in
                        addLocalFile(imageInfo: info)
                        if let image = info[.originalImage] as? UIImage {
                            model.images.append(image)
                        }
                    })
                })
                .confirmationDialog("Select a Text style", isPresented: $showingTextModes, titleVisibility: .visible) {
                    Button("Plain") {
                        textMode = "Plain"
                    }
                    .accessibilityIdentifier("plainText")
                    Button("Markdown") {
                        textMode = "Markdown"
                    }
                    .accessibilityIdentifier("markdownText")
                    Button("HTML") {
                        textMode = "HTML"
                    }
                    .accessibilityIdentifier("htmlText")
                }
                .alert("Error", isPresented: $model.showError) {
                    Button("Ok") { }
                } message: {
                    Text(model.error)
                }
                .alert("Message Sent", isPresented: $model.isSent) {
                    Button("Ok") {
                        model.text = ""
                        model.mentions = []
                    }
                } message: {
                    Text(model.sentText)
                        .accessibilityIdentifier("alertMessageText")
                }
                .sheet(isPresented: $showMentionList) {
                    MentionsListView(model: model, space: space) { index in
                        selectedItemIndex = index
                        selectItemInMentionList(indexPos: selectedItemIndex)
                    }
                }
                if model.isLoading {
                    ActivityIndicatorView()
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }

    /// Sends a message to a space with the given ID, text, text mode, and mentions.
    func sendMessage() {
        model.sendMessage(id: space.id ?? "", text: model.text, textMode: textMode, mentions: model.mentions)
    }

    /// Adds a local file with the given image information.
    func addLocalFile(imageInfo: [UIImagePickerController.InfoKey: Any]) {
        model.addLocalFile(info: imageInfo)
    }
    
    /// Selects an item in the mention list at the given index position, appends the selected mention to the text, and hides the mention list.
    func selectItemInMentionList(indexPos: Int) {
        let startPos = self.model.text.count
        let endPos = startPos + model.mentionList[indexPos].personName.count
        let mention: Mention = indexPos == 0 ? .all(MentionPos(id: "", start: startPos, end: startPos + 3)) : .person(MentionPos(id: model.mentionList[indexPos].id, start: startPos, end: endPos))
        model.mentions.append(mention)
        model.text.append(model.mentionList[indexPos].personName)
        showMentionList = false
    }
    
    /// Fetches the mention list for the space with the given ID asynchronously.
    func getMentionList(spaceId: String) {
        Task {
            await model.getAllMentionsListAsync(spaceId: space.id ?? "")
        }
    }
}

@available(iOS 16.0, *)
struct MentionsListView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: MessageComposerViewModel
    var space: SpaceKS
    var onMentionItemSelected: (Int) -> Void

    /// Initializes a new instance with the given message composer view model, space, and mention item selection handler.
    init(model: MessageComposerViewModel, space: SpaceKS, onMentionItemSelected: @escaping (Int) -> Void ) {
        self.space = space
        self.model = model
        self.onMentionItemSelected = onMentionItemSelected
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(model.mentionList, id:\.id) { mention in
                    Text(mention.personName)
                        .font(.subheadline)
                        .onTapGesture {
                            onMentionItemSelected(model.mentionList.firstIndex(where: { $0.id == mention.id }) ?? -1)
                            dismiss()
                        }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Mentions")
        }
        .overlay {
            if model.isLoading {
                ActivityIndicatorView()
            }
        }
    }
}
