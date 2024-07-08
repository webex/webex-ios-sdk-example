import SwiftUI
import WebexSDK

@available(iOS 16.0, *)
class CameraSettingViewModel: ObservableObject {
    let webexPhone  = WebexPhone()
    @Published var showSlideInMessage = false
    @Published var messageText = ""
    @Published var backgrounds: [Phone.VirtualBackground] = []
    var isPreview: Bool = true

    /// Start preview the camera view
    func startPreview(videoView: MediaRenderViewRepresentable) {
        DispatchQueue.main.async { [weak self] in
            self?.webexPhone.startPreview(videoView: videoView.renderVideoView)
        }
    }
    
    /// Update the virtual background list on add, update, delete
    func updateVirtualBackgrounds() {
        self.webexPhone.updateVirtualBackgrounds { [weak self] result in
            DispatchQueue.main.async {
                self?.backgrounds = result
            }
        }
    }
    
    /// Add selected image from gallery to background list
    func addVirtualBackground(image: UIImage) {
        let resizedThumbnail = image.resizedImage(for: CGSize(width: 64, height: 64))
        
        guard let imageData = image.pngData(),
              let thumbnailData = resizedThumbnail?.pngData() else { return }
        
        let fileName = "background_\(UUID().uuidString).png"
        let thumbnailFileName = "thumbnail_\(UUID().uuidString).png"
        
        let imagePath = FileUtils.writeToFile(data: imageData, fileName: fileName)
        let thumbnailPath = FileUtils.writeToFile(data: thumbnailData, fileName: thumbnailFileName)
        
        guard let thumbnailFilePath = thumbnailPath?.path,
              let thumbnailFileType = thumbnailPath?.pathExtension,
              let localFilePath = imagePath?.path,
              let localFileType = imagePath?.pathExtension else {
            print("Failed to get file paths")
            return
        }
        
        let thumbnail = LocalFile.Thumbnail(path: thumbnailFilePath, mime: thumbnailFileType, width: 64, height: 64)
        guard let localFile = LocalFile(path: localFilePath, name: fileName, mime: localFileType, thumbnail: thumbnail) else { print("Failed to get local file"); return }
        
        self.webexPhone.addVirtualBackground(image: localFile ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let background):
                    self?.backgrounds.append(background)
                    self?.showSlideInMessage(message: "Successfully uploaded background")
                case .failure(let error):
                    self?.showSlideInMessage(message: "Failed to add virtual background: \(error)")
                @unknown default:
                    self?.showSlideInMessage(message: "Failed to add virtual background")
                }
            }
        }
    }
    
    /// Apply virtual background from background list
    func applyVirtualBackground(background: Phone.VirtualBackground) {
        self.webexPhone.applyVirtualBackground(background: background, isPreview: isPreview) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self?.updateVirtualBackgrounds()
                    self?.showSlideInMessage(message: "Successfully updated background")
                case .failure(let error):
                    self?.showSlideInMessage(message: "Failed updating background with error: \(error)")
                @unknown default:
                    self?.showSlideInMessage(message: "Failed updating background")
                    
                }
            }
        }
    }
    
    /// Delete a virtual custom background
    func deleteItem(item: Phone.VirtualBackground?) {
        guard let item = item else {
            print("Virtual background item is nil")
            return
        }
        
        self.webexPhone.deleteItem(item: item) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self?.showSlideInMessage(message: "Successfully deleted background")
                    self?.updateVirtualBackgrounds()
                case .failure(let error):
                    self?.showSlideInMessage(message: "Failed deleting background with error: \(error)")
                @unknown default:
                    self?.showSlideInMessage(message: "Failed deleting background")
                }
            }
        }
    }
    
    /// Shows message alert when virtual backgrounds applied, deleted
    private func showSlideInMessage(message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.showSlideInMessage = true
            self?.messageText = message
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            withAnimation {
                self?.showSlideInMessage = false
            }
        }
    }
    
    func stopPreview() {
        webex.phone.stopPreview()
    }
    
    func updateCameraFacing(frontCamera: Bool) {
        if frontCamera {
            webexPhone.defaultFacingMode = .user
        } else {
            webexPhone.defaultFacingMode = .environment
        }
    }
    
    func startPreview(start: Bool, view: MediaRenderViewRepresentable)
    {
        if start {
            webexPhone.startPreview(videoView: view.renderVideoView)
        } else {
            webexPhone.stopPreview()
        }
    }
}
