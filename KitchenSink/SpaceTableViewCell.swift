//
//  SpaceTableViewCell.swift
//  KitchenSink
//
//  Created by qucui on 2017/8/23.
//  Copyright © 2017年 Cisco Systems, Inc. All rights reserved.
//

import UIKit
import WebexSDK


class SpaceTableViewCell: UITableViewCell {

    @IBOutlet weak var spaceNameLabel: UILabel!
    @IBOutlet weak var dialButton: UIButton!
    
    @IBOutlet var heightScaleCollection: [NSLayoutConstraint]!
    
    @IBOutlet var labelFontScaleCollection: [UILabel]!
    
    @IBOutlet var widthScaleCollection: [NSLayoutConstraint]!
    
    @IBOutlet weak var onGoingLabel: UILabel!
    
    var spaceId: String?
    var spaceName: String?
    var initiateCallViewController: InitiateCallViewController!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let selector = #selector(SpaceTableViewCell.dial)
        dialButton.addTarget(self, action: selector, for: UIControl.Event.touchUpInside)
        
        
        for label in labelFontScaleCollection {
            label.font = UIFont.labelLightFont(ofSize: label.font.pointSize * Utils.HEIGHT_SCALE)
        }
        for heightConstraint in heightScaleCollection {
            heightConstraint.constant *= Utils.HEIGHT_SCALE
        }
        for widthConstraint in widthScaleCollection {
            widthConstraint.constant *= Utils.WIDTH_SCALE
        }
    }
    
    @objc func dial(_ sender: UIButton) {
        initiateCallViewController.dialSpaceWithSpaceId(spaceId!, spaceName!)
    }

    public func setOnGoingCall(_ isOnGoing:Bool) {
        onGoingLabel.isHidden = !isOnGoing
    }
    
}
