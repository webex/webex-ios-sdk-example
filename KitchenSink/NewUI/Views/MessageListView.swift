import SwiftUI

@available(iOS 16.0, *)
struct MessageListView: View {

    var space: SpaceKS

    @ObservedObject var model = MessageListViewModel()

    /// Initializes a new instance with the given `SpaceKS` data.
    init(space: SpaceKS) {
        self.space = space
    }

    var body: some View {
        NavigationView {
                List {
                    ForEach(model.messages.filter { !$0.isReply }, id: \.messageId) { message in
                        MessageView(model: model, message: message, replies: model.messages.filter { $0.isReply && $0.parentMessageId == message.messageId })
                    }
                }
                .overlay(content: {
                    if model.isLoading {
                        ActivityIndicatorView()
                    }
                    if model.showProgress {
                        ProgressView("Downloading", value: model.progress, total: model.size)
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding()
                    }
                })
                .alert("Error", isPresented: $model.showError) {
                    Button("Ok") { }
                } message: {
                    Text(model.error)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .navigationBarTitle(space.name ?? "Chat", displayMode: .inline)
                .onAppear(perform: refreshMessages)
        }
    }
    
    /// Fetches and updates the list of messages for the space with the given ID using the model.
    func refreshMessages() {
        model.listMessages(spaceId: space.id ?? "")
    }
}

@available(iOS 16.0, *)

struct MessageView: View {
    @State var isExpanded = false
    @ObservedObject var model: MessageListViewModel
    var message: MessageKS
    var replies: [MessageKS]

    var body: some View {
        VStack(alignment: message.isCurrentUser ? .trailing : .leading) {
            MessageBubbleView(model: model, message: message)
            if isExpanded {
                ForEach(replies, id: \.messageId) { reply in
                    MessageBubbleView(model: model, message: reply)
                        .padding(.horizontal, 20)
                }
            }
            if !replies.isEmpty {
                Button(action: {
                    isExpanded.toggle()
                }) {
                    Text(isExpanded ? "Hide Replies" : "Show Replies")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct MessageBubbleView: View {
    @State var showActionSheet = false
    @State var showAlert = false
    @State var showReplyAlert = false
    @State var editedMessage = ""
    @State var replyMessage = ""
    @ObservedObject var model: MessageListViewModel
    var message: MessageKS

    var body: some View {
        ZStack {
            VStack {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(0 ..< (message.thumbnail.count), id:\.self) { i in
                            Image(uiImage: message.thumbnail[i])
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .cornerRadius(10)
                                .onTapGesture {
                                    downloadFile(index: i)
                                }
                        }
                    }
                }
                HStack {
                    if !message.isCurrentUser {
                        Spacer()
                    }
                    VStack {
                        Text(message.timeStamp)
                            .font(.caption2)
                        Text("\(message.sender): \(message.text)")
                            .padding(10)
                            .background(message.isCurrentUser ? Color.blue : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .onTapGesture {
                                showActionSheet = true
                            }
                            .actionSheet(isPresented: $showActionSheet) {
                                ActionSheet(
                                    title: Text("Actions"),
                                    buttons: message.isCurrentUser ?
                                    [
                                        .default(Text("Reply"), action: {
                                            showReplyAlert = true
                                        }),
                                        .default(Text("Fetch messages before this date"), action: {
                                            fetchMessageBeforeDate()
                                        }),
                                        .default(Text("Fetch messages before this messageId"), action: {
                                            fetchMessageBeforeId()
                                        }),
                                        .default(Text("Mark as read"), action: {
                                            markMessageRead()
                                        }),
                                        .default(Text("Edit"), action: {
                                            showAlert = true
                                        }),
                                        .destructive(Text("Delete"), action: {
                                            deleteMessage()
                                        }),
                                        .cancel()
                                    ]
                                    :
                                        [
                                            .default(Text("Reply"), action: {
                                                showReplyAlert = true
                                            }),
                                            .default(Text("Fetch messages before this date"), action: {
                                                fetchMessageBeforeDate()
                                            }),
                                            .default(Text("Fetch messages before this messageId"), action: {
                                                fetchMessageBeforeId()
                                            }),
                                            .default(Text("Mark as Read"), action: {
                                                markMessageRead()
                                            }),
                                            .cancel()
                                        ]
                                )
                            }
                    }
                    if message.isCurrentUser {
                        Spacer()
                    }
                }
            }
            .sheet(isPresented: $model.showfileSheet, content: {
                WebFileView(url: model.fileURL ?? URL(string: "https://google.com")!)
            })
            .alert(isPresented: $showAlert, title: "Edit Message", textFieldValue: $editedMessage, action: editMessage)
            .alert(isPresented: $showReplyAlert, title: "Reply Message", textFieldValue: $replyMessage, action: sendReply)
        }
        .alert(isPresented: $model.markedAsRead) {
            Alert(title: Text("Successfully marked as read"))
        }
        .alert(isPresented: $model.replySent) {
            Alert(title: Text("Successfully reply sent"))
        }
    }

    /// Initiates the download of a file at the specified index from the message's files.
    func downloadFile(index: Int) {
        guard let files = message.message.files else { 
            return
            }
        guard files.count > index else {
            print("Could not find file to download at index \(index)")
            return
            }
        model.downloadFile(remoteFile: files[index])
    }

    /// Fetches and updates the list of messages in the space created before the date of the current message using the model.
    func fetchMessageBeforeDate() {
        if let createdDate = message.message.created {
            model.listMessages(spaceId: message.message.spaceId ?? "", before: .date(createdDate))
        }
    }
    
    /// Fetches and updates the list of messages in the space created before the ID of the current message using the model.
    func fetchMessageBeforeId() {
        model.listMessages(spaceId: message.message.spaceId ?? "", before: .message(message.messageId))
    }

    /// Marks the current message as read using the model.
    func markMessageRead() {
        model.markMessageAsRead(message: message)
    }

    /// Edits the current message with the provided text using the model.
    func editMessage() {
        model.editMessage(text: editedMessage, message: message)
    }

    /// Deletes the current message using the model.
    func deleteMessage() {
        model.deleteMessage(message: message)
    }

    /// Send the reply to the parent message using the model.
    func sendReply() {
        model.sendReply(parent: message, text: replyMessage)
    }
}

@available(iOS 16.0, *)
struct MessageListView_Previews: PreviewProvider {
    static var previews: some View {
        MessageListView(space: SpaceKS())
    }
}
