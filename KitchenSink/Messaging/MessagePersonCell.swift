//
//  MessagePersonCell.swift
//  KitchenSink
//
//  Created by qucui on 2018/1/29.
//  Copyright 2016-2019 Cisco Systems Inc. All rights reserved.
//

import UIKit
import WebexSDK

class MessagePersonCell: UITableViewCell {

    public var personModel: Person?
    private var avatarImageView: UIImageView!
    private var nameLabel: UILabel!
    var messageButton: UIButton!
    private var line: CALayer?
    var spaceListVC: SpaceListViewController!
    
    // update UI after refreshing
    public func updateWithPersonModel(_ personModel: Person?){
        self.personModel = personModel
        if(self.avatarImageView == nil){
            self.avatarImageView = UIImageView(frame: CGRect(x: 20, y: 10*Utils.HEIGHT_SCALE, width: 80*Utils.HEIGHT_SCALE, height: 80*Utils.HEIGHT_SCALE))
            self.avatarImageView.layer.cornerRadius = (80*Utils.HEIGHT_SCALE)/2
            self.avatarImageView.layer.masksToBounds = true
            self.addSubview(self.avatarImageView!)
        }
        self.avatarImageView.image = UIImage(named: "DefaultAvatar")
        Utils.downloadAvatarImage(self.personModel?.avatar, completionHandler: {
            self.avatarImageView.image = $0
        })
        
        if(self.nameLabel == nil){
            self.nameLabel = UILabel(frame: CGRect(x: 30+80*Utils.HEIGHT_SCALE, y: 0, width: kScreenWidth-110-80*Utils.HEIGHT_SCALE, height: cellHeight*Utils.HEIGHT_SCALE))
            self.addSubview(self.nameLabel!)
        }
        self.nameLabel.text = self.personModel?.displayName
        
        if(self.messageButton == nil){
            self.messageButton = UIButton(frame: CGRect(x: kScreenWidth-70, y: 26*Utils.HEIGHT_SCALE, width: 48*Utils.HEIGHT_SCALE, height: 48*Utils.HEIGHT_SCALE))
            self.messageButton.setImage(UIImage.fontAwesomeIcon(name: .commentDots, textColor: UIColor.white, size: CGSize.init(width: 32*Utils.WIDTH_SCALE , height: 32*Utils.WIDTH_SCALE)), for: .normal)
            self.messageButton.setImage(UIImage.fontAwesomeIcon(name: .commentDots, textColor: UIColor.gray, size: CGSize.init(width: 32*Utils.WIDTH_SCALE , height: 32*Utils.WIDTH_SCALE)), for: .highlighted)
            self.messageButton.backgroundColor = UIColor.buttonGreenNormal()
            self.messageButton.layer.cornerRadius = (48*Utils.HEIGHT_SCALE)/2
            self.messageButton.addTarget(self, action: #selector(message), for: .touchUpInside)
            self.addSubview(self.messageButton)
        }
        
        if(self.line == nil){
            self.line = CALayer()
            self.line?.frame = CGRect(x: 25, y: cellHeight*Utils.HEIGHT_SCALE - 0.5, width: kScreenWidth-25, height: 0.5)
            self.line?.backgroundColor = UIColor.lightGray.cgColor
            self.layer.addSublayer(self.line!)
        }
    }

    @objc func message(_ sender: UIButton) {
        if let model = self.personModel{
            UserDefaultsUtil.addMessagePersonHistory(self.personModel!)
            spaceListVC.messageWithPerson(model)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
