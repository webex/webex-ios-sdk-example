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

class WaitingCallViewController: BaseViewController {
    
    //MARK: - UI outlets variables
    @IBOutlet var labelFontScaleCollection: [UILabel]!
    @IBOutlet var heightScaleCollection: [NSLayoutConstraint]!
    private var waittingTimer: Timer?
    @IBOutlet weak var animationLabel: UILabel!
    override var navigationTitle: String? {
        get {
            return "Wait Call"
        }
        set(newValue) {
            title = newValue
        }
    }

    /// saparkSDK reperesent for the WebexSDK API instance
    var webexSDK: Webex?
    
    /// receivedCall represent the call currently received
    private var receivedCall: Call?
    

    
    // MARK: - Life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /* register phone callback functions for incoming call */
        self.webexCallBackInit()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startWaitingAnimation()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopWaitingAnimation()
    }
    
    // MARK: - WebexSDK: register callback code for Call reception
    func webexCallBackInit() {
        if let phone = self.webexSDK?.phone {
            
            /*  Callback when call is incoming. */
            phone.onIncoming = { [weak self] call in
                ///codes after receive cll here...
                if let strongSelf = self {
                    strongSelf.receivedCall = call
                    strongSelf.presentCallToastView(call)
                }
            }
        }
    }
    
    fileprivate func presentCallToastView(_ call: Call) {
        if let callToastViewController = storyboard?.instantiateViewController(withIdentifier: "CallToastViewController") as? CallToastViewController {
            callToastViewController.modalPresentationStyle = .fullScreen
            callToastViewController.modalTransitionStyle = .coverVertical
            
            /// Answer/Reject button click block
            callToastViewController.answerBtnClickedBlock = {
                self.presentVideoCallView()
            }
            callToastViewController.rejectBtnClickedBlock = {
                self.receivedCall?.reject() { error in
                    if error != nil {
                        print("Decline error :\(error!)")
                    }
                }
            }
            callToastViewController.incomingCall = self.receivedCall
            callToastViewController.webexSDK = self.webexSDK
            present(callToastViewController, animated: true, completion: nil)
        }
    }
    
    fileprivate func presentVideoCallView() {
                
        if let videoCallViewController = (storyboard?.instantiateViewController(withIdentifier: "VideoCallViewController") as? VideoCallViewController) {
            videoCallViewController.currentCall = self.receivedCall
            videoCallViewController.videoCallRole = VideoCallRole.CallReceiver(self.receivedCall?.from?.displayName ?? "Unknown")
            videoCallViewController.webexSDK = self.webexSDK
            navigationController?.pushViewController(videoCallViewController, animated: true)
        }
    }
    
    // MARK: - UI Implemetation
    override func initView() {
        for label in labelFontScaleCollection {
            label.font = UIFont.labelLightFont(ofSize: label.font.pointSize * Utils.HEIGHT_SCALE)
        }
        for heightConstraint in heightScaleCollection {
            heightConstraint.constant *= Utils.HEIGHT_SCALE
        }
    }
    
    func startWaitingAnimation() {
        stopWaitingAnimation()
        waittingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.waitingAnimation), userInfo: nil, repeats: true)
    }
    
    func stopWaitingAnimation() {
        if let timer = waittingTimer {
            if timer.isValid {
                timer.invalidate()
            }
            waittingTimer = nil
        }
    }
    
    @objc func waitingAnimation() {
        if let labelText = animationLabel.text {
            if labelText.count > 2 {
                animationLabel.text = ""
            }
            else {
                animationLabel.text!.append(".")
            }
        }
        
    }
}
