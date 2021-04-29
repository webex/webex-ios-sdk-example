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

class Utils {
    static let HEIGHT_SCALE: CGFloat = UIScreen.main.bounds.height / 736.0
    static let WIDTH_SCALE: CGFloat = UIScreen.main.bounds.width / 414.0
    
    static func getDataFromUrl(_ urlString:String, completion: @escaping ((_ data: Data?, _ response: URLResponse?, _ error: Error? ) -> Void)) {
        let url = URL(string: urlString)
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            completion(data, response, error)
        }
        task.resume()
    }
    
    ///Download a image with image url
    static func downloadAvatarImage(_ url: String?, completionHandler: @escaping (_ image : UIImage) -> Void) {
        if url == nil || url!.isEmpty {
            let image = UIImage(named: "DefaultAvatar")
            completionHandler(image!)
            return
        }

        let fileName = URL(fileURLWithPath: url!).lastPathComponent + ".jpg"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagePath = documentsURL.appendingPathComponent(fileName).path
        
        if FileManager.default.fileExists(atPath: imagePath) {
            let image = UIImage(contentsOfFile: imagePath)
            completionHandler(image!)
        } else {
            getDataFromUrl(url!) { (data, response, error) in
                guard let data = data , error == nil else { return }
                print("Download Finished")
                do {
                    try data.write(to: URL(fileURLWithPath: imagePath), options: .atomicWrite)
                } catch {
                    print(error)
                }
                DispatchQueue.main.async { () -> Void in
                    let image = UIImage(data: data)
                    completionHandler(image!)
                }
            }
        }
    }
    
    static func showCameraMicrophoneAccessDeniedAlert(_ parentView: UIViewController) {
        let AlertTitle = "Access Denied"
        let AlertMessage = "Calling requires access to the camera and microphone. To fix this, go to Settings|Privacy|Camera and Settings|Privacy|Microphone, find this app and grant access."
        
        let alert = UIAlertController(title: AlertTitle, message: AlertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        parentView.present(alert, animated: true, completion: nil)
    }
    
    static func showAlert(_ parentView: UIViewController, title: String?, message: String?, cancel:(() -> Void)? = nil, confirm:(() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            cancel?()
        }))
        if let confirm = confirm {
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                confirm()
            }))
        }
        parentView.present(alert, animated: true, completion: nil)
    }
    
}
