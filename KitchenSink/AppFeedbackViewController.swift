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
import MessageUI
class AppFeedbackViewController: BaseViewController, MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate,UITextViewDelegate,UINavigationControllerDelegate {

    // MARK: - UI outlets variables
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var userCommentsText: UITextView!
    @IBOutlet weak var mailAddressLabel: UILabel!
    @IBOutlet weak var snapshotLabel: UILabel!
    @IBOutlet var labelFontScaleCollection: [UILabel]!
    @IBOutlet var heightScaleCollection: [NSLayoutConstraint]!
    @IBOutlet var widthScaleCollection: [NSLayoutConstraint]!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var snapshotAngleImage: UIImageView!
    @IBOutlet weak var topicAngleImage: UIImageView!
    @IBOutlet weak var topicButton: UIButton!
    @IBOutlet weak var snapshotButton: UIButton!
    let mailAddress = "devsupport@ciscospark.com"
    var imagePicker = UIImagePickerController()
    var snapshotImage: UIImage!
    let snapshotFileName = "snapshot.png"
    override var navigationTitle: String? {
        get {
            return "Send feedback"
        }
        set(newValue) {
            title = newValue
        }
    }
    
    // MARK: - Life Circle
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(dissmissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    // MARK: - UI Impelemetation
    override func initView() {
        for label in labelFontScaleCollection {
            label.font = UIFont.labelLightFont(ofSize: label.font.pointSize * Utils.HEIGHT_SCALE)
        }
        for heightConstraint in heightScaleCollection {
            heightConstraint.constant *= Utils.HEIGHT_SCALE
        }
        for widthConstraint in widthScaleCollection {
            widthConstraint.constant *= Utils.WIDTH_SCALE
        }
        //textview
        userCommentsText.font = UIFont.labelLightFont(ofSize: (userCommentsText.font?.pointSize)! * Utils.HEIGHT_SCALE)
        userCommentsText.delegate = self
        //button
        topicButton.setBackgroundImage(UIImage.imageWithColor(UIColor.labelGreyHightLightColor(), background: nil), for: .highlighted)
        snapshotButton.setBackgroundImage(UIImage.imageWithColor(UIColor.labelGreyHightLightColor(), background: nil), for: .highlighted)
        //image
        let angleImage = UIImage.fontAwesomeIcon(name: .angleRight, textColor: UIColor.labelGreyColor(), size: CGSize.init(width: 44 * Utils.WIDTH_SCALE , height: 44))
        snapshotAngleImage.image = angleImage
        topicAngleImage.image = angleImage
        //navigation bar init
        let nextButton = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 44, height: 44))
        
        let nextImage = UIImage.fontAwesomeIcon(name: .send, textColor: UIColor.buttonGreenNormal(), size: CGSize.init(width: 32 * Utils.WIDTH_SCALE , height: 44))
        let nextLightImage = UIImage.fontAwesomeIcon(name: .send, textColor: UIColor.buttonGreenHightlight(), size: CGSize.init(width: 32 * Utils.WIDTH_SCALE, height: 44))
        nextButton.setImage(nextImage, for: .normal)
        nextButton.setImage(nextLightImage, for: .highlighted)
        nextButton.addTarget(self, action: #selector(sendMail), for: .touchUpInside)
        
        
        let rightView = UIView.init(frame:CGRect.init(x: 0, y: 0, width: 44, height: 44))
        rightView.addSubview(nextButton)
        let rightButtonItem = UIBarButtonItem.init(customView: rightView)
        
        
        let fixBarSpacer = UIBarButtonItem.init(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixBarSpacer.width = -10 * (2 - Utils.WIDTH_SCALE)
        navigationItem.rightBarButtonItems = [fixBarSpacer,rightButtonItem]
        
        //data 
        topicLabel.text = "UI"
        snapshotLabel.text = " "
        mailAddressLabel.text = mailAddress
    }
    
    
    @objc func sendMail() {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            present(mailComposeViewController, animated: true, completion: nil)
        } else {
            showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients([mailAddress])
        mailComposerVC.setSubject("[\(topicLabel.text!)] Feedback on Kitchen Sink")
        mailComposerVC.setMessageBody(userCommentsText.text, isHTML: false)
        
        if (snapshotImage != nil) {
            let myData: Data = UIImagePNGRepresentation(snapshotImage)!
            mailComposerVC.addAttachmentData(myData, mimeType: "image/png", fileName: snapshotFileName)
        }
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        sendMailErrorAlert.addAction(okAction)
        present(sendMailErrorAlert, animated: true)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!) {
        self.dismiss(animated: true, completion: { () -> Void in
            self.snapshotImage = image
            self.snapshotLabel.text = self.snapshotFileName
        })
    }

    @IBAction func topicButtonTouchUpInside(_ sender: Any) {
        showActionSheet()
    }
    @IBAction func snapshotButtonTouchUpInside(_ sender: Any) {
        attachSnapshot()
    }
    
    func showActionSheet() {
        let optionMenu = UIAlertController(title: nil, message: "Choose Topic", preferredStyle: .actionSheet)
        
        let uiAction = UIAlertAction(title: "UI", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.topicLabel.text = "UI"
        })
        
        let sdkAction = UIAlertAction(title: "SDK", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.topicLabel.text = "SDK"
        })
        
        let devicesAction = UIAlertAction(title: "Supported devices", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.topicLabel.text = "Supported devices"
        })
        
        let featureAction = UIAlertAction(title: "Feature request", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.topicLabel.text = "Feature request"
        })
        
        optionMenu.addAction(uiAction)
        optionMenu.addAction(sdkAction)
        optionMenu.addAction(devicesAction)
        optionMenu.addAction(featureAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    func attachSnapshot() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
            imagePicker.allowsEditing = false
            
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if !textView.text.isEmpty {
            placeholderLabel.isHidden = true
        }
        else {
            placeholderLabel.isHidden = false
        }
    }

}
