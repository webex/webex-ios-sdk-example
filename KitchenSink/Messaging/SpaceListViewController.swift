//
//  SpaceListViewController.swift
//  KitchenSink
//
//  Created by qucui on 2018/1/18.
//  Copyright 2016-2019 Cisco Systems Inc. All rights reserved.
//

import UIKit
import WebexSDK
enum SegmentType : Int{
    case history = 0
    case search = 1
    case email = 2
    case space = 3
}
let cellHeight : CGFloat = 100.0
class SpaceListViewController: BaseViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    fileprivate var backView: UIView?
    fileprivate var indicatorView: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    fileprivate var segmentedControl: UISegmentedControl?
    fileprivate var spaceType: SpaceType = SpaceType.group
    fileprivate var searchResult: [Person] = [Person]()
    fileprivate var historyResult: [Person] = [Person]()
    fileprivate var spaceResult: [Space] = [Space]()
    fileprivate var messageEmailTextField: UITextField?
    fileprivate var messageEmailBackView: UIView?
    fileprivate var historyTableView: UITableView?
    fileprivate var spaceTableView: UITableView?
    fileprivate var searchTableView: UITableView!
    fileprivate let searchBar : UISearchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 40))
    fileprivate var currentSegType: SegmentType = SegmentType.history
    fileprivate var createSpaceButton: UIButton?
    
    
    /// saparkSDK reperesent for the WebexSDK API instance
    var webexSDK: Webex?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.title = "Messaging"
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.setupView()
    }
    
    // MARK: - WebexSDK: search people with Email/SearchString
    private func webexFetchPersonProfilesWithEmail(searchStr: String){
        self.indicatorView.startAnimating()
        if let email = EmailAddress.fromString(searchStr) {
            /* Lists people with email address in the authenticated user's organization. */
            self.webexSDK?.people.list(email: email, max: 10) {
                (response: ServiceResponse<[Person]>) in
                self.indicatorView.stopAnimating()
                switch response.result {
                case .success(let value):
                    self.searchResult = value
                case .failure:
                    self.searchResult.removeAll()
                }
                if searchStr == self.searchBar.text! {
                    self.searchTableView.reloadData()
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
                    self.searchResult.removeAll()
                }
                if searchStr == self.searchBar.text! {
                    self.searchTableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - WebexSDK: list Spaces
    private func requestWebexSpaceList(){
        self.indicatorView.startAnimating()
        self.webexSDK?.spaces.list(max: 5, type: self.spaceType ,sortBy: SpaceSortType.byLastActivity ,completionHandler: { (response: ServiceResponse<[Space]>) in
            self.indicatorView.stopAnimating()
            switch response.result {
            case .success(let value):
                self.spaceResult.removeAll()
                self.spaceResult = value
                self.spaceTableView?.reloadData()
            case .failure:
                break
            }
        })
    }
    
    
    // MARK: - UI Implementation
    public func setupView(){
        let itemArray = [UIImage.fontAwesomeIcon(name: .history, textColor: UIColor.titleGreyColor(), size: CGSize.init(width: 32*Utils.WIDTH_SCALE , height: 29)),UIImage.fontAwesomeIcon(name: .search, textColor: UIColor.titleGreyColor(), size: CGSize.init(width: 32*Utils.WIDTH_SCALE , height: 29)),UIImage.fontAwesomeIcon(name: .commenting, textColor: UIColor.titleGreyColor(), size: CGSize.init(width: 32*Utils.WIDTH_SCALE , height: 29)),UIImage.fontAwesomeIcon(name: .group, textColor: UIColor.titleGreyColor(), size: CGSize.init(width: 32*Utils.WIDTH_SCALE , height: 29))]
        
        //init history tableView data
        segmentedControl = UISegmentedControl.init(items: itemArray)
        segmentedControl?.frame = CGRect.init(x: 0, y: 0, width: 150, height: 29)
        segmentedControl?.setTintColor(UIColor.titleGreyColor())
        segmentedControl?.selectedSegmentIndex = 0
        segmentedControl?.addTarget(self, action: #selector(segmentClicked(_:)),for:.valueChanged)
        navigationItem.titleView = segmentedControl
        
        //init back view
        self.backView = UIView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight))
        self.backView?.backgroundColor = UIColor.white
        self.view.addSubview(self.backView!)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(dissmissKeyboard))
        view.addGestureRecognizer(tap)
        
        self.processSegmentClickedWithType(self.currentSegType)
    }
    
    @IBAction func segmentClicked(_ sender: AnyObject) {
        dissmissKeyboard()
        self.currentSegType = SegmentType(rawValue: sender.selectedSegmentIndex)!
        self.processSegmentClickedWithType(self.currentSegType)
    }
    
    private func processSegmentClickedWithType(_ type: SegmentType){
        switch type
        {
        case .history:
            self.setUpHistoryTableView()
            break
        case .search:
            self.setUpSearchTableView()
            break
        case .email:
            self.setUpMessageEmailView()
            break
        case .space:
            self.setUpSpaceTableView()
            break
        }
    }
    
    @objc private func messageToEmailButtonClicked(){
        if let emailAddress = self.messageEmailTextField?.text{
            if emailAddress.count == 0{
                return
            }
            self.webexSDK?.people.list(email: EmailAddress.fromString(emailAddress), completionHandler: { (response) in
                switch response.result{
                case .success(let person):
                    self.messageWithPerson(person[0])
                    break
                case .failure(_):
                    self.showNoPersonAlertView()
                }
            })
        }
    }

    public func messageWithPerson( _ person: Person){
        UserDefaultsUtil.addMessagePersonHistory(person)
        let activityDetailVC = SpaceDetailViewController()
        activityDetailVC.emailAddress =  person.emails?.first?.toString()
        activityDetailVC.webexSDK = self.webexSDK
        self.navigationController?.pushViewController(activityDetailVC, animated: true)
    }
    
    public func messageWithSpace( _ spaceModel: Space?){
        if let space = spaceModel{
            let activityDetailVC = SpaceDetailViewController()
            activityDetailVC.spaceModel = space
            activityDetailVC.webexSDK = self.webexSDK
            self.navigationController?.pushViewController(activityDetailVC, animated: true)
        }
    }
    private func showNoPersonAlertView(){
        let alert = UIAlertController(title: "Can not find person", message: self.messageEmailTextField?.text!, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // MARK: UItableView datadataSource
    private func setUpHistoryTableView(){
        self.historyResult = UserDefaultsUtil.meesagePersonHistory
        self.historyResult.reverse()
        if self.historyTableView == nil{
            self.historyTableView = UITableView(frame:  CGRect(x: 0.0, y: 0.0, width: kScreenWidth, height: kScreenHeight-kNavHeight), style: .plain)
            self.historyTableView?.showsVerticalScrollIndicator = false
            self.historyTableView?.separatorStyle = .none
            self.historyTableView?.dataSource = self
            self.historyTableView?.delegate = self
            self.backView?.addSubview(self.historyTableView!)
        }
        self.backView?.bringSubview(toFront: self.historyTableView!)
        self.historyTableView?.reloadData()
    }
    
    private func setUpSearchTableView(){
        if self.searchTableView == nil{
            // search controller setup
            self.searchBar.sizeToFit()
            self.searchBar.isTranslucent = false
            self.searchBar.placeholder = "Email or User name"
            self.searchBar.searchBarStyle = .default
            self.searchBar.delegate = self
            self.searchBar.returnKeyType = .done
            
            self.searchTableView = UITableView(frame:  CGRect(x: 0.0, y: 0.0, width: kScreenWidth, height: kScreenHeight-kNavHeight), style: .plain)
            self.searchTableView?.showsVerticalScrollIndicator = false
            self.searchTableView.separatorStyle = .none
            self.searchTableView?.dataSource = self
            self.searchTableView?.delegate = self
        
            self.backView?.addSubview(self.searchTableView!)
        }
        self.searchTableView?.addSubview(self.indicatorView)
        self.indicatorView.center = (self.searchTableView?.center)!
        self.backView?.bringSubview(toFront: self.searchTableView!)
        self.searchBar.becomeFirstResponder()
        self.searchTableView?.reloadData()
    }

    private func setUpMessageEmailView(){
        if self.messageEmailBackView == nil{
            self.messageEmailBackView = UIView(frame:  CGRect(x: 0.0, y: 0.0, width: kScreenWidth, height: kScreenHeight))
            self.messageEmailBackView?.backgroundColor = UIColor.white
            self.messageEmailTextField = UITextField(frame: CGRect(x: 20.0, y: 20.0, width: kScreenWidth-40, height: 50))
            self.messageEmailTextField?.layer.cornerRadius = 5.0
            self.messageEmailTextField?.layer.borderWidth = 0.5
            self.messageEmailTextField?.layer.borderColor = UIColor.lightGray.cgColor
            self.messageEmailTextField?.layer.masksToBounds = true
            self.messageEmailTextField?.placeholder = "Email For Message"
            self.messageEmailTextField?.textAlignment = .center
            self.messageEmailTextField?.font = UIFont.textViewLightFont(ofSize: 20 * Utils.HEIGHT_SCALE)
            self.messageEmailBackView?.addSubview(self.messageEmailTextField!)
            self.backView?.addSubview(messageEmailBackView!)
            
            // message button
            let messageButton = UIButton(frame: CGRect(x: kScreenWidth/2-40, y: kScreenHeight/2-80, width: 80*Utils.HEIGHT_SCALE, height: 80*Utils.HEIGHT_SCALE))
            messageButton.setImage(UIImage.fontAwesomeIcon(name: .commenting, textColor: UIColor.white, size: CGSize.init(width: 48*Utils.WIDTH_SCALE , height: 32)), for: .normal)
            messageButton.setImage(UIImage.fontAwesomeIcon(name: .commenting, textColor: UIColor.gray, size: CGSize.init(width: 48*Utils.WIDTH_SCALE , height: 32)), for: .highlighted)
            messageButton.backgroundColor = UIColor.buttonGreenNormal()
            messageButton.layer.cornerRadius = (80*Utils.HEIGHT_SCALE)/2
            messageButton.addTarget(self, action:#selector(messageToEmailButtonClicked), for: .touchUpInside)
            self.messageEmailBackView?.addSubview(messageButton)
        }
        self.backView?.bringSubview(toFront: self.messageEmailBackView!)
        self.messageEmailTextField?.becomeFirstResponder()
    }
    
    private func setUpSpaceTableView(){
        if self.spaceTableView == nil{
            self.spaceTableView = UITableView(frame:  CGRect(x: 0.0, y: 0.0, width: kScreenWidth, height: kScreenHeight-kNavHeight), style: .plain)
            self.spaceTableView?.showsVerticalScrollIndicator = false
            self.spaceTableView?.separatorStyle = .none
            self.spaceTableView?.dataSource = self
            self.spaceTableView?.delegate = self
            self.backView?.addSubview(self.spaceTableView!)
            
            self.createSpaceButton = UIButton(frame: CGRect(x: kScreenWidth/2-40, y: kScreenHeight-kNavHeight*2-80, width: 80, height: 80))
            self.createSpaceButton?.setImage(UIImage.fontAwesomeIcon(name: .plus, textColor: UIColor.white, size: CGSize.init(width: 50*Utils.WIDTH_SCALE , height: 50*Utils.WIDTH_SCALE)), for: .normal)
            self.createSpaceButton?.setImage(UIImage.fontAwesomeIcon(name: .plus, textColor: UIColor.gray, size: CGSize.init(width: 50*Utils.WIDTH_SCALE , height: 50*Utils.WIDTH_SCALE)), for: .highlighted)
            self.createSpaceButton?.backgroundColor = UIColor.buttonGreenNormal()
            self.createSpaceButton?.addTarget(self, action: #selector(createSpaceBtnClicked), for: .touchUpInside)
            self.createSpaceButton?.layer.cornerRadius = 40.0
            self.createSpaceButton?.layer.masksToBounds = true
            self.backView?.addSubview(self.createSpaceButton!)
        }
        self.spaceTableView?.addSubview(self.indicatorView)
        self.indicatorView.center = (self.spaceTableView?.center)!
        self.requestWebexSpaceList()
        self.backView?.bringSubview(toFront: self.spaceTableView!)
        self.backView?.bringSubview(toFront: self.createSpaceButton!)
        self.spaceTableView?.reloadData()
    }

    // MARK: table view delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
    
        switch self.currentSegType
        {
        case .history:
            return self.historyResult.count
        case .search:
            return self.searchResult.count
        case .space:
            return self.spaceResult.count
        case .email:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        if(tableView == self.searchTableView || tableView == self.historyTableView){
            var cell = tableView.dequeueReusableCell(withIdentifier: "MessagePersonCell") as? MessagePersonCell
            if cell == nil{
                cell = MessagePersonCell(style: .default, reuseIdentifier: "MessagePersonCell")
            }
            let dataSource: [Person]?
            if tableView == self.searchTableView {
                dataSource = searchResult
            }else {
                dataSource = historyResult
            }
            let person = dataSource?[indexPath.row]
            cell?.updateWithPersonModel(person)
            cell?.spaceListVC = self
            return cell!
        }else{
            var cell = tableView.dequeueReusableCell(withIdentifier: "MessageSpaceCell") as? MessageSpaceCell
            if cell == nil{
                cell = MessageSpaceCell(style: .default, reuseIdentifier: "MessageSpaceCell")
            }
            let dataSource: [Space]?
            dataSource = spaceResult
            let space = dataSource?[indexPath.row]
            cell?.updateWithSpace(space)
            cell?.spaceListVC = self
            return cell!
        }

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight * Utils.HEIGHT_SCALE
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if(tableView == self.searchTableView){
            return self.searchBar
        }
        return nil
        
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(tableView == self.searchTableView){
            return 40
        }
        return 0
    }
    
    // MARK: search bar result updating delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchString = self.searchBar.text!
        if searchString.count < 3 {
            searchResult.removeAll()
            self.searchTableView.reloadData()
            return
        }
        indicatorView.startAnimating()
        self.webexFetchPersonProfilesWithEmail(searchStr: searchString)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }
    
    // MARK: create sapce button clicked
    @objc private func createSpaceBtnClicked(){
        let createSpaceVC = CreateGroupViewControlller()
        createSpaceVC.webexSDK = self.webexSDK
        createSpaceVC.spaceCreatedBlock = { space in
            self.spaceResult.insert(space, at: 0)
            self.spaceTableView?.reloadData()
        }
        self.navigationController?.pushViewController(createSpaceVC, animated: true)
    }
    
    override func dissmissKeyboard() {
        super.dissmissKeyboard()
        self.searchBar.endEditing(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.searchBar.resignFirstResponder()
        self.messageEmailTextField?.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
