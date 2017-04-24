//
//  InventoryTableViewController.swift
//  CustomCamera
//
//  Created by It's Happen Inc. on 2016-06-06.
//  Copyright © 2016 It's Happen Inc. All rights reserved.
//

import UIKit
import RealmSwift
import Firebase
import AVKit
import AVFoundation

class InventoryTableViewController: UITableViewController{
 
    var tappedLootItem = LootItem()
    
    
    var inventoryLoot = try! Realm().objects(LootItem.self)
    var tempToday:[String] = []
    var tempYesterday:[String] = []
    var tempOld:[String] = []
    
    var todaysLoot:[String] = []
    var yesterdaysLoot:[String] = []
    var oldLoot: [String] = []
    
    var todaysMediaLoot: [UIImage] = []
    var yesterdaysMediaLoot: [UIImage] = []
    var oldMediaLoot: [UIImage] = []
    
    
    var fromInventory = true
    
    var ref: FIRDatabaseReference!

    
    
    
    var image = UIImage()
    


    deinit{
        ref.removeAllObservers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()

         NotificationCenter.default.addObserver(self, selector: #selector(InventoryTableViewController.reloadAllData), name: NSNotification.Name(rawValue: "reloadInventoryTable"), object: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        initializeNavigationBar()
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async(execute: {
            self.sortByDate()
            DispatchQueue.main.sync(execute: {
                self.todaysLoot = self.tempToday
                self.yesterdaysLoot = self.tempYesterday
                self.oldLoot = self.tempOld

                self.tableView.reloadData()
            });
        });
        
        
    }
    
    //MARK: This makes sure that the cells don't get hidden underneath the tab bar or navigation bar
    override func viewDidLayoutSubviews() {
        self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, (self.bottomLayoutGuide.length), 0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if (section == 0){
            return todaysLoot.count
        }
        else if (section == 1){
            return yesterdaysLoot.count
        }
        else{
            return oldLoot.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "inventoryCell", for: indexPath) as! InventoryTableViewCell
        
        
        //Today's loot section
        if ((indexPath as NSIndexPath).section == 0){
            let currentLootItem = inventoryLoot.filter("itemID == %@", todaysLoot[(indexPath as NSIndexPath).row])
            
            
            cell.lootedAtTimeTextLabel.text = currentLootItem[0].lootedAt
            cell.lootItemThumbnailImageView.image = todaysMediaLoot[(indexPath as NSIndexPath).row]
            cell.locationButton.addTarget(self, action: #selector(locationButtonTouched(sender:)), for: UIControlEvents.touchUpInside)
            cell.locationButton.indexRow = (indexPath as NSIndexPath).row
            cell.locationButton.sectionNumber = 0
            cell.locationButton.setImage(UIImage(named: "inactive-center-button"), for: .normal)
            if (currentLootItem[0].hasCaption){
                cell.captionTextLabel.text = currentLootItem[0].caption
            }else{
                cell.captionTextLabel.text = ""
            }
            
            ref.root.child("MetaData").child(currentLootItem[0].itemID).observeSingleEvent(of: .value, with: { (snapshot)in
                // Get user value
                
                let postDict = snapshot.value as! [String : AnyObject]
                
                let likes = (postDict["likes"]!) as! Int
                
                cell.likeCounterTextLabel.text = String(likes)
                
            }) { (error) in
                
            }
            
        }
        else if ((indexPath as NSIndexPath).section == 1){
            let currentLootItem = inventoryLoot.filter("itemID == %@", yesterdaysLoot[(indexPath as NSIndexPath).row])
            
            
            cell.lootedAtTimeTextLabel.text = currentLootItem[0].lootedAt
            cell.lootItemThumbnailImageView.image = yesterdaysMediaLoot[(indexPath as NSIndexPath).row]
            cell.locationButton.addTarget(self, action: #selector(locationButtonTouched(sender:)), for: UIControlEvents.touchUpInside)
            cell.locationButton.indexRow = (indexPath as NSIndexPath).row
            cell.locationButton.sectionNumber = 1
            cell.locationButton.setImage(UIImage(named: "inactive-center-button"), for: .normal)
            if (currentLootItem[0].hasCaption){
                cell.captionTextLabel.text = currentLootItem[0].caption
            }else{
                cell.captionTextLabel.text = ""
            }
            
            ref.root.child("MetaData").child(currentLootItem[0].itemID).observeSingleEvent(of: .value, with: { (snapshot)in
                // Get user value
                
                let postDict = snapshot.value as! [String : AnyObject]
                
                
                let likes = (postDict["likes"]!) as! Int
                
                cell.likeCounterTextLabel.text = String(likes)
                
                
            }) { (error) in
                
            }

        }
        else if ((indexPath as NSIndexPath).section == 2){
            let currentLootItem = inventoryLoot.filter("itemID == %@", oldLoot[(indexPath as NSIndexPath).row])
            
            
            cell.lootedAtTimeTextLabel.text = currentLootItem[0].lootedAt
            cell.lootItemThumbnailImageView.image = oldMediaLoot[(indexPath as NSIndexPath).row]
            cell.locationButton.addTarget(self, action: #selector(locationButtonTouched(sender:)), for: UIControlEvents.touchUpInside)
            cell.locationButton.indexRow = (indexPath as NSIndexPath).row
            cell.locationButton.sectionNumber = 2
            cell.locationButton.setImage(UIImage(named: "inactive-center-button"), for: .normal)
            if (currentLootItem[0].hasCaption){
                cell.captionTextLabel.text = currentLootItem[0].caption
            }else{
                cell.captionTextLabel.text = ""
            }
            
            ref.root.child("MetaData").child(currentLootItem[0].itemID).observeSingleEvent(of: .value, with: { (snapshot)in
                // Get user value
                
                let postDict = snapshot.value as! [String : AnyObject]
                
                let likes = (postDict["likes"]!) as! Int
                
                cell.likeCounterTextLabel.text = String(likes)
                
            }) { (error) in
                
            }

        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85.0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0){
            return "Today"
        }
        else if (section == 1){
            return "Yesterday"
        }
        else{
            return "Way Back"
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            let realm = try! Realm()
            if((indexPath as NSIndexPath).section == 0){
                try! realm.write(){
                    let temp = inventoryLoot.filter("itemID == %@", todaysLoot[(indexPath as NSIndexPath).row])
                    tappedLootItem = temp[0]
                    tappedLootItem.lootedAt = "NOTLOOTED"
                }
                todaysLoot.remove(at: (indexPath as NSIndexPath).row)
                tempToday.remove(at: (indexPath as NSIndexPath).row)
                todaysMediaLoot.remove(at: (indexPath as NSIndexPath).row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
            }else if ((indexPath as NSIndexPath).section == 1){
                // handle delete (by removing the data from your array and updating the tableview)
                    try! realm.write(){
                        let temp = inventoryLoot.filter("itemID == %@", yesterdaysLoot[(indexPath as NSIndexPath).row])
                        tappedLootItem = temp[0]
                        tappedLootItem.lootedAt = "NOTLOOTED"
                    }
                    yesterdaysLoot.remove(at: (indexPath as NSIndexPath).row)
                    tempYesterday.remove(at: (indexPath as NSIndexPath).row)
                    yesterdaysMediaLoot.remove(at: (indexPath as NSIndexPath).row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                
            }else if ((indexPath as NSIndexPath).section == 2){
                // handle delete (by removing the data from your array and updating the tableview)
                    try! realm.write(){
                        let temp = inventoryLoot.filter("itemID == %@", oldLoot[(indexPath as NSIndexPath).row])
                        tappedLootItem = temp[0]
                        tappedLootItem.lootedAt = "NOTLOOTED"
                    }
                    oldLoot.remove(at: (indexPath as NSIndexPath).row)
                    tempOld.remove(at: (indexPath as NSIndexPath).row)
                    oldMediaLoot.remove(at: (indexPath as NSIndexPath).row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    //MARK: Segue to fullscreen
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if ((indexPath as NSIndexPath).section == 0){
            let temp = inventoryLoot.filter("itemID == %@", todaysLoot[(indexPath as NSIndexPath).row])
            tappedLootItem = temp[0]
            
            performSegue(withIdentifier: "fullscreensegue", sender: self)
        }
        else if ((indexPath as NSIndexPath).section == 1){
            let temp = inventoryLoot.filter("itemID == %@", yesterdaysLoot[(indexPath as NSIndexPath).row])
            tappedLootItem = temp[0]
            
            performSegue(withIdentifier: "fullscreensegue", sender: self)
        }
        else {
            let temp = inventoryLoot.filter("itemID == %@", oldLoot[(indexPath as NSIndexPath).row])
            tappedLootItem = temp[0]
            
            performSegue(withIdentifier: "fullscreensegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "fullscreensegue"){
            if let imageDisplayView = segue.destination as? ImageDisplayViewController{
                imageDisplayView.imgString = readFromImageFile(tappedLootItem.itemID)
                imageDisplayView.captionString = tappedLootItem.caption
                
            }
        }
        
    }
    
    
    //Unwinder
    @IBAction func unwindToInventory(_ segue: UIStoryboardSegue){
        
    }

    //MARK: Initializers
    func initializeNavigationBar(){
        self.navigationController?.navigationBar.topItem?.title = "Inventory"
        self.navigationController?.isNavigationBarHidden = false
    }
    
    func reloadAllData(){
        tableView.reloadData()
    }
    
    //MARK: Location button functionality
    func locationButtonTouched(sender: LocationButton){
        let indexRow = sender.indexRow
        let section = sender.sectionNumber
        
        var lootItemToSendToMap = LootItem()
        
        if section == 0{
            let lootItem = inventoryLoot.filter("itemID == %@", todaysLoot[indexRow])
            lootItemToSendToMap = lootItem[0]
        }
        else if section == 1{
            let lootItem = inventoryLoot.filter("itemID == %@", yesterdaysLoot[indexRow])
            lootItemToSendToMap = lootItem[0]
        }
        else if section == 2{
            let lootItem = inventoryLoot.filter("itemID == %@", oldLoot[indexRow])
            lootItemToSendToMap = lootItem[0]
        }
        
        let key:NSObject = "key" as NSObject
        
        let dictionaryToPassLoot = [key:lootItemToSendToMap]
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "passLocationLootBack"), object: nil, userInfo: dictionaryToPassLoot)
        
        performSegue(withIdentifier: "unwindtomapfrominventory", sender: self)
    }
    
    //MARK: Image display functions
    func displayImage(_ lootItemToDisplay: LootItem)->UIImage{
        
        if(lootItemToDisplay.mediatype == "Picture"){
            let imageFile = readFromImageFile(lootItemToDisplay.itemID)
            let imageFileURL = URL(fileURLWithPath: imageFile)
            let data = try? Data(contentsOf: imageFileURL)
            let image = UIImage(data: data!)
        
            self.image = image!
        }
        
        return image
    }
    func readFromImageFile(_ itemID: String) -> String{
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                           .userDomainMask, true)
        let documentsDirectory = dirPaths[0]
        
        let fileName = itemID
        
        let finalFilePath = "\(documentsDirectory)/\(fileName).png"
        
        return finalFilePath
    }


    

    //MARK: Sorting loot by dates
    func sortByDate() {
        
        let realm = try! Realm()
        
        let lootItems = realm.objects(LootItem.self).filter("lootedAt != 'NOTLOOTED'")
        
        for lootItem in lootItems{
            //Swith the string to NSDate format for sorting purposes
            let date = stringToDate(lootItem.lootedAt)
            let calendar = Calendar.current
            if (calendar.isDateInToday(date)){
                if (tempToday as NSArray).contains(lootItem.itemID){
                    //already saved
                }
                else{
                    tempToday.insert(lootItem.itemID, at: 0)
                    todaysMediaLoot.insert(displayImage(lootItem), at: 0)

                }
            }
            else if (calendar.isDateInYesterday(date)){
                if (tempYesterday as NSArray).contains(lootItem.itemID){
                    //already saved
                }
                else{
                    tempYesterday.insert(lootItem.itemID, at: 0)
                    yesterdaysMediaLoot.insert(displayImage(lootItem), at: 0)
                }
            }
            else {
                if (tempOld as NSArray).contains(lootItem.itemID){
                    //already saved
                }
                else{
                    tempOld.insert(lootItem.itemID, at: 0)
                    oldMediaLoot.insert(displayImage(lootItem), at: 0)
                }
            }
        }

    }
    
    //Helper function to order loot
    func stringToDate(_ stringToConvert: String) -> Date{
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        
        return (dateFormatter.date(from: stringToConvert))!
    }
}
