//
//  LootItemAnnotation.swift
//  CustomCamera
//
//  Created by It's Happen Inc. on 2016-05-26.
//  Copyright © 2016 It's Happen Inc. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift

class LootItemAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var lootitem: LootItem?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, lootitem: LootItem? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.lootitem = lootitem
        
    }
    
}
