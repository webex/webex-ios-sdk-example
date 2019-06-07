//
//  MessageSpaceCell.swift
//  KitchenSink
//
//  Created by qucui on 2018/1/18.
//  Copyright 2016-2019 Cisco Systems Inc. All rights reserved.
//

import UIKit
import WebexSDK
class MessageSpaceCell: UITableViewCell {

    public var spaceModel: Space?
    private var spaceTitleLabel : UILabel?
    private var line: CALayer?
    private var messageButton : UIButton!
    var spaceListVC: SpaceListViewController!
    
    public func updateWithSpace(_ spaceModel: Space?){
        self.spaceModel = spaceModel
        if(self.spaceTitleLabel == nil){
            self.spaceTitleLabel = UILabel(frame: CGRect(x: 15.0, y: 0.0, width: kScreenWidth-80, height: cellHeight))
            self.spaceTitleLabel?.font = UIFont.labelLightFont(ofSize: 17*Utils.HEIGHT_SCALE)
            self.spaceTitleLabel?.textColor = UIColor.darkGray
            self.spaceTitleLabel?.textAlignment = .center
            self.spaceTitleLabel?.numberOfLines = 0
            self.addSubview(self.spaceTitleLabel!)
        }
        self.spaceTitleLabel?.text = (self.spaceModel?.title)!
        
        if(self.messageButton == nil){
            self.messageButton = UIButton(frame: CGRect(x: kScreenWidth-70, y: 26*Utils.HEIGHT_SCALE, width: 48*Utils.HEIGHT_SCALE, height: 48*Utils.HEIGHT_SCALE))
            self.messageButton?.setImage(UIImage.fontAwesomeIcon(name: .commenting, textColor: UIColor.white, size: CGSize.init(width: 32*Utils.WIDTH_SCALE , height: 32)), for: .normal)
            self.messageButton?.setImage(UIImage.fontAwesomeIcon(name: .commenting, textColor: UIColor.gray, size: CGSize.init(width: 32*Utils.WIDTH_SCALE , height: 32)), for: .highlighted)
            self.messageButton.backgroundColor = UIColor.buttonGreenNormal()
            self.messageButton.layer.cornerRadius = (48*Utils.HEIGHT_SCALE)/2
            self.messageButton.addTarget(self, action: #selector(message), for: .touchUpInside)
            self.addSubview(self.messageButton)
        }
        
        if(self.line == nil){
            self.line = CALayer()
            self.line?.frame = CGRect(x: 25, y: cellHeight - 0.5, width: kScreenWidth-25, height: 0.5)
            self.line?.backgroundColor = UIColor.lightGray.cgColor
            self.layer.addSublayer(self.line!)
        }
    }
    
    @objc func message(_ sender: UIButton) {
        spaceListVC.messageWithSpace(self.spaceModel)
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
