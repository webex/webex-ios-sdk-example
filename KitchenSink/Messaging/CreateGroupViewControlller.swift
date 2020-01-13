//
//  CreateGroupViewControlller.swift
//  KitchenSink
//
//  Created by qucui on 2018/1/31.
//  Copyright 2016-2019 Cisco Systems Inc. All rights reserved.
//

import UIKit
import WebexSDK

class CreateGroupViewControlller: BaseViewController ,UITextFieldDelegate ,UISearchBarDelegate,UITableViewDelegate,UITableViewDataSource{
    fileprivate var indicatorView: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)

    fileprivate var spaceNameTextFeild: UITextField?
    fileprivate var searchBar : UISearchBar?
    fileprivate var searchResult: [Person] = [Person]()
    fileprivate var searchTableView: UITableView!
    fileprivate var selectedPersonList: [Person] = [Person]()
    fileprivate var selectedPersonTableView: UITableView!
    public var spaceCreatedBlock: ((Space)->Void)?
    
    /// saparkSDK reperesent for the WebexSDK API instance
    var webexSDK: Webex?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "New Space"
        self.setUpNavigation()
        self.setUpSubView()
        // Do any additional setup after loading the view.
    }
    
    
    // MARK: - WebexSDK: search people with Email/SearchString
    private func webexFetchPersonProfilesWithEmail(searchStr: String){
        if let email = EmailAddress.fromString(searchStr) {
            /* Lists people with email address in the authenticated user's organization. */
            self.webexSDK?.people.list(email: email, max: 10) {
                (response: ServiceResponse<[Person]>) in
                switch response.result {
                case .success(let value):
                    self.searchResult = value
                case .failure:
                    self.searchResult.removeAll()
                }
                self.setUpSearchResultTable()
                if searchStr == self.searchBar?.text! {
                    self.searchTableView.reloadData()
                }
            }
        } else {
            /* Lists people with display name in the authenticated user's organization. */
            self.webexSDK?.people.list(displayName: searchStr, max: 10) {
                (response: ServiceResponse<[Person]>) in
                switch response.result {
                case .success(let value):
                    self.searchResult = value
                case .failure:
                    self.searchResult.removeAll()
                }
                self.setUpSearchResultTable()
                if searchStr == self.searchBar?.text! {
                    self.searchTableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - WebexSDK: Create Webex Space
    public func createNewSpace(){
        var spaceTitle = ""
        if let title = self.spaceNameTextFeild?.text{
            spaceTitle = title
        }
        self.view?.addSubview(self.indicatorView)
        self.indicatorView.center = (self.view?.center)!
        self.webexSDK?.spaces.create(title: spaceTitle) { (response: ServiceResponse<Space>) in
            switch response.result {
            case .success(let value):
                let threahGroup = DispatchGroup()
                // after creating space, let selectedPersons add into new space
                for person in self.selectedPersonList{
                    DispatchQueue.global().async(group: threahGroup, execute: {
                        self.webexSDK?.memberships.create(spaceId: value.id!, personEmail:(person.emails?.first)!, completionHandler: { (response: ServiceResponse<Membership>) in
                            switch response.result{
                            case .success(_):
                                break
                            case .failure(_):
                                break
                            }
                        })
                    })
                }
                
                threahGroup.notify(queue: DispatchQueue.global(), execute: {
                    DispatchQueue.main.async {
                        if(self.spaceCreatedBlock != nil){
                            self.spaceCreatedBlock!(value)
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                })
                break
            case .failure(_):
                break
            }
        }
    }

    // MARK: - UI Implementation
    func setUpNavigation(){
        let nextButton = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 44, height: 44))
        nextButton.setTitle("Done", for: .normal)
        nextButton.setTitleColor(UIColor.blue, for: .normal)
        nextButton.addTarget(self, action: #selector(createSpace), for: .touchUpInside)
        
        let rightView = UIView.init(frame:CGRect.init(x: 0, y: 0, width: 44, height: 44))
        rightView.addSubview(nextButton)
        let rightButtonItem = UIBarButtonItem.init(customView: rightView)
        
        let fixBarSpacer = UIBarButtonItem.init(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixBarSpacer.width = -10 * (2 - Utils.WIDTH_SCALE)
        navigationItem.rightBarButtonItems = [fixBarSpacer,rightButtonItem]
    }
    
    @objc private func createSpace(){
        if self.selectedPersonList.count == 0{
            let alert = UIAlertController(title: "Alert", message: "Need At Least One Member", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        if let text = self.spaceNameTextFeild?.text{
            if text == ""{
                let alert = UIAlertController(title: "Alert", message: "Space Name Needed", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
                return
            }
        }else{
            let alert = UIAlertController(title: "Alert", message: "Space Name Needed", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        self.createNewSpace()
    }
    
    private func setUpSubView(){
        self.view.backgroundColor = UIColor.white
        
        self.spaceNameTextFeild = UITextField(frame: CGRect(x: 20, y: 20, width: kScreenWidth-40, height: 40))
        self.spaceNameTextFeild?.layer.cornerRadius = 5.0
        self.spaceNameTextFeild?.layer.borderWidth = 0.5
        self.spaceNameTextFeild?.layer.borderColor = UIColor.lightGray.cgColor
        self.spaceNameTextFeild?.layer.masksToBounds = true
        self.spaceNameTextFeild?.placeholder = "Space Name"
        self.spaceNameTextFeild?.textAlignment = .center
        self.spaceNameTextFeild?.font = UIFont.textViewLightFont(ofSize: 20 * Utils.HEIGHT_SCALE)
        self.spaceNameTextFeild?.delegate = self
        self.view.addSubview(self.spaceNameTextFeild!)
        
        self.searchBar = UISearchBar(frame: CGRect(x: 10, y: 60, width: kScreenWidth-20, height: 44))
        self.searchBar?.sizeToFit()
        self.searchBar?.isTranslucent = false
        self.searchBar?.showsCancelButton = true
        self.searchBar?.placeholder = "Email or User name"
        self.searchBar?.searchBarStyle = .minimal
        self.searchBar?.delegate = self
        self.searchBar?.returnKeyType = .default
        self.searchBar?.enablesReturnKeyAutomatically = false
        self.view.addSubview(self.searchBar!)
        
        self.setUpSelectedPersonTableView()
    }
    
    private func setUpSelectedPersonTableView(){
        if self.selectedPersonTableView == nil{
            self.selectedPersonTableView = UITableView(frame:  CGRect(x: 0.0, y: 105, width: kScreenWidth, height: kScreenHeight-kNavHeight-100), style: .plain)
            self.selectedPersonTableView.backgroundColor = UIColor.white
            self.selectedPersonTableView?.showsVerticalScrollIndicator = false
            self.selectedPersonTableView?.separatorStyle = .none
            self.selectedPersonTableView?.dataSource = self
            self.selectedPersonTableView?.delegate = self
            self.view.addSubview(self.selectedPersonTableView!)
        }
        self.view.bringSubviewToFront(self.selectedPersonTableView)
        self.selectedPersonTableView?.reloadData()
    }
    
    private func setUpSearchResultTable(){
        if self.searchTableView == nil {
            self.searchTableView = UITableView(frame:  CGRect(x: 0.0, y: 105, width: kScreenWidth, height: kScreenHeight-kNavHeight-100), style: .plain)
            self.searchTableView.backgroundColor = UIColor.white
            self.searchTableView?.showsVerticalScrollIndicator = false
            self.searchTableView?.separatorStyle = .none
            self.searchTableView?.dataSource = self
            self.searchTableView?.delegate = self
            self.searchTableView.backgroundColor = UIColor.gray
            self.view.addSubview(self.searchTableView)
        }
        searchTableView.isHidden = false
        self.view.bringSubviewToFront(self.searchTableView)
        self.searchTableView?.reloadData()
    }
    
    // MARK: search bar result updating delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let searchString = self.searchBar?.text! else{
            return
        }
        if searchString.count < 3 {
            searchResult.removeAll()
            if let searchT = self.searchTableView{
                searchT.reloadData()
            }
            return
        }
        self.webexFetchPersonProfilesWithEmail(searchStr: searchString)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar?.resignFirstResponder()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar?.resignFirstResponder()
        super.dissmissKeyboard()
        self.setUpSelectedPersonTableView()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.spaceNameTextFeild?.resignFirstResponder()
        return true
    }
    
    // MARK: table view delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if tableView == self.searchTableView{
            return self.searchResult.count
        }else{
            return self.selectedPersonList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        if(tableView == self.searchTableView){
            var cell = tableView.dequeueReusableCell(withIdentifier: "MessagePersonCell") as? MessagePersonCell
            if cell == nil{
                cell = MessagePersonCell(style: .default, reuseIdentifier: "MessagePersonCell")
            }
            let dataSource: [Person]?
            dataSource = searchResult
            
            let person = dataSource?[indexPath.row]
            cell?.updateWithPersonModel(person)
            cell?.messageButton.isHidden = true
            return cell!
        }else{
            var cell = tableView.dequeueReusableCell(withIdentifier: "SelectedPersonTableCell") as? MessagePersonCell
            if cell == nil{
                cell = MessagePersonCell(style: .default, reuseIdentifier: "SelectedPersonTableCell")
            }
            let dataSource: [Person]?
            dataSource = selectedPersonList
            
            let person = dataSource?[indexPath.row]
            cell?.updateWithPersonModel(person)
            cell?.messageButton.isHidden = true
            return cell!
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.searchTableView{
            let dataSource: [Person]?
            dataSource = searchResult
            let person = dataSource?[indexPath.row]
            if self.selectedPersonList.filter({$0.id == person?.id}).first == nil{
                self.selectedPersonList.append(person!)
            }
            self.searchBar?.text = ""
            self.searchBar?.endEditing(true)
            super.dissmissKeyboard()
            self.setUpSelectedPersonTableView()
        }else{
            self.selectedPersonList.remove(at: indexPath.row)
            self.setUpSelectedPersonTableView()
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight * Utils.HEIGHT_SCALE
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
