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

import UIKit
import WebexSDK

class PersonTableViewCell: UITableViewCell {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dialButton: UIButton!
    
    @IBOutlet weak var avatarImageHeight: NSLayoutConstraint!
    @IBOutlet var heightScaleCollection: [NSLayoutConstraint]!
    
    @IBOutlet var labelFontScaleCollection: [UILabel]!
    
    @IBOutlet var widthScaleCollection: [NSLayoutConstraint]!
    
    var address: String?
    var initiateCallViewController: InitiateCallViewController!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let selector = #selector(PersonTableViewCell.dial)
        dialButton.addTarget(self, action: selector, for: UIControl.Event.touchUpInside)
        
        
        for label in labelFontScaleCollection {
            label.font = UIFont.labelLightFont(ofSize: label.font.pointSize * Utils.HEIGHT_SCALE)
        }
        for heightConstraint in heightScaleCollection {
            heightConstraint.constant *= Utils.HEIGHT_SCALE
        }
        for widthConstraint in widthScaleCollection {
            widthConstraint.constant *= Utils.WIDTH_SCALE
        }
        
        avatarImageView.layer.cornerRadius = avatarImageHeight.constant/2
    }
    
    @objc func dial(_ sender: UIButton) {
        initiateCallViewController.dialWithEmailAddress(address!)
    }
}
