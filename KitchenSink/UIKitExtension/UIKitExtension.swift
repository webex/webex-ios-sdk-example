// Copyright 2016-2017 Cisco Systems Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit
extension UIFont {
    static let fontFamilyDesc: [UIFontDescriptor.AttributeName:Any] = [UIFontDescriptor.AttributeName.family: "Arial"]
    
    static func buttonLightFont(ofSize size:CGFloat) -> UIFont {
        return withWeight(fromDescriptor: UIFontDescriptor(fontAttributes:fontFamilyDesc), weight: .light,size: size)
    }
    
    static func labelLightFont(ofSize size:CGFloat) -> UIFont {
        return withWeight(fromDescriptor: UIFontDescriptor(fontAttributes:fontFamilyDesc), weight: .light,size: size)
    }
    static func textViewLightFont(ofSize size:CGFloat) -> UIFont {
        return withWeight(fromDescriptor: UIFontDescriptor(fontAttributes:fontFamilyDesc), weight: .light,size: size)
    }
    
    static func navigationBoldFont(ofSize size:CGFloat) -> UIFont {
        return withWeight(fromDescriptor: UIFontDescriptor(fontAttributes:fontFamilyDesc), weight: .bold,size: size)
    }
    
    static private func withWeight(fromDescriptor:UIFontDescriptor, weight: UIFont.Weight, size:CGFloat) -> UIFont {
        var attributes = fromDescriptor.fontAttributes
        var traits = (attributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]
        traits[.weight] = weight
        attributes[.traits] = traits
        let descriptor = UIFontDescriptor(fontAttributes: attributes)
        return UIFont(descriptor: descriptor, size: size)
    }
}

extension UIColor {
    static func buttonBlueNormal() -> UIColor {
        return UIColor.init(red: 7/255.0, green: 193/255.0, blue: 228/255.0, alpha: 1.0)
    }
    
    static func buttonBlueHightlight() -> UIColor {
        return UIColor.init(red: 6/255.0, green: 177/255.0, blue: 210/255.0, alpha: 1.0)
    }
    static func labelGreyColor() -> UIColor {
        return UIColor.init(red: 106/255.0, green: 107/255.0, blue: 108/255.0, alpha: 1.0)
    }
    static func labelGreyHightLightColor() -> UIColor {
        return UIColor.init(red: 106/255.0, green: 107/255.0, blue: 108/255.0, alpha: 0.2)
    }
    static func titleGreyColor() -> UIColor {
        return UIColor.init(fromRGB: 0x444444,withAlpha:1.0)
    }
    static func titleGreyLightColor() -> UIColor {
        return UIColor.init(fromRGB: 0x444444,withAlpha:0.5)
    }
    
    static func buttonGreenNormal() ->UIColor {
        return UIColor.init(fromRGB: 0x30D557,withAlpha:1.0)
    }
    static func buttonGreenHightlight() ->UIColor {
        return UIColor.init(fromRGB: 0x30D557,withAlpha:0.5)
    }
    
    static func baseRedNormal() ->UIColor {
        return UIColor.init(fromRGB: 0xFF513D,withAlpha:1.0)
    }
    static func baseRedHighlight() ->UIColor {
        return UIColor.init(fromRGB: 0xEB4A38,withAlpha:1.0)
    }
    
    
    public convenience init(fromRGB rgbValue: UInt32, withAlpha alpha: CGFloat = 1) {
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255
        let b = CGFloat((rgbValue & 0x0000FF)) / 255
        
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
}

extension UIImage {
   static func imageWithColor(_ color:UIColor ,background:UIColor?) -> UIImage? {
        let scaledUnti: CGFloat = 1.0/UIScreen.main.scale
        let rect: CGRect = CGRect.init(x: 0, y: 0, width: scaledUnti, height: scaledUnti)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        if let backgroundColor = background {
            backgroundColor.setFill()
            UIRectFillUsingBlendMode(rect, .normal)
        }
        color.setFill()
        UIRectFillUsingBlendMode(rect, .normal)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.resizableImage(withCapInsets: .zero)
    }
}

