//
//  ActivityDetailViewController.swift
//  KitchenSink
//
//  Created by qucui on 2018/1/18.
//  Copyright 2016-2019 Cisco Systems Inc. All rights reserved.
//

import UIKit
import WebexSDK
import WebKit

class SpaceDetailViewController: BaseViewController, UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    
    var spaceModel: Space?
    var spaceId: String?
    var emailAddress: String?
    private var contentTextView: UITextView?
    private var fileContentsView: UIScrollView?
    private var textInputView: KitchensinkInputView?
    private var receivedFiles: [RemoteFile]? = [RemoteFile]()
    private var currentMessage: Message?
    private var isMessageEditing: Bool = false
    private var editButton: UIButton?
    
    /// saparkSDK reperesent for the WebexSDK API instance
    var webexSDK: Webex?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
        self.registerMessageCallBack()
    }
    
    // MARK: - WebexSDK: register Message receive CallBack
    private func registerMessageCallBack(){
        self.webexSDK?.messages.onEvent = { event in
            switch event {
            case .messageReceived(let message):
                // callback all messages, if you just want to receive current space's messages, filter to use message.spaceId
                self.currentMessage = message
                self.updateMessageAcitivty(message)
                break
            case .messageDeleted(_):
                // callback the id of message deleted
                break
            case .messageUpdated(let messageId, let type):
                switch type {
                case .fileThumbnail(let files):
                    if self.currentMessage?.id == messageId {
                        self.updateMessageAcitivty(self.currentMessage, files: files)
                    }
                case .message:
                    if self.currentMessage?.id == messageId {
                        self.currentMessage?.update(type)
                        self.updateMessageAcitivty(self.currentMessage, files: nil)
                    }
                }
                break
            }
        }
    }
    
    // MARK: - WebexSDK: Send Message
    public func sendMessage(_ textStr: String?,_ memberShip : Membership? ,_ image: [String: Any]?){
        self.title = "Sending.."
        var finalStr : String?
        var files : [LocalFile]?
        var mentions : [Mention]? = [Mention]()
        if let text = textStr{
            finalStr = text
        }else{
            finalStr = ""
        }
        if let imageDict = image{
            do{
                let selectedImage = imageDict["UIImagePickerControllerOriginalImage"] as! UIImage
                let imageData = selectedImage.jpegData(compressionQuality: 1.0)
                let docDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let imageURL = docDir.appendingPathComponent("tempImage.jpeg")
                if let url = URL.init(string:imageURL.path) {
                    try imageData?.write(to: imageURL)
                    let thumbnail = LocalFile.Thumbnail.init(path: url.path, width: 320, height: 480)
                    let fileModel = LocalFile.init(path: url.path, name: "tempImage.jpeg",thumbnail:thumbnail) {
                        progress in
                        DispatchQueue.main.async {
                            let progressStr = "Sending.. Uploaded: \(progress*100)"+"%"
                            self.title = progressStr
                        }
                    }
                    files = [LocalFile]()
                    if let file = fileModel {
                        files?.append(file)
                    }
                }
            }catch{
                print("image convert failed")
                return
            }
        }
        if let membership = memberShip , let memberShipId = memberShip?.id{
            mentions?.append(Mention.person(memberShipId))
            finalStr = "\(finalStr!)\(membership.personDisplayName!)"
        }
        
        self.setUpFileContentsView(files: [])
        var text:Message.Text?
        if let str = finalStr {
            text = Message.Text.html(html: str)
        }
        
        if isMessageEditing {
            guard let message = currentMessage else {
                Utils.showAlert(self, title: "", message: "No message to edit")
                return
            }
            if message.files != nil || files != nil {
                Utils.showAlert(self, title: "", message: "Only support editing message without attachment")
                return
            }
            guard let text = text else {
                return
            }
            self.webexSDK?.messages.edit(text, parent: message, mentions: mentions, completionHandler: {[weak self] (response) in
                switch response.result{
                case .success(let message):
                    self?.title = "Edit Sucess!"
                    self?.currentMessage = message
                    self?.updateMessageAcitivty(message)
                    self?.endEditingMessage()
                case .failure(let error):
                    DispatchQueue.main.async {
                        print(error)
                        self?.title = "Edit Fail!"
                    }
                }
            })
            return
        }
        
        if let space = self.spaceModel{
            self.webexSDK?.messages.post(text, toSpace: space.id!, mentions: mentions, withFiles: files, completionHandler: { (response) in
                switch response.result{
                case .success(let message):
                    /// Send Message Call Back Code Here
                    self.title = "Sent Sucess!"
                    self.spaceId = message.spaceId
                    self.currentMessage = message
                    self.updateMessageAcitivty(message)
                    break
                case .failure(let error):
                    DispatchQueue.main.async {
                        print(error)
                        self.title = "Sent Fail!"
                    }
                    break
                }
            })
        }
        else if let email = self.emailAddress,let emailAddress = EmailAddress.fromString(email){
            self.webexSDK?.messages.post(text, toPersonEmail: emailAddress, withFiles: files, completionHandler: { (response) in
                switch response.result{
                case .success(let message):
                    /// Send Message Call Back Code Here
                    self.title = "Sent Sucess!"
                    self.spaceId = message.spaceId
                    self.currentMessage = message
                    self.updateMessageAcitivty(message)
                    break
                case .failure(let error):
                    DispatchQueue.main.async {
                        print(error)
                        self.title = "Sent Fail!"
                    }
                    break
                }
            })
            
        }
    }
    
    // MARK: - WebexSDK: Download File
    public func downLoadFile(file: RemoteFile, onView: UIView){
        let progressTag = 256
        let progressLabel:UILabel
        if let existLabel:UILabel = onView.viewWithTag(progressTag) as? UILabel {
            progressLabel = existLabel
        } else {
            progressLabel = UILabel(frame: CGRect(x: 0, y: 0, width: onView.frame.size.width, height: 30))
        }
        
        
        progressLabel.textAlignment = .center
        progressLabel.textColor = UIColor.black
        progressLabel.tag = progressTag
        onView.addSubview(progressLabel)
        
        self.webexSDK?.messages.downloadFile(file,progressHandler:{
            progress in
            progressLabel.text = "\(String.init(format: "%.2f", progress * 100) )%"
            print("=====received progress:\(String.init(format: "%.2f", progress * 100))")
        }) {
            result in
            switch result {
            case .success(let url):
                progressLabel.text = "100%"
                let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight))
                webView.load(URLRequest(url: url))
                let webVC = UIViewController()
                webVC.view = webView
                self.navigationController?.pushViewController(webVC, animated: true)
                break
            default:
                break
            }
        }
        
    }
    
    public func downLoadThumbnail(_ file: RemoteFile, onView: UIView){
        let progressLabel = UILabel(frame: CGRect(x: 0, y: 0, width: onView.frame.size.width, height: onView.frame.size.height))
        progressLabel.textAlignment = .center
        progressLabel.textColor = UIColor.black
        onView.addSubview(progressLabel)
        
        self.webexSDK?.messages.downloadThumbnail(for: file) { result in
            switch result {
            case .success(let url):
                progressLabel.removeFromSuperview()
                let image = UIImage(contentsOfFile: url.path)
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: onView.frame.size.width, height: onView.frame.size.height))
                imageView.image = image
                imageView.backgroundColor = UIColor.red
                onView.addSubview(imageView)
            default:
                break
            }
        }
    }
    
    // MARK: - UI Implementation
    public func setupView(){
        editButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 44))
        editButton!.setTitle("Edit", for: .normal)
        editButton!.setTitle("Editing", for: .selected)
        editButton!.setTitleColor(.black, for: .normal)
        editButton!.addTarget(self, action: #selector(editMessage(_:)), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: editButton!)
        
        self.view.backgroundColor = UIColor.white
        if let space = self.spaceModel{
            self.title = space.title
            self.spaceId = space.id
        }else if let email = self.emailAddress{
            self.title = email
        }else{
            self.title = ""
        }
        
        let titleLabel = UILabel(frame: CGRect(x: 10, y: 10, width: kScreenWidth-10, height: 20))
        titleLabel.text = "Message Payloads:"
        self.view.addSubview(titleLabel)
        
        self.contentTextView = UITextView(frame: CGRect(x: 10, y: 30, width: kScreenWidth-20, height: 320))
        self.contentTextView?.backgroundColor =  UIColor.init(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)
        self.contentTextView?.font = UIFont.systemFont(ofSize: 15)
        self.contentTextView?.isUserInteractionEnabled = true
        self.contentTextView?.isScrollEnabled = true
        self.view.addSubview(self.contentTextView!)
        
        let fileTitleLable = UILabel(frame: CGRect(x: 10, y: 350, width: kScreenWidth-10, height: 20))
        fileTitleLable.text = "Files:"
        self.view.addSubview(fileTitleLable)
        
        self.fileContentsView = UIScrollView(frame: CGRect(x: 10, y: 370, width: kScreenWidth-20, height: 100))
        self.fileContentsView?.backgroundColor = UIColor.init(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)
        self.view.addSubview(self.fileContentsView!)
        
        self.textInputView = KitchensinkInputView(frame: CGRect(x:0,y:kScreenHeight-kNavHeight-40,width: kScreenWidth, height: 40), backVC: self)
        self.textInputView?.sendBtnClickBlock = { (textStr: String?, mention : Membership? , image: [String: Any]?) in
            self.textInputView?.textView?.text = ""
            self.sendMessage(textStr, mention, image)
        }
        self.view.addSubview(self.textInputView!)
    }
    
    public func updateMessageAcitivty(_ message: Message?, files: [RemoteFile]? = nil){
        guard message != nil else {
            return
        }
        if let msg = message {
            self.contentTextView?.text = "\(msg))"
        }
        if let files = files ?? message?.files {
            self.setUpFileContentsView(files: files)
        }
        
    }
    
    public func setUpFileContentsView(files: [RemoteFile]){
        
        self.fileContentsView?.removeFromSuperview()
        self.fileContentsView = UIScrollView(frame: CGRect(x: 10, y: 370, width: kScreenWidth-20, height: 120))
        self.fileContentsView?.backgroundColor = UIColor.init(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)
        
        self.view.addSubview(self.fileContentsView!)
        self.view.bringSubviewToFront(self.textInputView!)
        
        self.receivedFiles?.removeAll()
        self.receivedFiles = files
        self.fileContentsView?.contentSize = CGSize(width: 100*(self.receivedFiles?.count)!, height: 120)
        for index in 0..<files.count{
            let file = files[index]
            let tempView = UIView(frame: CGRect(x: 100*index, y: 10, width: 100, height: 100))
            tempView.tag = 10000+index
            tempView.backgroundColor = UIColor.lightGray
            self.fileContentsView?.addSubview(tempView)
            if(file.thumbnail != nil){
                self.downLoadThumbnail(file, onView: tempView)
            }else{
                let titleLabel = UILabel(frame: CGRect(x: 10, y: 10, width: tempView.frame.size.width-20, height: tempView.frame.size.height-20))
                titleLabel.text = file.displayName!
                titleLabel.numberOfLines = 0
                titleLabel.backgroundColor = UIColor.lightGray
                titleLabel.textAlignment = .center
                tempView.addSubview(titleLabel)
            }
            let tap = UITapGestureRecognizer(target: self, action: #selector(fileDownLoadClicked(_ :)))
            tempView.addGestureRecognizer(tap)
        }
    }
    @objc private func fileDownLoadClicked(_ recognizer: UITapGestureRecognizer){
        let index = (recognizer.view?.tag)! - 10000
        let file = self.receivedFiles![index]
        self.downLoadFile(file: file, onView: recognizer.view!)
        
    }
    
    @objc func editMessage(_ button: UIButton) {
        button.isSelected.toggle()
        isMessageEditing = button.isSelected
        if isMessageEditing {
            textInputView?.textView?.becomeFirstResponder()
        }
    }
    
    func endEditingMessage() {
        isMessageEditing = false
        editButton?.isSelected = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
