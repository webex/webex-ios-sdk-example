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

class CallToastViewController: BaseViewController {
    
    //MARK: - UI outlets variables
    @IBOutlet private weak var avatarImage: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet weak var avatarViewHeight: NSLayoutConstraint!
    @IBOutlet var labelFontScaleCollection: [UILabel]!
    @IBOutlet var heightScaleCollection: [NSLayoutConstraint]!
    @IBOutlet var widthScaleCollection: [NSLayoutConstraint]!    
    /// answerBtn clicked block 
    var answerBtnClickedBlock : (()->())?
    
    /// rejectBtn clicked block
    var rejectBtnClickedBlock : (()->())?
    
    /// incomingCall represent for current incoming call
    var incomingCall: Call?
    
    /// saparkSDK reperesent for the WebexSDK API instance
    var webexSDK: Webex?
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webexFetchUserProfiles()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /*
         Callback when this *call* is disconnected (hangup, cancelled, get declined or other self device pickup the call).
        */
        self.checkCallStatus()
    }
    
    // MARK: - WebexSDK: fetch person info with a incoming call
    private func webexFetchUserProfiles() {
        // check the user is logically authorized.
        if self.webexSDK?.authenticator.authorized == true {
            
            var callerEmailString = ""
            
            if let incomingCall = self.incomingCall{
                for member in incomingCall.memberships {
                    if member.isInitiator == true {
                        callerEmailString = member.displayName ?? "Unkown"
                    }
                }
            }
            
            if (callerEmailString != "Unkown") {
                /* 
                 Person list is empty with SIP email address
                 Lists people in the authenticated user's organization.
                 */
                self.webexSDK?.people.list(email: EmailAddress.fromString(callerEmailString), max: 1) { response in
                    
                    // Check Response Status
                    switch response.result {
                    case .success(let value):
                        // Request Success Processing
                        var persons: [Person] = []
                        persons = value
                        if let person = persons.first {
                            self.upDateUI(person: person)
                        }
                    case .failure(let error):
                        // Request Fail Processing
                        print("ERROR: \(error)")
                    }
                }
            } else {
                print("could not parse email address \(callerEmailString) for retrieving user profile")
            }
        }
    }

    // MARK: WebexSDK: Check call Status Function
    func checkCallStatus() {
        /* 
         Callback when this *call* is disconnected (hangup, cancelled, get declined or other self
         device pickup the call).
         */
        if let call = self.incomingCall {
            call.onDisconnected = { [weak self] disconnectionType in
                if let strongSelf = self {
                    strongSelf.dismissView()
                }
            }
        }
    }
    
    // MARK: - UI Implementation
    override func initView() {
        
        if let incomingCall = self.incomingCall{
            for member in incomingCall.memberships {
                if member.isInitiator == true {
                    nameLabel.text = member.displayName ?? "Unknown"
                }
            }
        }

        for label in labelFontScaleCollection {
            label.font = UIFont.labelLightFont(ofSize: label.font.pointSize * Utils.HEIGHT_SCALE)
        }
        for heightConstraint in heightScaleCollection {
            heightConstraint.constant *= Utils.HEIGHT_SCALE
        }
        for widthConstraint in widthScaleCollection {
            widthConstraint.constant *= Utils.WIDTH_SCALE
        }
        
        avatarImage.layer.cornerRadius = avatarViewHeight.constant/2
        
    }
    
    private func upDateUI(person: Person){
        if let incomingCall = self.incomingCall{
            for member in incomingCall.memberships {
                if member.isInitiator == true {
                    nameLabel.text = member.displayName ?? "Unknown"
                }
            }
        }
        if let displayName = person.displayName {
            self.nameLabel.text = displayName
        }
        if let avatarUrl = person.avatar {
            self.fetchAvatarImage(avatarUrl)
        }
    }
    
    // MARK: ToasingView wake up answer/reject Blocks
    
    @IBAction private func answerButtonPressed(_ sender: AnyObject) {
        if(self.answerBtnClickedBlock != nil){
            self.answerBtnClickedBlock!()
        }
        dismissView()
    }
    
    @IBAction private func declineButtonPressed(_ sender: AnyObject) {
        if(self.rejectBtnClickedBlock != nil){
            self.rejectBtnClickedBlock!()
        }
        dismissView()
    }
    
    private func fetchAvatarImage(_ avatarUrl: String) {
        Utils.downloadAvatarImage(avatarUrl, completionHandler: { [weak self] avatarImage in
            if let strongSelf = self {
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
                    strongSelf.avatarImage.alpha = 1
                    strongSelf.avatarImage.alpha = 0.1
                    strongSelf.view.layoutIfNeeded()
                }, completion: { [weak self] finished in
                    if let strongSelf = self {
                        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
                            strongSelf.avatarImage.image = avatarImage
                            strongSelf.avatarImage.alpha = 1
                            strongSelf.view.layoutIfNeeded()
                        }, completion: nil)
                    }
                })
            }
        })
    }
    
    
    
    private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}
