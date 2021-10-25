import Foundation

class DateUtils {
    static func getReadableDateTime(date: Date) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.doesRelativeDateFormatting = true
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        return "\(dateFormatter.string(from: date)), \(timeFormatter.string(from: date))"
    }
}
