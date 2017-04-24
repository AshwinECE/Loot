//
//  MyLootTableViewController.swift
//  CustomCamera
//
//  Created by It's Happen Inc. on 2016-06-10.
//  Copyright © 2016 It's Happen Inc. All rights reserved.
//

import UIKit
import RealmSwift
import Firebase
import AVKit
import AVFoundation

class MyLootTableViewController: UITableViewController {
    
    var myLoots = try! Realm().objects(LootItem.self)
    
    var sortedMyLoot: [String] = []
    var tempSorted: [String] = []
    var sortedMyLootImages: [UIImage] = []

    
    var tappedLootItem = LootItem()
    
    
    var ref: FIRDatabaseReference!
    
    var image = UIImage()
        
    
    
    deinit{
        ref.removeAllObservers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()

        
        NotificationCenter.default.addObserver(self, selector: #selector(MyLootTableViewController.reloadAllData), name: NSNotification.Name(rawValue: "reloadMyLootTable"), object: nil)
        
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        initializeNavigationBar()
        
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async(execute: {
            self.sortByDate()
            DispatchQueue.main.sync(execute: {
                // update some UI
                self.sortedMyLoot = self.tempSorted
                self.tableView.reloadData()
            });
        });
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        self.sortedMyLoot.removeAll()
        self.tempSorted.removeAll()
        self.sortedMyLootImages.removeAll()
    }
    

    //MARK: This is to make sure that the tableview cells were not hidden behind the nav and tab bars
    override func viewDidLayoutSubviews() {
        self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, (self.bottomLayoutGuide.length), 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }

    //MARK: TableView Functions
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return sortedMyLoot.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myLootCell", for: indexPath) as! MyLootTableViewCell
        
        let currentLootItem = myLoots.filter("itemID == %@", sortedMyLoot[(indexPath as NSIndexPath).row])
        
        cell.timeDroppedTextLabel.text = currentLootItem[0].created
        cell.myLootThumbnailImageView.image = sortedMyLootImages[(indexPath as NSIndexPath).row]
        cell.locationButton.addTarget(self, action: #selector(locationButtonTouched(sender:)), for: UIControlEvents.touchUpInside)
        cell.locationButton.indexRow = indexPath.row
        cell.locationButton.setImage(UIImage(named: "inactive-center-button"), for: .normal)
        if (currentLootItem[0].hasCaption){
            cell.captionTextLabel.text = currentLootItem[0].caption
        }
        else{
            //No Caption to display in tableview cell
        }

        ref = FIRDatabase.database().reference()
        
        //TODO: Once the item is deleted from the world (aka Firebase), this crashes
        
        let timeSince = Int(stringToDate(cell.timeDroppedTextLabel.text!).timeIntervalSinceNow)
        let secondsInDay = 24*60*60*(-1)
        
        print(secondsInDay)
        print(timeSince)

        var likes = currentLootItem[0].likes
        
        if currentLootItem[0].likes == 0{
            cell.likeCounterTextLabel.text = "🌚"
        }else{
            cell.likeCounterTextLabel.text = "\(currentLootItem[0].likes)"
        }
        
        if (timeSince > secondsInDay){
            ref.root.child("MetaData").child(currentLootItem[0].itemID).observeSingleEvent(of: .value, with: { (snapshot)in
            
                    let postDict = snapshot.value as! [String : AnyObject]
            
                    likes = (postDict["likes"]!) as! Int
            
                if likes == 0 {
                    cell.likeCounterTextLabel.text = "🌚"
                }
                else{
                    cell.likeCounterTextLabel.text = String(likes)
                }
            
                })
            { (error) in
                
            }
            //Update realm likes
            try! Realm().write {
                currentLootItem[0].likes = likes
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85.0
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            
            let result = myLoots.filter("itemID == %@", sortedMyLoot[(indexPath as NSIndexPath).row])
            tappedLootItem = result[0]
            
            ref.root.child("MetaData").child(self.tappedLootItem.itemID).observeSingleEvent(of: .value, with: { (snapshot) in
               
                // Get user value
                let postDict = snapshot.value as! [String : AnyObject]
                
                let likes = (postDict["likes"]!) as! Int
                
                try! Realm().write{
                    self.tappedLootItem.likes = likes
                }
                
                let newLootDict = ["itemid": self.tappedLootItem.itemID ,
                    "mediatype": self.tappedLootItem.mediatype,
                    "latitude": self.tappedLootItem.latitude,
                    "longitude": self.tappedLootItem.longitude,
                    "created": self.tappedLootItem.created,
                    "likes": self.tappedLootItem.likes,
                    "isdeleted": true,
                    "beenuploaded": self.tappedLootItem.beenUploaded,
                    "hascaption": self.tappedLootItem.hasCaption,
                    "caption": self.tappedLootItem.caption] as [String : Any]
                
                
                self.ref.root.child("MetaData").child(self.tappedLootItem.itemID).setValue(newLootDict)
                
            }) { (error) in
                
            }
            
            
            //Modify Realm
            try! Realm().write(){
                tappedLootItem.isDeleted = true
            }
            
            //Remove from sortedMyLoot Array
            sortedMyLoot.remove(at: (indexPath as NSIndexPath).row)
            
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            let key:NSObject = "key" as NSObject
            
            let dictionaryToPassLoot = [key:tappedLootItem]
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "passDeletedLootBack"), object: nil, userInfo: dictionaryToPassLoot)
            
        }
    }

    //MARK: Fullscreen imageview segue
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = myLoots.filter("itemID == %@", sortedMyLoot[(indexPath as NSIndexPath).row])
        tappedLootItem = result[0]
        performSegue(withIdentifier: "fullscreensegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "fullscreensegue"){
            if let imageDisplayView = segue.destination as? ImageDisplayViewController{
                imageDisplayView.imgString = readFromImageFile(tappedLootItem.itemID)
                imageDisplayView.captionString = tappedLootItem.caption
            }
        }
    }
    
    //MARK: Initializers
    func initializeNavigationBar(){
        self.navigationController?.navigationBar.topItem?.title = "My Drops"
        self.navigationController?.isNavigationBarHidden = false
    }
    
    func reloadAllData(){
        tableView.reloadData()
    }
    

    
    //MARK: Sort and display array with most recent content at top
    func sortByDate(){
        
        let realm = try! Realm()
        
        let myLoot = realm.objects(LootItem.self).filter("localLoot == true AND isDeleted == false")

        
        for lootitem in myLoot {
            if (tempSorted as NSArray).contains(lootitem.itemID){
                //Don't add
            }else{
                tempSorted.insert(lootitem.itemID, at: 0)
                sortedMyLootImages.insert(displayImage(lootitem), at: 0)

            }
        }
    }
    
    
    
    //MARK: Unwinder To get back to this view from another view
    @IBAction func unwindToMyDrops(_ segue: UIStoryboardSegue){
        
    }
    
    //MARL: LocationButton Functionality
    func locationButtonTouched(sender: LocationButton){
        let indexRow = sender.indexRow
        let lootItem = myLoots.filter("itemID == %@", sortedMyLoot[indexRow])
        
        let lootItemToSendToMap = lootItem[0]
        
        
        let key:NSObject = "key" as NSObject
        
        let dictionaryToPassLoot = [key:lootItemToSendToMap]
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "passLocationLootBack"), object: nil, userInfo: dictionaryToPassLoot)
        
        performSegue(withIdentifier: "unwindToMapFromMyLoot", sender: self)
        
        
        
    }
    
    //MARK: Image displaying functions
    func displayImage(_ lootItemToDisplay: LootItem)->UIImage{
        
        if (lootItemToDisplay.mediatype == "Picture"){
            let imageFile = readFromImageFile(lootItemToDisplay.itemID)
            let imageFileURL = URL(fileURLWithPath: imageFile)
            let data = try? Data(contentsOf: imageFileURL)
            image = UIImage(data: data!)!
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
    
    
    //MARK: Helper date converter function
    //Helper function to order loot
    func stringToDate(_ stringToConvert: String) -> Date{
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        
        return (dateFormatter.date(from: stringToConvert))!
    }
}
