import SwiftUI
import MessageUI
import WebexSDK

@available(iOS 16.0, *)
struct CameraSettingView: View {
    
    @ObservedObject var cameraSettingVM: CameraSettingViewModel
    let videoView = MediaRenderViewRepresentable()
    
    // State to control the presentation of the views
    @State private var showImagePicker = false
    @State private var showListView = false
    @State private var showCamera = true
    @State private var frontCamera = true
    
    // State to manage the selection of images
    @State private var selectedImage: UIImage?
    
    init(cameraSettingVM: CameraSettingViewModel) {
        self.cameraSettingVM = cameraSettingVM
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack {
                    videoView
                        .frame(width: geometry.size.width, height: geometry.size.height - 250)
                        .opacity(1.0)
                    if showListView {
                        // Horizontal scrolling list
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 20) {
                                ForEach(cameraSettingVM.backgrounds.indices, id: \.self) { index in
                                    let background = cameraSettingVM.backgrounds[index]
                                    VirtualBackgroundCell(background: background, deleteAction: {
                                        cameraSettingVM.deleteItem(item: background)
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
                    }
                    List {
                        HStack {
                            Toggle("Camera", isOn: $showCamera)
                                .accessibilityIdentifier("showCamera")
                        }.onTapGesture {
                            showCamera.toggle()
                            cameraSettingVM.startPreview(start: showCamera, view: self.videoView)
                        }
                        HStack {
                            Toggle("\(frontCamera ? "Front Camera" : "Back Camera")", isOn: $frontCamera)
                                .accessibilityIdentifier("showCamera")
                        }.onTapGesture {
                            frontCamera.toggle()
                            cameraSettingVM.updateCameraFacing(frontCamera: frontCamera)
                        }
                    }
                    Spacer()
                }
            }
            .navigationBarItems(trailing: trailingBarButton)
            .onAppear() {
                self.startPreview(showCamera: true, videoView: videoView)
            }
            
            // Present the image picker view
            .sheet(isPresented: $showImagePicker) {
                ImagePicker { image in
                    cameraSettingVM.addVirtualBackground(image: image)
                    showListView = true
                }
            }
            if cameraSettingVM.showSlideInMessage {
                SlideInMessageView(message: cameraSettingVM.messageText)
                    .zIndex(1)
            }
        }.background(.black)
    }
    
    private var trailingBarButton: some View {
        HStack {
            if showListView {
                Button(action: {
                    showListView = true
                    showImagePicker = true
                }) {
                    Image(systemName: "paperclip")
                        .foregroundColor(.blue)
                }
                .accessibilityIdentifier("imagePickerButton")
            } else {
                Button(action: {
                    showListView = true
                    showImagePicker = false
                    self.updateVirtualBackground()
                }) {
                    Image(systemName: "paintbrush")
                        .foregroundColor(.blue)
                }
                .accessibilityIdentifier("virtualBackgroundListButton")
            }
        }
    }
    
    func startPreview(showCamera: Bool, videoView: MediaRenderViewRepresentable) {
        cameraSettingVM.startPreview(start: showCamera, view: videoView)
    }
    
    private func applyVirtualBackground(_ background: Phone.VirtualBackground) {
        self.cameraSettingVM.applyVirtualBackground(background: background)
    }
    
    func updateVirtualBackground() {
        self.cameraSettingVM.updateVirtualBackgrounds()
    }
}


@available(iOS 16.0, *)
struct VirtualBackgroundCell: View {
    let background: Phone.VirtualBackground
    let deleteAction: () -> Void

    init(background: Phone.VirtualBackground, deleteAction: @escaping () -> Void) {
        self.background = background
        self.deleteAction = deleteAction
    }
    
    var body: some View {
        VStack {
            ZStack {
                switch background.type {
                case .none:
                    DefaultCellView(image: "slash.circle", text: "None", isActive: background.isActive, defaultType: .none)
                case .blur:
                    DefaultCellView(image: "drop", text: "Blur", isActive: background.isActive, defaultType: .blur)
                case .custom:
                    Group {
                        if let thumbnailData = background.thumbnail.thumbnail, let image = UIImage(named: "none") {
                            DefaultCellView(image: "drop", text: "Blur", isActive: background.isActive, defaultType: .custom(image: UIImage(data: thumbnailData) ?? image))
                        } else {
                            DefaultCellView(image: "slash.circle", text: "None", isActive: background.isActive, defaultType: .none)
                        }
                    }
                    .overlay(
                            Button(action: deleteAction) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .font(.system(size: 16))
                            }
                            .offset(x: 20, y: -20)
                        )
                }
            }
        }
        .frame(width: 70, height: 70)
        .cornerRadius(15)
    }
}


struct DefaultCellView: View {
    @State var image: String
    @State var text: String
    @State var isActive: Bool = false
    
    enum DefaultType {
        case none
        case blur
        case custom(image: UIImage)
    }
    
    @State var defaultType: DefaultType
    
    var body: some View {
        VStack {
            switch defaultType {
            case .none, .blur:
                Image(systemName: image)
                    .resizable()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.white)
            case .custom(let image):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10)
            }
            switch defaultType {
            case .none, .blur:
                Text(text)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            case .custom:
                EmptyView()
            }
        }
        .frame(width: 60, height: 60)
        .padding()
        .background(Color(red: 45 / 255, green: 45 / 255, blue: 45 / 255))
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    var completionHandler: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.completionHandler(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}


struct SlideInMessageView: View {
    let message: String

    var body: some View {
        Text(message)
            .padding()
            .background(Color.gray.opacity(0.8))
            .foregroundColor(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding()
    }
}
