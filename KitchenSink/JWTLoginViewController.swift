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
import Toast_Swift

class JWTLoginViewController: BaseViewController {
    
    // MARK: - UI outlets variables
    @IBOutlet weak var jwtTextField: UITextField!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var jwtLoginButton: UIButton!
    @IBOutlet weak var waitingView: UIActivityIndicatorView!
    @IBOutlet var textFieldFontScaleCollection: [UITextField]!
    @IBOutlet var labelFontScaleCollection: [UILabel]!
    @IBOutlet var heightScaleCollection: [NSLayoutConstraint]!
    @IBOutlet var widthScaleCollection: [NSLayoutConstraint]!
    @IBOutlet var buttonFontScaleCollection: [UIButton]!
    @IBOutlet weak var imageTopToSuperView: NSLayoutConstraint!
    private var topToSuperView: CGFloat = 0
    @IBOutlet weak var buttonHeightConstraint: NSLayoutConstraint!
    
    /// saparkSDK reperesent for the WebexSDK API instance
    var webexSDK: Webex?
    
    
    // MARK: - Life cycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /*
         Check wether webexSDK is already authorized, webexSDk saves authorization info in device key-chain
         -note: if user didn't logged out or didn't deauthorize, "jwtAuthStrategy.authorized" function will return true
         -note: if webexSDK is authorized, directly jump to login success process
         */
        let jwtAuthStrategy = JWTAuthenticator()
        if jwtAuthStrategy.authorized == true {
            /* JWT Login success process codes here....*/
            self.webexSDK = Webex(authenticator: jwtAuthStrategy)
            self.webexSDK?.logger = KSLogger() //Register a console logger into SDK
            self.loginSuccessProcess()
        }else{
            /* JWT Login failure process codes here....*/
            self.jwtTextField.becomeFirstResponder()
        }
    }
    
    // MARK: - WebexSDK: JWT Login
    @IBAction func jwtLoginBtnClicked(_ sender: UIButton) {
        guard let jwtString = jwtTextField.text else {
            return
        }
        self.jwtTextField.resignFirstResponder()
        
        /*
         A [JSON Web Token](https://jwt.io/introduction) (JWT) based authentication strategy
         is to be used to authenticate a guest user on Cisco Webex.
         */
        let jwtAuthStrategy = JWTAuthenticator()
        jwtAuthStrategy.authorizedWith(jwt: jwtString)
        if jwtAuthStrategy.authorized == true {
            /* JWT Login success process codes here....*/
            self.webexSDK = Webex(authenticator: jwtAuthStrategy)
            self.webexSDK?.logger = KSLogger() //Register a console logger into SDK
            self.loginSuccessProcess()
        } else {
            /* JWT Login failure process codes here....*/
            showLoginError()
        }
    }
    
    private func loginSuccessProcess(){
        let homeViewController = self.storyboard?.instantiateViewController(withIdentifier: "HomeTableViewController") as! HomeTableViewController
        homeViewController.webexSDK = self.webexSDK
        self.navigationController?.pushViewController(homeViewController, animated: true)
    }
    
    private func loginFailureProcess(error: Error){

        let alert = UIAlertController(title: "Could Not Get Personal Info", message: "Unable to retrieve information about the user logged in using the JWT: Please make sure your JWT is correct. \(error)", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(okAction)
        
        self.present(alert, animated: true)
    }
    
    // MARK: - UI Implementation
    override func initView()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        topToSuperView = imageTopToSuperView.constant
        
        for label in labelFontScaleCollection {
            label.font = UIFont.labelLightFont(ofSize: label.font.pointSize * Utils.HEIGHT_SCALE)
        }
        for button in buttonFontScaleCollection {
            button.titleLabel?.font = UIFont.buttonLightFont(ofSize: (button.titleLabel?.font.pointSize)! * Utils.HEIGHT_SCALE)
        }
        for heightConstraint in heightScaleCollection {
            heightConstraint.constant *= Utils.HEIGHT_SCALE
        }
        for widthConstraint in widthScaleCollection {
            widthConstraint.constant *= Utils.WIDTH_SCALE
        }
        for textField in textFieldFontScaleCollection {
            textField.font = UIFont.textViewLightFont(ofSize: (textField.font?.pointSize)! * Utils.HEIGHT_SCALE)
        }
        statusLabel.text = "Powered by WebexSDK v" + Webex.version
        jwtLoginButton.setBackgroundImage(UIImage.imageWithColor(UIColor.buttonBlueNormal(), background: nil), for: .normal)
        jwtLoginButton.setBackgroundImage(UIImage.imageWithColor(UIColor.buttonBlueHightlight(), background: nil), for: .highlighted)
        jwtLoginButton.layer.cornerRadius = buttonHeightConstraint.constant/2
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    /// - JWT Text Field & Button Enable/Disable
    @IBAction func jwtTextFieldChanged(_ sender: UITextField) {
        jwtLoginButton.isEnabled = !((jwtTextField.text?.isEmpty) ?? false)
        jwtLoginButton.alpha = (jwtLoginButton.isEnabled) ? 1.0 : 0.5
    }
    
    private func showLoginError() {
        let alert = UIAlertController(title: "Could Not Login", message: "Unable to Login: Please make sure your JWT is correct.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel) {
            action in
            
        }
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    func showWaitingView() {
        waitingView.startAnimating()
        jwtLoginButton.setTitleColor(UIColor.clear, for: UIControl.State.disabled)
        jwtLoginButton.isEnabled = false
        jwtLoginButton.alpha = 0.5
    }
    
    func hideWaitingView() {
        waitingView.stopAnimating()
        jwtLoginButton.setTitleColor(UIColor.white, for: UIControl.State.disabled)
        jwtLoginButton.alpha = 1
        jwtTextFieldChanged(jwtTextField)
    }
    
    @objc func keyboardWillShow(notification:NSNotification) {
        guard imageTopToSuperView.constant != 0 else {
            return
        }
        
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            guard keyboardSize.size.height > 0 else {
                return
            }
            
            let textViewButtom = jwtLoginButton.frame.origin.y + jwtLoginButton.frame.size.height
            let keyboardY = UIScreen.main.bounds.height - keyboardSize.size.height
            if keyboardY < textViewButtom {
                UIView.animate(withDuration: 0.5) { [weak self] in
                    if let strongSelf = self {
                        strongSelf.imageTopToSuperView.constant = 0
                        strongSelf.view.layoutIfNeeded()
                    }
                }
            }
        }
    }
    
    @objc func keyboardWillHide(notification:NSNotification) {
        if imageTopToSuperView.constant != topToSuperView {
            UIView.animate(withDuration: 0.5) { [weak self] in
                if let strongSelf = self {
                    strongSelf.imageTopToSuperView.constant = strongSelf.topToSuperView
                    strongSelf.view.layoutIfNeeded()
                }
            }
        }
    }
    
}
