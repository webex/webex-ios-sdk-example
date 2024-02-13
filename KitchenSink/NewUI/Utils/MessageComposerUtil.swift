import SwiftUI
import AVFoundation
import WebexSDK

class MessageComposerUtil {
    func convertTextToMessageText(text: String, textMode: String) -> Message.Text {
        if textMode == "Markdown" {
            return Message.Text.markdown(markdown: text)
        } else if textMode == "HTML" {
            return Message.Text.html(html: text)
        } else {
            return Message.Text.plain(plain: text)
        }
    }

    func addLocalFile(info: [UIImagePickerController.InfoKey: Any], currentLocalFiles: [LocalFile]) -> [LocalFile] {
        var localFiles = currentLocalFiles
        var thumbnailImage: UIImage?
        var fileURL: URL?
        if info[.mediaType] as? String ?? "" == "public.movie" {
            if let url = info[.mediaURL] as? URL {
                fileURL = url
                thumbnailImage = thumbnailForVideo(url: url)
            }
        } else {
            thumbnailImage = info[.originalImage] as? UIImage
            if let url = info[UIImagePickerController.InfoKey.imageURL] as? URL {
                fileURL = url
            }
        }

        guard let image = thumbnailImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }

        guard let url = fileURL else {
            return localFiles
        }

        let fileName = url.lastPathComponent
        let fileType = url.pathExtension

        do {
            let data = try Data(contentsOf: url)
            let path = writeToFile(data: data, fileName: fileName)
            guard let filePath = path?.absoluteString.replacingOccurrences(of: "file://", with: "") else { return localFiles }

            guard let thumbnailData = image.pngData() else { return localFiles }
            let thumbnailPath = writeToFile(data: thumbnailData, fileName: "thumnail"+fileName)

            guard let thumbnailFilePath = thumbnailPath?.absoluteString.replacingOccurrences(of: "file://", with: "") else { return localFiles }

            let thumbnail = LocalFile.Thumbnail(path: thumbnailFilePath, mime: fileType, width: Int(image.size.width), height: Int(image.size.height))

            let duplicate = localFiles.contains { // checking if already attached
                let url1 = URL(fileURLWithPath: $0.path)
                let url2 = URL(fileURLWithPath: filePath)

                if let data1 = try? Data(contentsOf: url1), let data2 = try? Data(contentsOf: url2) {
                    return data1 == data2
                } else {
                    return false
                }
            }

            if duplicate { // if already attached returning
                return localFiles
            }

            guard let localFile = LocalFile(path: filePath, name: fileName, mime: fileType, thumbnail: thumbnail, progressHandler: { progress in
                  // implement progress bar
                print("localFiles progress \(fileName) \(progress)")
            }) else { return localFiles }

            localFiles.append(localFile)
            return localFiles
        }
        catch let error {
            print(error.localizedDescription)
            return localFiles
        }
    }

    private func writeToFile(data: Data, fileName: String) -> URL? {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let fileDirectory = documentDirectory?.appendingPathComponent("Files") else { return URL(string: "") }

        guard let path = URL(string: "\(fileDirectory)\(fileName)") else { return URL(string: "") }
        do {
            try FileManager.default.createDirectory(atPath: fileDirectory.path, withIntermediateDirectories: true, attributes: nil)
            try data.write(to: path)
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
        return path
    }

    func thumbnailForVideo(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true

        var time = asset.duration
        time.value = min(time.value, 2)

        do {
            let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print("failed to create thumbnail")
            return nil
        }
    }
}
