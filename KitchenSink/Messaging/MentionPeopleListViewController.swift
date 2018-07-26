//
//  MentionPeopleListViewController.swift
//  KitchenSink
//
//  Created by qucui on 2018/1/24.
//  Copyright © 2018年 Cisco Systems, Inc. All rights reserved.
//

import UIKit
import WebexSDK
class MentionPeopleListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    fileprivate var indicatorView: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    fileprivate var tableView: UITableView!
    fileprivate var membershipResult: [Membership] = [Membership]()
    
    public var spaceId: String?
    public var completionBlock: ((Membership?)->Void)?
    /// saparkSDK reperesent for the WebexSDK API instance
    var webexSDK: Webex?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.title = "MemberShipList"
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        let addButton: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissVC))
        self.navigationItem.rightBarButtonItem = addButton
        self.setupView()
        self.requestMemberShipList()
        // Do any additional setup after loading the view.
    }
    

    // MARK: - WebexSDK: list Memberships
    private func requestMemberShipList(){
        self.indicatorView.startAnimating()
        self.webexSDK?.memberships.list(spaceId: self.spaceId!, completionHandler: { (response: ServiceResponse<[Membership]>) in
            self.indicatorView.stopAnimating()
            switch response.result {
            case .success(let value):
                self.membershipResult.removeAll()
                self.membershipResult = value
            case .failure:
                break
            }
            self.refreshTableView()
        })
    }

    // MARK: UI Implementation
    @objc public func dismissVC(){
        if let completionBlock = self.completionBlock{
            completionBlock(nil)
        }
    }
    public func setupView(){
        tableView = UITableView(frame:  CGRect(x: 0.0, y: 0.0, width: kScreenWidth, height: kScreenHeight+35), style: .grouped)
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionHeaderHeight = 0.5
        tableView.contentInset = UIEdgeInsets(top: -35, left: 0, bottom: 0, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        self.tableView.addSubview(self.indicatorView)
        self.indicatorView.center = self.view.center
        self.view.addSubview(tableView!)
    }
    
    private func refreshTableView(){
        self.tableView.reloadData()
    }
    
    
    // MARK: UItableView datadataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return self.membershipResult.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCell(withIdentifier: "MembershipCell") as? MembershipCell
        if cell == nil{
            cell = MembershipCell(style: .default, reuseIdentifier: "MembershipCell")
        }
        let dataSource: [Membership]?
        dataSource = membershipResult
        let membership = dataSource?[indexPath.row]
        cell?.updateWithMembership(membership)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let completionBlock = self.completionBlock{
            let memberShip = self.membershipResult[indexPath.row]
            completionBlock(memberShip)
        }
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
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
