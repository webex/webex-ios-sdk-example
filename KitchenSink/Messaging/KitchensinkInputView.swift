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
import FontAwesome_swift
import PhotosUI
import WebexSDK

let kScreenSize = UIScreen.main.bounds
let kScreenWidth = kScreenSize.width
let kScreenHeight = kScreenSize.height
let iPhoneX = (kScreenWidth == 375 && kScreenHeight == 812)
let kNavHeight : CGFloat = iPhoneX ? 88.0 : 64.0

class KitchensinkInputView: UIView, UIImagePickerControllerDelegate , UINavigationControllerDelegate{
    
    public var sendBtnClickBlock : ((_ text : String?, _ membership: Membership?, _ imageInfo: [String: Any]?)->())?
    
    private static var myContext = 0
    private var backVC: SpaceDetailViewController
    public var textView: UITextView?
    private var sendBtn: UIButton?
    private var backViewTap: UIGestureRecognizer?
    private var plusBtn: UIButton?
    private var attachmentBackView : UIView?
    private let textViewX = 50
    private let textViewY = 2
    private let textViewWidth = Int(kScreenWidth - 140)
    private let textViewHeight = 36
    private var imageBtn : UIButton?
    private var mentionBtn: UIButton?
    private let galleryPicker = UIImagePickerController()
    private var selectedImageDict : [String : Any]?
    private var selectedMembership : Membership?
    private var control: UIControl?
    
    init(frame: CGRect , backVC: SpaceDetailViewController){
        self.backVC = backVC
        super.init(frame: frame)
        self.control = UIControl(frame: backVC.view.bounds)
        self.control?.addTarget(self, action: #selector(backViewTapped), for: .touchUpInside)
        self.setUpSubViews()
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillAppear(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillDisappear(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc private func plusBtnClicked(){
        let inputViewHeight = kScreenWidth > 375 ? 226 : 216
        if self.attachmentBackView == nil{
            self.attachmentBackView = UIView(frame: CGRect(x: 0, y: 0, width: Int(kScreenWidth), height: inputViewHeight))
            self.imageBtn = UIButton(frame: CGRect(x: 5, y: 5, width: Int(inputViewHeight/2)-10, height: Int(inputViewHeight/2)-10))
            self.imageBtn?.setTitle("Images", for: .normal)
            self.imageBtn?.backgroundColor = UIColor.buttonBlueNormal()
            self.imageBtn?.addTarget(self, action: #selector(addImageButtnClicked), for: .touchUpInside)
            self.attachmentBackView?.addSubview(self.imageBtn!)
            
            if let _ = self.backVC.spaceModel?.id{
                self.mentionBtn = UIButton(frame: CGRect(x: Int(inputViewHeight/2)+5, y: 5, width: Int(inputViewHeight/2)-10, height: Int(inputViewHeight/2)-10))
                self.mentionBtn?.setTitle("Mentions", for: .normal)
                self.mentionBtn?.backgroundColor = UIColor.buttonBlueNormal()
                self.mentionBtn?.addTarget(self, action: #selector(addMentionButtonClicked), for: .touchUpInside)
                self.attachmentBackView?.addSubview(self.mentionBtn!)
            }

        }
      
        self.textView?.inputView = self.attachmentBackView
        self.textView?.reloadInputViews()
        self.textView?.tintColor = UIColor.clear
        let control = UIControl(frame: (self.textView?.bounds)!)
        control.addTarget(self, action: #selector(textViewClicked), for: .touchUpInside)
        self.textView?.addSubview(control)
        self.textView?.becomeFirstResponder()
    }
    
    @objc private func textViewClicked(){
        self.textView?.inputView = nil
        self.textView?.tintColor = UIColor.buttonBlueNormal()
        self.textView?.becomeFirstResponder()
        self.textView?.reloadInputViews()
    }
    
    // MARK: - UI Implementation
    func setUpSubViews(){
        let bottomViewWidth = kScreenWidth
        self.backgroundColor = UIColor.init(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1)
        
        self.plusBtn = UIButton(frame: CGRect(x: 14, y: 7, width: 26, height: 26))
        self.plusBtn?.setImage(UIImage.fontAwesomeIcon(name: .plus, textColor: UIColor.white, size: CGSize(width: 26, height: 26)), for: .normal)
        self.plusBtn?.addTarget(self, action: #selector(plusBtnClicked), for: .touchUpInside)
        self.plusBtn?.backgroundColor = UIColor.buttonBlueNormal()
        self.plusBtn?.layer.cornerRadius = 13.0
        self.plusBtn?.layer.masksToBounds = true
        self.addSubview(self.plusBtn!)
        
        self.textView = UITextView(frame: CGRect(x: textViewX, y: textViewY, width: textViewWidth, height: textViewHeight))
        self.textView?.textAlignment = .center
        self.textView?.tintColor = UIColor.buttonBlueNormal()
        self.textView?.layer.borderColor = UIColor.clear.cgColor
        self.textView?.font = UIFont.buttonLightFont(ofSize: 15)
        self.textView?.textAlignment = .left
        self.textView?.returnKeyType = .default;
        self.textView?.layer.cornerRadius = 5.0
        self.textView?.layer.borderColor = UIColor.buttonBlueNormal().cgColor
        self.textView?.layer.borderWidth = 1.0
        self.textView?.layoutManager.allowsNonContiguousLayout = false
        self.textView?.addObserver(self, forKeyPath:"contentSize" , options: [NSKeyValueObservingOptions.old , NSKeyValueObservingOptions.new], context: &KitchensinkInputView.myContext)
        self.addSubview(self.textView!)
        
        self.sendBtn = UIButton(frame: CGRect(x: bottomViewWidth-80, y: 5, width: 70, height: 30))
        self.sendBtn?.setTitle("Send", for: .normal)
        self.sendBtn?.backgroundColor = UIColor.buttonBlueNormal()
        self.sendBtn?.titleLabel?.font = UIFont.fontAwesome(ofSize: 15)
        self.sendBtn?.layer.cornerRadius = 15
        self.sendBtn?.layer.masksToBounds = true
        self.sendBtn?.addTarget(self, action: #selector(sendBtnClicked), for: .touchUpInside)
        self.addSubview(self.sendBtn!)
    }
    
    
    // MARK: UI Logic Implementation
    @objc func keyBoardWillAppear(notification: Notification){
        let userInfo = notification.userInfo!
        let keyboardFrame:NSValue = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        self.backVC.view.addSubview(self.control!)
        self.backVC.view.bringSubview(toFront: self)
        UIView.animate(withDuration: 0.25) {
            self.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
        }
    }
    
    @objc func keyBoardWillDisappear(notification: Notification){
        self.control?.removeFromSuperview()
        UIView.animate(withDuration: 0.25) {
            self.transform = CGAffineTransform(translationX: 0, y: 0)
        }

    }

    // MARK: - UITextView/Delegate Observer Implemenation
    @objc override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &KitchensinkInputView.myContext{
            if let newValue = change?[.newKey] as? CGSize, let oldValue = change?[.oldKey] as? CGSize, newValue != oldValue {
                var contentHeight = newValue.height
                let textViewWidth = self.textViewWidth
                if(contentHeight < 36){
                    contentHeight = 36
                }else if(contentHeight >= 120){
                    contentHeight = 120
                }
                let gap = contentHeight - self.frame.size.height + 4
                if(newValue.height >= oldValue.height){
                    self.textView?.frame = CGRect(x: textViewX, y: textViewY, width: textViewWidth, height: Int(contentHeight))
                    self.frame.size.height = contentHeight+4
                    UIView.animate(withDuration: 0.15, animations: {
                        self.updateTableViewInset(-gap)
                    })
                 
                }else{
                    self.textView?.frame = CGRect(x: textViewX, y: textViewY, width: textViewWidth, height: Int(contentHeight))
                    UIView.animate(withDuration: 0.15, animations: {
                        self.frame.size.height = contentHeight+4
                        self.updateTableViewInset(-gap)
                    })

                }
            }
        }
    }
    
    func updateTableViewInset(_ height: CGFloat){
        self.frame.origin.y += (height)
        self.sendBtn?.frame.origin.y -= (height)
        self.plusBtn?.frame.origin.y -= (height)
    }
    
    // MARK: - UITextView/Delegate Observer Implemenation
    @objc private func backViewTapped(){
        self.textView?.resignFirstResponder()
    }
    
    // MARK: - Mention List Delegate
    @objc private func addMentionButtonClicked(){
        let mentionListVC = MentionPeopleListViewController()
        mentionListVC.webexSDK = self.backVC.webexSDK
        mentionListVC.spaceId = self.backVC.spaceModel?.id
        let navVC = UINavigationController(rootViewController: mentionListVC)
        mentionListVC.completionBlock = { (membership) in
            navVC.dismiss(animated: true, completion: {})
            self.membershipSelected(membership)
        }
        self.backVC.present(navVC, animated: true)
    }
    
    func membershipSelected(_ membership: Membership?){
        self.textView?.becomeFirstResponder()
        if let membership = membership{
            self.selectedMembership = membership
            self.mentionBtn?.setTitle(membership.personDisplayName, for: .normal)
        }
    }
    
    // MARK: - Image Picker delegate
    @objc private func addImageButtnClicked(){
        
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
            
            switch photoAuthorizationStatus {
                
            case .authorized: print("Access is granted by user")
                self.galleryPicker.sourceType = .photoLibrary
                self.galleryPicker.delegate = self
                self.backVC.present(galleryPicker, animated: true)
                break
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization({ (newStatus) in
                    print("status is \(newStatus)")
                    if newStatus == PHAuthorizationStatus.authorized{
                        print("success")
                        self.galleryPicker.sourceType = .photoLibrary
                        self.galleryPicker.delegate = self
                        self.backVC.present(self.galleryPicker, animated: true)
                    }
                })
                break
            case .restricted:
                break
            case .denied:
                break
        }

    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {}
        self.textView?.becomeFirstResponder()
    }
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true) {}
        self.textView?.becomeFirstResponder()
        self.selectedImageDict = info
        self.updateSlectedImage()
    }
    
    private func updateSlectedImage(){
        if let imageDict = self.selectedImageDict{
            let selectedImage = imageDict["UIImagePickerControllerOriginalImage"] as! UIImage
            self.imageBtn?.setImage(selectedImage, for: .normal)
        }
    }
    
    // MARK: Kitchensink InputView Delegate Part
    @objc private func sendBtnClicked(){
        if(self.sendBtnClickBlock != nil){
            self.sendBtnClickBlock!((self.textView?.text)!, self.selectedMembership, self.selectedImageDict)
            self.textView?.text = ""
            self.selectedImageDict = nil
            self.selectedMembership = nil
            self.imageBtn?.setTitle("Images", for: .normal)
            self.imageBtn?.setImage(nil, for: .normal)
            self.mentionBtn?.setTitle("Mentions", for: .normal)
        }
    }
    
    
    deinit{
        self.textView?.removeObserver(self, forKeyPath: "contentSize")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
