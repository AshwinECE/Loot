//
//  MyLootTableViewCell.swift
//  CustomCamera
//
//  Created by It's Happen Inc. on 2016-06-10.
//  Copyright © 2016 It's Happen Inc. All rights reserved.
//

import UIKit

class MyLootTableViewCell: UITableViewCell {

    @IBOutlet weak var myLootThumbnailImageView: UIImageView!
    
    @IBOutlet weak var timeDroppedTextLabel: UILabel!
    
    @IBOutlet weak var likeCounterTextLabel: UILabel!
    
    @IBOutlet weak var captionTextLabel: UILabel!
    
    @IBOutlet weak var locationButton: LocationButton!
    
    @IBAction func locationButtonDidTouch(_ sender: AnyObject) {
        locationButton.setImage(UIImage(named:"active-center-button"), for: .normal)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.myLootThumbnailImageView.layer.cornerRadius = self.myLootThumbnailImageView.frame.width/35.0
        self.myLootThumbnailImageView.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
