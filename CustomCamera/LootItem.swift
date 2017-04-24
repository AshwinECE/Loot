//
//  LootItem.swift
//  CustomCamera
//
//  Created by It's Happen Inc. on 2016-05-26.
//  Copyright © 2016 It's Happen Inc. All rights reserved.
//

import Foundation
import RealmSwift


class LootItem: Object{
    
    dynamic var itemID = ""
    dynamic var mediatype = ""
    dynamic var latitude = 0.0
    dynamic var longitude = 0.0
    dynamic var created = ""
    dynamic var cloudFlag = Bool()
    dynamic var beenLoaded = false
    dynamic var localLoot = false
    dynamic var lootedAt = "NOTLOOTED"
    dynamic var likes = 0
    dynamic var beenLiked = false
    dynamic var hasExpired = false
    dynamic var isDeleted = false
    dynamic var beenUploaded = false
    dynamic var beenSelected = false
    dynamic var hasCaption = Bool()
    dynamic var caption = ""
    
    override class func primaryKey() -> String{
        return "itemID"
    }
}
