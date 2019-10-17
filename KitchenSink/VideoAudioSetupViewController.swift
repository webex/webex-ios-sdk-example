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

class VideoAudioSetupViewController: BaseViewController {
    
    // MARK: - UI outlets variables
    @IBOutlet weak var audioView: UIView!
    @IBOutlet weak var audioImage: UIImageView!
    @IBOutlet weak var audioVideoView: UIView!
    @IBOutlet weak var audioVideoImage: UIImageView!
    @IBOutlet weak var loudSpeakerSwitch: UISwitch!
    @IBOutlet weak var cameraSetupView: UIView!
    @IBOutlet weak var videoSetupView: UIView!
    @IBOutlet weak var frontCameraView: UIView!
    @IBOutlet weak var backCameraView: UIView!
    @IBOutlet weak var frontImage: UIImageView!
    @IBOutlet weak var backImage: UIImageView!
    @IBOutlet weak var loudSpeakerLabel: UILabel!
    @IBOutlet weak var bandwidthTitleLabel: UILabel!
    @IBOutlet weak var bandWidthLabel: UILabel!
    @IBOutlet weak var bandwidthImg: UIImageView!
    @IBOutlet weak var selfViewHiddenHelpLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var selfViewHiddenHelpLabel: KSLabel!
    @IBOutlet weak var videoSetupBackoundViewTop: NSLayoutConstraint!
    @IBOutlet weak var videoSetupBackoundView: UIView!
    @IBOutlet var videoSetupBackroundViewBottom: NSLayoutConstraint!
    @IBOutlet weak var selfViewCloseView: UIView!
    @IBOutlet weak var selfViewCloseImage: UIImageView!
    @IBOutlet weak var videoViewHiddenHelpLabel: KSLabel!
    @IBOutlet weak var videoViewhiddenHelpLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var selfViewSetupHeight: NSLayoutConstraint!
    @IBOutlet weak var videoViewHeight: NSLayoutConstraint!
    @IBOutlet var labelFontCollection: [UILabel]!
    @IBOutlet var widthScaleConstraintCollection: [NSLayoutConstraint]!
    @IBOutlet var heightScaleConstraintCollection: [NSLayoutConstraint]!
    @IBOutlet weak var preview: MediaRenderView!
    @IBOutlet weak var bandwidthBackView: UIView!
    private let uncheckImage = UIImage.fontAwesomeIcon(name: .square, type: .regular, textColor: UIColor.titleGreyColor(), size: CGSize.init(width: 33 * Utils.HEIGHT_SCALE, height: 33 * Utils.HEIGHT_SCALE))
    private let arrowImage = UIImage.fontAwesomeIcon(name: .angleRight, textColor: UIColor.titleGreyColor(), size: CGSize.init(width: 33 * Utils.HEIGHT_SCALE, height: 33 * Utils.HEIGHT_SCALE))
    private let checkImage = UIImage.fontAwesomeIcon(name: .checkSquare, type: .regular, textColor: UIColor.titleGreyColor(), size: CGSize.init(width: 33 * Utils.HEIGHT_SCALE, height: 33 * Utils.HEIGHT_SCALE))
    private let selfViewSetupHeightContant = 320 * Utils.HEIGHT_SCALE
    private let selfViewSetupHelpLabelHeightContant = 54 * Utils.HEIGHT_SCALE
    private let videoViewSetupHeightContant = 420 * Utils.HEIGHT_SCALE
    private let videoViewSetupHelpLabelHeightContant = 54 * Utils.HEIGHT_SCALE
    override var navigationTitle: String? {
        get {
            return "Video/Audio setup"
        }
        set(newValue) {
            title = newValue
        }
    }
    
    /// saparkSDK reperesent for the WebexSDK API instance
    var webexSDK: Webex?
    
    // MARK: - Life cycle
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //note:make sure stopPreview before calling
        webexSDK?.phone.stopPreview()
    }
    
    // MARK: - UI Implemetation
    override func initView() {
        for label in labelFontCollection {
            label.font = UIFont.labelLightFont(ofSize: label.font.pointSize * Utils.HEIGHT_SCALE)
        }
        
        for heightConstraint in heightScaleConstraintCollection {
            heightConstraint.constant *= Utils.HEIGHT_SCALE
        }
        for widthConstraint in widthScaleConstraintCollection {
            widthConstraint.constant *= Utils.WIDTH_SCALE
        }
        
        
        //navigation bar init
        let nextButton = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 44, height: 44))
        
        let nextImage = UIImage.fontAwesomeIcon(name: .phone, textColor: UIColor.buttonGreenNormal(), size: CGSize.init(width: 32 * Utils.WIDTH_SCALE , height: 44))
        let nextLightImage = UIImage.fontAwesomeIcon(name: .phone, textColor: UIColor.buttonGreenHightlight(), size: CGSize.init(width: 32 * Utils.WIDTH_SCALE, height: 44))
        nextButton.setImage(nextImage, for: .normal)
        nextButton.setImage(nextLightImage, for: .highlighted)
        nextButton.addTarget(self, action: #selector(gotoInitiateCallView), for: .touchUpInside)
        
        
        let rightView = UIView.init(frame:CGRect.init(x: 0, y: 0, width: 44, height: 44))
        rightView.addSubview(nextButton)
        let rightButtonItem = UIBarButtonItem.init(customView: rightView)
        
        
        let fixBarSpacer = UIBarButtonItem.init(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixBarSpacer.width = -10 * (2 - Utils.WIDTH_SCALE)
        navigationItem.rightBarButtonItems = [fixBarSpacer,rightButtonItem]
        
        //checkbox init
        var tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(handleCapGestureEvent(sender:)))
        audioView.addGestureRecognizer(tapGesture)
        
        tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(handleCapGestureEvent(sender:)))
        audioVideoView.addGestureRecognizer(tapGesture)
        updateCallCapStatus()
        if(globalVideoSetting.webexSDK == nil){
            globalVideoSetting.webexSDK = self.webexSDK
        }
        videoViewHeight.constant = CGFloat(globalVideoSetting.isVideoEnabled() ? videoViewSetupHeightContant:0)
        videoSetupView.alpha = globalVideoSetting.isVideoEnabled() ? 1:0
        videoViewHiddenHelpLabel.alpha = globalVideoSetting.isVideoEnabled() ? 0:1
        videoViewhiddenHelpLabelHeight.constant = CGFloat(globalVideoSetting.isVideoEnabled() ? 0:videoViewSetupHelpLabelHeightContant)
        view.removeConstraint(videoSetupBackroundViewBottom)
        videoSetupBackroundViewBottom =  NSLayoutConstraint.init(item: videoSetupBackoundView!, attribute: .bottom, relatedBy: .equal, toItem: globalVideoSetting.isVideoEnabled() ? videoSetupView:loudSpeakerLabel, attribute: .bottom, multiplier: 1, constant: globalVideoSetting.isVideoEnabled() ? 0:-(videoSetupBackoundViewTop.constant))
        view.addConstraint(videoSetupBackroundViewBottom)
        
        view.layoutIfNeeded()
        tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(handleCameraGestureEvent(sender:)))
        frontCameraView.addGestureRecognizer(tapGesture)
        tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(handleCameraGestureEvent(sender:)))
        backCameraView.addGestureRecognizer(tapGesture)
        tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(handleCameraGestureEvent(sender:)))
        selfViewCloseView.addGestureRecognizer(tapGesture)
        updateCameraStatus(false)
        updateLoudspeakerStatus()
        
        //bandwidth label
        bandwidthImg.image = arrowImage
        tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(handleCameraBandwidthGestureEvent(sender:)))
        bandwidthBackView.addGestureRecognizer(tapGesture)
        updateBandwidthView()
    }
    // MARK: hand checkbox change
    @IBAction func loudSpeakerSwitchChange(_ sender: Any) {
        let speakerSwitch = sender as! UISwitch
        globalVideoSetting.isLoudSpeaker = speakerSwitch.isOn
    }
    
    @objc func handleCapGestureEvent(sender:UITapGestureRecognizer) {
        if let view = sender.view {
            if view == audioView {
                globalVideoSetting.setVideoEnabled(false)
                updateVideoView(true)
            }
            else if view == audioVideoView {
                globalVideoSetting.setVideoEnabled(true)
                updateVideoView(false)
            }
            
            updateCallCapStatus()
        }
    }
    
    @objc func handleCameraGestureEvent(sender:UITapGestureRecognizer) {
        if let view = sender.view {
            if view == frontCameraView {
                globalVideoSetting.facingMode = .user
                globalVideoSetting.isSelfViewShow = true
            }
            else if view == selfViewCloseView {
                // Ture is sending Video stream to remote,false is not.Default is true
                globalVideoSetting.isSelfViewShow = false
            }
            else {
                globalVideoSetting.facingMode = .environment
                globalVideoSetting.isSelfViewShow = true
            }

            updateCameraStatus()
        }
    }
    
    @objc func handleCameraBandwidthGestureEvent(sender: UITapGestureRecognizer){
        let alertController = UIAlertController(title: "Band Width", message: nil, preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: "177Kbs", style: .default, handler: { (action) -> Void in
            globalVideoSetting.bandWidth = 177000
            self.updateBandwidthView()
        })
        let action2 = UIAlertAction(title: "384Kbps", style: .default, handler: { (action) -> Void in
            globalVideoSetting.bandWidth  = 384000
            self.updateBandwidthView()
        })
        let action3 = UIAlertAction(title: "768Kbs", style: .default, handler: { (action) -> Void in
            globalVideoSetting.bandWidth  = 768000
            self.updateBandwidthView()
        })
        let action4 = UIAlertAction(title: "2Mbps", style: .default, handler: { (action) -> Void in
            globalVideoSetting.bandWidth  = 2000000
            self.updateBandwidthView()
        })
        let action5 = UIAlertAction(title: "3Mbps", style: .default, handler: { (action) -> Void in
            globalVideoSetting.bandWidth  = 3000000
            self.updateBandwidthView()
        })
        let action6 = UIAlertAction(title: "4Mbps", style: .default, handler: { (action) -> Void in
            globalVideoSetting.bandWidth  = 4000000
            self.updateBandwidthView()
        })
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            
        })
        
        alertController.addAction(action1)
        alertController.addAction(action2)
        alertController.addAction(action3)
        alertController.addAction(action4)
        alertController.addAction(action5)
        alertController.addAction(action6)
        alertController.addAction(cancelButton)

        self.navigationController!.present(alertController, animated: true, completion: nil)
    }
    
    func updateBandwidthView(){
        var bandWidthStr : String = ""
        if let bandwidth = webexSDK?.phone.videoMaxBandwidth{
            switch Int(bandwidth) {
            case 177000 :
                bandWidthStr = "177Kbps "
                break
            case 384000 :
                bandWidthStr = "384Kbps "
                break
            case 768000 :
                bandWidthStr = "768Kbps "
                break
            case 2000000 :
                bandWidthStr = "2Mbps "
                break
            case 3000000 :
                bandWidthStr = "3Mbps "
                break
            case 4000000:
                bandWidthStr = "4Mbps "
                break
            default:
                bandWidthStr = "720p "
                break
            }
            bandWidthLabel.text = bandWidthStr
        }else{
            bandWidthLabel.text = ""
        }
    }
    func updateCallCapStatus() {
        if !globalVideoSetting.isVideoEnabled() {
            audioImage.image = checkImage
            audioVideoImage.image = uncheckImage
        } else {
            audioImage.image = uncheckImage
            audioVideoImage.image = checkImage
        }
    }
    
    func updateCameraStatus(_ animation:Bool = true) {
        if animation {
            updateSelfSetupView(!globalVideoSetting.isSelfViewShow)
        }
        else {
            selfViewHiddenHelpLabelHeight.constant = CGFloat(globalVideoSetting.isSelfViewShow ? 0:selfViewSetupHelpLabelHeightContant)
            selfViewHiddenHelpLabel.alpha = globalVideoSetting.isSelfViewShow ? 0:1
            cameraSetupView.alpha = globalVideoSetting.isSelfViewShow ? 1:0
            selfViewSetupHeight.constant = CGFloat(globalVideoSetting.isSelfViewShow ? selfViewSetupHeightContant:0)
        }
        if !globalVideoSetting.isSelfViewShow {
            frontImage.image = uncheckImage
            backImage.image = uncheckImage
            selfViewCloseImage.image = checkImage
            //note:stopPreview stream will not sent to remote side
            webexSDK?.phone.stopPreview()
        }
        else if globalVideoSetting.facingMode == .user {
            frontImage.image = checkImage
            backImage.image = uncheckImage
            selfViewCloseImage.image = uncheckImage
            //note:when change the facing mode ,please stop previous preview stream
            webexSDK?.phone.stopPreview()
            webexSDK?.phone.startPreview(view: self.preview)
        }
        else {
            frontImage.image = uncheckImage
            backImage.image = checkImage
            selfViewCloseImage.image = uncheckImage
            //note:when change the facing mode ,please stop previous preview stream
            webexSDK?.phone.stopPreview()
            webexSDK?.phone.startPreview(view: self.preview)
            
        }
    }
    
    func updateLoudspeakerStatus() {
        loudSpeakerSwitch.isOn = globalVideoSetting.isLoudSpeaker
    }
    
    func updateVideoView(_ isHidden:Bool) {
        var firstView:UIView?
        var firstConstraint:NSLayoutConstraint?
        var firstConstant:CGFloat?
        var secondView:UIView?
        var secondConstraint:NSLayoutConstraint?
        var secondConstant:CGFloat?
        let backoundViewBottom:NSLayoutConstraint?
        if isHidden {
            firstView = videoSetupView
            firstConstraint = videoViewHeight
            firstConstant = 0
            secondView = videoViewHiddenHelpLabel
            secondConstraint = videoViewhiddenHelpLabelHeight
            secondConstant = videoViewSetupHelpLabelHeightContant
            backoundViewBottom = NSLayoutConstraint.init(item: videoSetupBackoundView!, attribute: .bottom, relatedBy: .equal, toItem: loudSpeakerLabel, attribute: .bottom, multiplier: 1, constant: -(videoSetupBackoundViewTop.constant))
        }
        else {
            firstView = videoViewHiddenHelpLabel
            firstConstraint = videoViewhiddenHelpLabelHeight
            firstConstant = 0
            secondView = videoSetupView
            secondConstraint = videoViewHeight
            secondConstant = videoViewSetupHeightContant
            backoundViewBottom = NSLayoutConstraint.init(item: videoSetupBackoundView!, attribute: .bottom, relatedBy: .equal, toItem: videoSetupView, attribute: .bottom, multiplier: 1, constant: 0)
        }
        
        expandedView(withAnim: { [weak self] in
            if let strongSelf = self {
                firstView?.alpha = 0
                firstConstraint?.constant = firstConstant ?? 0
                if isHidden {
                    strongSelf.view.removeConstraint(strongSelf.videoSetupBackroundViewBottom)
                    strongSelf.videoSetupBackroundViewBottom = backoundViewBottom
                    strongSelf.view.addConstraint(strongSelf.videoSetupBackroundViewBottom)
                }
            }
        }){ [weak self] in
            if let strongSelf = self {
                strongSelf.expandedView(withAnim:{
                    secondView?.alpha = 1
                    secondConstraint?.constant = secondConstant ?? 0
                    if !isHidden {
                        strongSelf.view.removeConstraint(strongSelf.videoSetupBackroundViewBottom)
                        strongSelf.videoSetupBackroundViewBottom = backoundViewBottom
                        strongSelf.view.addConstraint(strongSelf.videoSetupBackroundViewBottom)
                    }
                }
                )
            }
        }
        
    }
    
    func updateSelfSetupView(_ isHidden:Bool) {
        var firstView:UIView?
        var firstConstraint:NSLayoutConstraint?
        var firstConstant:CGFloat?
        var secondView:UIView?
        var secondConstraint:NSLayoutConstraint?
        var secondConstant:CGFloat?
        
        if isHidden {
            firstView = cameraSetupView
            firstConstraint = selfViewSetupHeight
            firstConstant = 0
            secondView = selfViewHiddenHelpLabel
            secondConstraint = selfViewHiddenHelpLabelHeight
            secondConstant = selfViewSetupHelpLabelHeightContant
            
        }
        else {
            firstView = selfViewHiddenHelpLabel
            firstConstraint = selfViewHiddenHelpLabelHeight
            firstConstant = 0
            secondView = cameraSetupView
            secondConstraint = selfViewSetupHeight
            secondConstant = selfViewSetupHeightContant
        }
        
        expandedView(withAnim: { [weak self] in
            if let _ = self {
                firstView?.alpha = 0
                firstConstraint?.constant = firstConstant ?? 0
            }
        }){ [weak self] in
            if let strongSelf = self {
                strongSelf.expandedView(withAnim:{
                    secondView?.alpha = 1
                    secondConstraint?.constant = secondConstant ?? 0
                }
                )
            }
        }
        
    }
    
    private func expandedView(withAnim animations:@escaping () -> Swift.Void,completion: (() -> Swift.Void)? = nil) {
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 10.0, options: .curveEaseIn, animations: { [weak self]  in
            if let strongSelf = self {
                animations()
                strongSelf.view.layoutIfNeeded()
            }
            
            }, completion: { finished in
                if let finishedCompletion = completion {
                    finishedCompletion()
                }
        })
    }
    
    @objc func gotoInitiateCallView() {
        if let initiateCallViewController = (storyboard?.instantiateViewController(withIdentifier: "InitiateCallViewController") as? InitiateCallViewController) {
            initiateCallViewController.webexSDK = self.webexSDK
            navigationController?.pushViewController(initiateCallViewController, animated: true)
        }
        
    }
    
}
