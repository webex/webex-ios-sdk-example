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

class InitiateCallViewController: BaseViewController, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: UI outlets variables
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var dialAddressTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var spaceTableView: UITableView!
    @IBOutlet var widthScaleCollection: [NSLayoutConstraint]!
    @IBOutlet var heightScaleCollection: [NSLayoutConstraint]!
    @IBOutlet var textFieldScaleCollection: [UITextField]!
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    fileprivate var searchResult: [Person]?
    fileprivate var historyResult: [Person]?
    fileprivate var spaceResult: [Room]?
    fileprivate var dialEmail: String?
    fileprivate var segmentedControl: UISegmentedControl?
    
    /// saparkSDK reperesent for the WebexSDK API instance
    var webexSDK: Webex?
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = true
        self.setupView()
    }
    
    
    // MARK: - Dial call processing
    @IBAction func dialBtnClicked(_ sender: AnyObject) {
        if let emailAddress = dialAddressTextField.text{
            self.dialWithEmailAddress(emailAddress)
        }
    }
    
    func dialWithEmailAddress(_ emailAddress: String){
        if emailAddress.isEmpty {
            showNoticeAlert("Address is empty")
            return
        }
        self.presentVideoCallView(emailAddress)
    }
    
    func dialRoomWithRoomId(_ roomId: String, _ roomName: String){
        self.presentRoomVideoCallView(roomId,roomName)
    }
    
    fileprivate func presentVideoCallView(_ remoteAddr: String) {
        if let videoCallViewController = (storyboard?.instantiateViewController(withIdentifier: "VideoCallViewController") as? VideoCallViewController) {
            videoCallViewController.videoCallRole = VideoCallRole.CallPoster(remoteAddr)
            videoCallViewController.webexSDK = self.webexSDK
            navigationController?.pushViewController(videoCallViewController, animated: true)
        }
    }
    
    fileprivate func presentRoomVideoCallView(_ roomId: String, _ roomName: String) {
        if let videoCallViewController = (storyboard?.instantiateViewController(withIdentifier: "VideoCallViewController") as? VideoCallViewController) {
            videoCallViewController.videoCallRole = VideoCallRole.RoomCallPoster(roomId, roomName)
            videoCallViewController.webexSDK = self.webexSDK
            navigationController?.pushViewController(videoCallViewController, animated: true)
        }
    }
    
    // MARK: - WebexSDK: search people with Email/SearchString

    private func webexFetchPersonProfilesWithEmail(searchStr: String){
        if let email = EmailAddress.fromString(searchStr) {
            /* Lists people with email address in the authenticated user's organization. */
            self.webexSDK?.people.list(email: email, max: 10) {
                (response: ServiceResponse<[Person]>) in
                
                self.indicatorView.stopAnimating()
                switch response.result {
                case .success(let value):
                    self.searchResult = value
                case .failure:
                    self.searchResult = nil
                }
                if searchStr == self.searchController.searchBar.text! {
                    self.tableView.reloadData()
                }
            }
        } else {
            /* Lists people with display name in the authenticated user's organization. */
            self.webexSDK?.people.list(displayName: searchStr, max: 10) {
                (response: ServiceResponse<[Person]>) in
                self.indicatorView.stopAnimating()
                switch response.result {
                case .success(let value):
                    self.searchResult = value
                case .failure:
                    self.searchResult = nil
                }
                if searchStr == self.searchController.searchBar.text! {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - WebexSDK: list Space
    private func webexListRoom(){
        self.indicatorView.startAnimating()
        self.webexSDK?.rooms.list(type: RoomType.group ,completionHandler: { (response: ServiceResponse<[Room]>) in
            self.indicatorView.stopAnimating()
            switch response.result {
            case .success(let value):
                self.spaceResult = value
                
            case .failure:
                self.searchResult = nil
            }
            self.spaceTableView.reloadData()
        })
    }
    
    // MARK: - UI Implementation
    override func initView() {
        for textfield in textFieldScaleCollection {
            textfield.font = UIFont.textViewLightFont(ofSize: (textfield.font?.pointSize)! * Utils.HEIGHT_SCALE)
        }
        for heightConstraint in heightScaleCollection {
            heightConstraint.constant *= Utils.HEIGHT_SCALE
        }
        for widthConstraint in widthScaleCollection {
            widthConstraint.constant *= Utils.WIDTH_SCALE
        }
    }
    fileprivate func setupView() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(dissmissKeyboard))
        view.addGestureRecognizer(tap)
        historyTableView.dataSource = self
        historyTableView.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        spaceTableView.dataSource = self
        spaceTableView.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Email or user name"
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        view.bringSubview(toFront: indicatorView)
        dialAddressTextField.layer.borderColor = UIColor.gray.cgColor
        
        let itemArray = [UIImage.fontAwesomeIcon(name: .history, textColor: UIColor.titleGreyColor(), size: CGSize.init(width: 32*Utils.WIDTH_SCALE , height: 29)),UIImage.fontAwesomeIcon(name: .search, textColor: UIColor.titleGreyColor(), size: CGSize.init(width: 32*Utils.WIDTH_SCALE , height: 29)),UIImage.fontAwesomeIcon(name: .phone, textColor: UIColor.titleGreyColor(), size: CGSize.init(width: 32*Utils.WIDTH_SCALE , height: 29)),UIImage.fontAwesomeIcon(name: .group, textColor: UIColor.titleGreyColor(), size: CGSize.init(width: 32*Utils.WIDTH_SCALE , height: 29))]
        segmentedControl = UISegmentedControl.init(items: itemArray)
        segmentedControl?.frame = CGRect.init(x: 0, y: 0, width: 150, height: 29)
        segmentedControl?.tintColor = UIColor.titleGreyColor()
        segmentedControl?.selectedSegmentIndex = 0
        segmentedControl?.addTarget(self, action: #selector(switchDialWay(_:)),for:.valueChanged)
        navigationItem.titleView = segmentedControl
        
        //init history tableView data
        historyResult = UserDefaultsUtil.callPersonHistory
        historyResult?.reverse()
        historyTableView.reloadData()
        
        
    }
    
    @IBAction func switchDialWay(_ sender: AnyObject) {
        dissmissKeyboard()
        switch sender.selectedSegmentIndex
        {
        case 0:
            hideHistoryView(false)
            hideDialAddressView(true)
            hideSearchView(true)
            hideSpaceView(true)
        case 1:
            hideDialAddressView(true)
            hideSearchView(false)
            hideHistoryView(true)
            hideSpaceView(true)
        case 2:
            hideHistoryView(true)
            hideSearchView(true)
            hideDialAddressView(false)
            hideSpaceView(true)
        case 3:
            hideHistoryView(true)
            hideSearchView(true)
            hideDialAddressView(true)
            hideSpaceView(false)
        default:
            break;
        }
    }
    
    
    fileprivate func hideSearchView(_ hidden: Bool) {
        searchController.isActive = false
        tableView.isHidden = hidden
        if !hidden {
            searchController.searchBar.becomeFirstResponder()
        }
    }
    
    fileprivate func hideHistoryView(_ hidden: Bool) {
        historyTableView.isHidden = hidden
        
        if !hidden {
            historyResult = UserDefaultsUtil.callPersonHistory
            historyResult?.reverse()
            historyTableView.reloadData()
        }
    }
    
    fileprivate func hideSpaceView( _ hidden: Bool){
        spaceTableView.isHidden = hidden
        
        if !hidden {
            self.webexListRoom()
        }
    }
    
    fileprivate func hideDialAddressView(_ hidden: Bool) {
        dialAddressTextField.isHidden = hidden
        if !hidden {
            dialAddressTextField.becomeFirstResponder()
        }
    }
    
    override func dissmissKeyboard() {
        super.dissmissKeyboard()
        searchController.searchBar.endEditing(true)
    }
    
    fileprivate func showNoticeAlert(_ notice:String) {
        let alert = UIAlertController(title: "Alert", message: notice, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // MARK: search bar result updating delegate
    func updateSearchResults(for searchController: UISearchController) {
        let searchString = searchController.searchBar.text!
        
        if searchString.count < 3 {
            searchResult?.removeAll()
            tableView.reloadData()
            return
        }
        
        indicatorView.startAnimating()
        self.webexFetchPersonProfilesWithEmail(searchStr: searchString)
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100 * Utils.HEIGHT_SCALE
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.tableView && searchResult != nil  {
            return searchResult!.count
        } else if tableView == self.historyTableView {
            return historyResult?.count ?? 0
        } else if  tableView == self.spaceTableView{
            return spaceResult?.count ?? 0
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if(tableView == self.tableView || tableView == self.historyTableView){
            let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell", for: indexPath) as! PersonTableViewCell
        
            let dataSource: [Person]?
            
            if tableView == self.tableView {
                dataSource = searchResult
            }
            else {
                dataSource = historyResult
            }
            
            let person = dataSource?[indexPath.row]
            let email = person?.emails?.first
            cell.address = email?.toString()
            cell.initiateCallViewController = self
            
            Utils.downloadAvatarImage(person?.avatar, completionHandler: {
                cell.avatarImageView.image = $0
            })
            cell.nameLabel.text = person?.displayName
            
            return cell
        }else{
             let cell = tableView.dequeueReusableCell(withIdentifier: "SpaceCell", for: indexPath) as! SpaceTableViewCell
            
            let dataSource: [Room]?
            
            dataSource = spaceResult
            
            let room = dataSource?[indexPath.row]
            let roomName = room?.title
            let roomId = room?.id
            cell.roomId = roomId
            cell.roomName = roomName
            cell.initiateCallViewController = self
            cell.spaceNameLabel.text = roomName
            
            return cell
        }
    }
    // MARK: other functions
    deinit {
        searchController.view.removeFromSuperview()
    }
    
}
