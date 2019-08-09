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


class HomeTableViewController: BaseTableViewController {
    
    // MARK: - UI outlets variables
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var cloudConnectionStateLabel: UILabel!
    @IBOutlet weak var buttonHeight: NSLayoutConstraint!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet var heightScaleCollection: [NSLayoutConstraint]!
    @IBOutlet var widthScaleCollection: [NSLayoutConstraint]!
    @IBOutlet var labelFontScaleCollection: [UILabel]!
    @IBOutlet var buttonFontScaleCollection: [UIButton]!
    let indicatorView = UIActivityIndicatorView(style: .gray)
    
    /// isWebexPhoneRegisterd reperesent if the phone device complete register to Cisco Cloud
    var isWebexPhoneRegisterd: Bool = false
    
    /// saparkSDK reperesent for the WebexSDK API instance
    var webexSDK: Webex?
    
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Register current phone device on Cisco Webex cloud. */
        self.webexRegisterPhone()
        
        /* Fetch the details for the current authenticated user. */
        self.webexFetchUserProfile()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    // MARK: - WebexSDK: WebexPhone register | WebexUser get profile
    
    func webexRegisterPhone() {
        /*
         Registers this phone to Cisco Webex cloud on behalf of the authenticated user.
         It also creates the websocket and connects to Cisco Webex cloud.
         - note: make sure register device before calling
         */
        let uuid = NSUUID().uuidString
        print(uuid)
        self.webexSDK?.phone.register() { [weak self] error in
            if let strongSelf = self {
                if error != nil {
                    //register phone fail codes here...
                    strongSelf.updateCloudConnectionSateUpdate("fail")
                    
                } else {
                    //register phone success codes here...
                    strongSelf.isWebexPhoneRegisterd = true
                    strongSelf.updateCloudConnectionSateUpdate("ok")
                }
            }
        }
    }
    
    func webexFetchUserProfile() {
        /* Retrieves the details for the authenticated user. */
        self.webexSDK?.people.getMe() {[weak self] response in
            if let strongSelf = self {
                switch response.result {
                case .success(let person):
                    strongSelf.updateUserStatusLabel(person: person)
                case .failure:
                    strongSelf.updateUserStatusLabel(person: nil)
                }
            }
        }
    }
    
    // MARK: - Button actions process function
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "Video/AudioBtnClicked") {
            let videoAudioSettingVC = segue.destination as! VideoAudioSetupViewController
            videoAudioSettingVC.webexSDK = self.webexSDK
        }else if(segue.identifier == "WaitingCallBtnClicked"){
            let waitingCallVC = segue.destination as! WaitingCallViewController
            waitingCallVC.webexSDK = self.webexSDK
        }else if(segue.identifier == "InitiateCallBtnClicked"){
            let initiateCallVC = segue.destination as! InitiateCallViewController
            initiateCallVC.webexSDK = self.webexSDK
        }
    }
    
    /// logout Button Click | Deauthorize webexSDK when logging out
    @IBAction func logoutButtonClicked() {
        guard self.webexSDK != nil else {
            _ = navigationController?.popToRootViewController(animated: true)
            return
        }
        
        /* check if the phone has already registerd to Cisco cloud */
        if self.isWebexPhoneRegisterd{
            
            /* showing indicator view while deregister device*/
            self.view.addSubview(self.indicatorView)
            self.indicatorView.center = self.view.center
            self.indicatorView.startAnimating()
            
            /*
             Removes this *phone* from Cisco Webex cloud on behalf of the authenticated user.
             It also disconnects the websocket from Cisco Webex cloud.
             Subsequent invocations of this method behave as a no-op.
             */
            self.webexSDK!.phone.deregister() { ret in
                self.indicatorView.stopAnimating()
                // Deauthorizes the current user and clears any persistent state with regards to the current user.
                // If the *phone* is registered, it should be deregistered before calling this method.
                self.webexSDK?.authenticator.deauthorize()
                self.webexSDK = nil
                self.navigationController?.popToRootViewController(animated: true)
            }
        }else{
            // Deauthorizes the current user and clears any persistent state with regards to the current user.
            // If the *phone* is registered, it should be deregistered before calling this method.
            self.webexSDK?.authenticator.deauthorize()
            self.webexSDK = nil
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    
    // MARK: - UI Implementation
    
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
        
        
        for button in buttonFontScaleCollection {
            button.titleLabel?.font = UIFont.buttonLightFont(ofSize: (button.titleLabel?.font.pointSize)! * Utils.HEIGHT_SCALE)
            button.setBackgroundImage(UIImage.imageWithColor(UIColor.buttonBlueNormal(), background: nil), for: .normal)
            button.setBackgroundImage(UIImage.imageWithColor(UIColor.buttonBlueHightlight(), background: nil), for: .highlighted)
            button.clipsToBounds = true
            button.layer.cornerRadius = buttonHeight.constant/2
        }
        
        var frame = footerView.frame
        frame.size.height *= Utils.HEIGHT_SCALE
        self.footerView.frame = frame
        
        self.statusLabel.text = "fetching user profile..."
        self.cloudConnectionStateLabel.text = "Registration to Cisco cloud : connecting..."
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 1 {
            return 80 * Utils.HEIGHT_SCALE
        }
        else if indexPath.section == 0 && indexPath.row == 0 {
            return 80 * Utils.HEIGHT_SCALE
        }
        else if indexPath.section == 1 {
            return 75 * Utils.HEIGHT_SCALE
        }
        return super.tableView(tableView, heightForRowAt: indexPath) * Utils.HEIGHT_SCALE
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 && indexPath.row == 5 {
            self.logoutButtonClicked()
        }else if indexPath.section == 1 && indexPath.row == 0{
            self.messageBtnClicked()
        }
    }
    
    @IBAction func messageBtnClicked(){
        let messageVC = SpaceListViewController()
        messageVC.webexSDK = self.webexSDK
        self.navigationController?.pushViewController(messageVC, animated: true)
    }
    
    fileprivate func updateUserStatusLabel(person: Person?) {
        if let person = person{
            UserDefaultsUtil.userId = person.id
            self.statusLabel.text = "login as: \(person.displayName ?? "NONE")"
        }else{
            self.statusLabel.text = "Fetching user profile failed."
        }
    }
    fileprivate func updateCloudConnectionSateUpdate(_ stateString: String){
        self.cloudConnectionStateLabel.text = "Registration to Cisco cloud : " + stateString
    }
    
    fileprivate func showPhoneRegisterFailAlert() {
        let alert = UIAlertController(title: "Alert", message: "Phone register fail", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

