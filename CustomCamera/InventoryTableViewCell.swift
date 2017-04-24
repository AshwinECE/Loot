//
//  InventoryTableViewCell.swift
//  CustomCamera
//
//  Created by It's Happen Inc. on 2016-06-06.
//  Copyright © 2016 It's Happen Inc. All rights reserved.
//

import UIKit

class InventoryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lootItemThumbnailImageView: UIImageView!
    
    @IBOutlet weak var lootedAtTimeTextLabel: UILabel!
    
    @IBOutlet weak var likeCounterTextLabel: UILabel!
    
    @IBOutlet weak var locationButton: LocationButton!
    
    @IBAction func locationButtonDidTouch(_ sender: AnyObject) {
        locationButton.setImage(UIImage(named: "active-center-button"), for: .normal)
    }
    @IBOutlet weak var captionTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.lootItemThumbnailImageView.layer.cornerRadius = self.lootItemThumbnailImageView.frame.width/35.0
        self.lootItemThumbnailImageView.layer.masksToBounds = true
        
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
