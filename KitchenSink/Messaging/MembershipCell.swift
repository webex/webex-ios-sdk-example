//
//  MembershipCell.swift
//  KitchenSink
//
//  Created by qucui on 2018/1/24.
//  Copyright © 2018年 Cisco Systems, Inc. All rights reserved.
//

import UIKit
import WebexSDK
class MembershipCell: UITableViewCell {
    public var membershipModel: Membership?
    private var membershipTitleLabel : UILabel?
    
    public func updateWithMembership(_ membershipModel: Membership?){
        self.membershipModel = membershipModel
        if(self.membershipTitleLabel == nil){
            self.membershipTitleLabel = UILabel(frame: CGRect(x: 15, y: 0, width: kScreenWidth-15, height: 50))
            self.addSubview(self.membershipTitleLabel!)
        }
        self.membershipTitleLabel?.text = (self.membershipModel?.personDisplayName)!
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
