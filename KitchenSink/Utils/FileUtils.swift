import Foundation

class FileUtils {
    static func writeToFile(data: Data, fileName: String) -> URL? {
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
}
