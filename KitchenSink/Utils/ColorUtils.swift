import UIKit

extension UIColor {
    static let momentumGray50 = UIColor(rgb: 0x24282b)
    static let momentumBlue50 = UIColor(rgb: 0x00a0d1)
    static let momentumRed50 = UIColor(rgb: 0xff5c4a)
    static let momentumYellow50 = UIColor(rgb: 0xd67f04)
    static let momentumGreen50 = UIColor(rgb: 0x24ab31)
    static let momentumOrange50 = UIColor(rgb: 0xf26b1d)
    static let momentumGold50 = UIColor(rgb: 0xba8c00)
    static let momentumOlive50 = UIColor(rgb: 0xf3f5e4)
    static let momentumLime50 = UIColor(rgb: 0x73a321)
    static let momentumMint50 = UIColor(rgb: 0x16a693)
    static let momentumCyan50 = UIColor(rgb: 0x00a3b5)
    static let momentumCobalt50 = UIColor(rgb: 0x279be8)
    static let momentumSlate50 = UIColor(rgb: 0x8c91bd)
    static let momentumViolet50 = UIColor(rgb: 0xa87ff0)
    static let momentumPurple50 = UIColor(rgb: 0xe060de)
    static let momentumPink50 = UIColor(rgb: 0xf0677e)
    static let momentumGreen40 = UIColor(rgb: 0x44cf50)
}

extension UIColor {
    static let labelColor: UIColor = {
        if #available(iOS 13.0, *) { return UIColor.label } else { return UIColor.black }
    }()
    
    static let backgroundColor: UIColor = {
        if #available(iOS 13.0, *) { return UIColor.systemBackground } else { return UIColor.white }
    }()
    
    static let secondaryBackgroundColor: UIColor = {
        if #available(iOS 13.0, *) { return UIColor.secondarySystemBackground } else { return UIColor.white }
    }()
    
    static let grayColor: UIColor = {
        if #available(iOS 13.0, *) { return UIColor.systemGray } else { return UIColor.gray }
    }()
    
    static let lighterGrayColor: UIColor = {
        if #available(iOS 13.0, *) { return UIColor.systemGray5 } else { return UIColor.lightGray }
    }()
}

extension UIColor {
   convenience init(red: Int, green: Int, blue: Int) {
       assert(red >= 0 && red <= 255, "Invalid red component")
       assert(green >= 0 && green <= 255, "Invalid green component")
       assert(blue >= 0 && blue <= 255, "Invalid blue component")

       self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
   }

   convenience init(rgb: Int) {
       self.init(
           red: (rgb >> 16) & 0xFF,
           green: (rgb >> 8) & 0xFF,
           blue: rgb & 0xFF
       )
   }
}
