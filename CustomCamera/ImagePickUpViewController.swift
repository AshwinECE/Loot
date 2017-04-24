//
//  PickUpViewController.swift
//  CustomCamera
//
//  Created by It's Happen Inc. on 2016-05-28.
//  Copyright © 2016 It's Happen Inc. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift
import MapKit
import FirebaseInstanceID


class ImagePickUpViewController: UIViewController {
    
    @IBOutlet weak var pickUpBox: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var captionLabel: UILabel!
    
    
    
    @IBOutlet weak var likeLabel: UILabel!

    @IBOutlet weak var timeOfDropTextLabel: UILabel!
    
    @IBOutlet weak var lootButton: UIButton!
    @IBOutlet weak var buffButton: UIButton!
    
    @IBAction func dismissImagePickUpBoxDidTouch(_ sender: AnyObject) {
            performSegue(withIdentifier: "unwindToMapFromImageLooted", sender: self)
    }
    @IBAction func pickUpBoxCloseButtonDidTouch(_ sender: AnyObject) {
            performSegue(withIdentifier: "unwindToMapFromImageLooted", sender: self)
    }
    
    //MARK: Wrong name - meant lootButtonDidTouch
    @IBAction func dropButtonDidTouch(_ sender: AnyObject) {
        
        var ref: FIRDatabaseReference!
        
        ref = FIRDatabase.database().reference()
        
        moveImageToDocuments(lootItemToDisplay)
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        //dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        let date = Date()



        lootButton.isEnabled = false
        

        //Buff also
        if (!lootItemToDisplay.beenLiked){
            buffLoot()
        }
        let realm = try! Realm()
        try! realm.write{
            lootItemToDisplay.lootedAt = dateFormatter.string(from: date)
        }
        performSegue(withIdentifier: "unwindToMapFromImageLooted", sender: self)
    }
    
    var lootItemToDisplay = LootItem()
    
    var imageToDisplay = UIImage()
    
    var fromImagePickup = true
    
    var storageRef: FIRStorageReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        //Check if the item has been looted/buffed
        if lootItemToDisplay.beenLiked == true{
            buffButton.isEnabled = false
        }
        if lootItemToDisplay.lootedAt != "NOTLOOTED"{
            lootButton.isEnabled = false
        }
        
        // Do any additional setup after loading the view.

        
        if lootItemToDisplay.hasCaption {
            captionLabel.isHidden = false
            captionLabel.text = "  \(lootItemToDisplay.caption)"
        }
        else{
            captionLabel.isHidden = true
        }
        
        
            var ref: FIRDatabaseReference!
            
            ref = FIRDatabase.database().reference()
            
            
            ref.root.child("MetaData").child(self.lootItemToDisplay.itemID).observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                
                let postDict = snapshot.value as! [String : AnyObject]
                
                
                
                let likes = (postDict["likes"]!) as! Int
                
                
                
                try! Realm().write(){
                    self.lootItemToDisplay.likes = likes
                }
                self.likeLabel.text = String(self.lootItemToDisplay.likes)
                
                
                
                
            }) { (error) in
                
            }
 

        likeLabel.text = String(lootItemToDisplay.likes)
        
        
        //configureStorage()

        if lootItemToDisplay.cloudFlag == false{
            //Local File
            localFileDisplay()
        }
        else{
            //storageRef = FIRStorage.storage().referenceForURL("gs://loot-c340a.appspot.com")
            
            //let fileRef = storageRef.child("LootImage/\(lootItemToDisplay.itemID).png")
            
            let tempFile = NSTemporaryDirectory()
            
            let fileName = "\(tempFile)\(lootItemToDisplay.itemID).png"
            
            let fileManager = FileManager.default
            
            if (fileManager.fileExists(atPath: fileName)){
            
                let localURL = URL(fileURLWithPath: fileName)
            
                let data = try? Data(contentsOf: localURL)
            
                let image = UIImage(data: data!)
            
                let imageScaled = self.resizeImage(image!, newWidth: 365)
            
                self.imageView.image = imageScaled
            
                self.imageToDisplay = imageScaled
            
                self.initializePickUpBoxImageView()
            }
            else{
                let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
                let documentDirectory = urls[0] as URL
                let imageURL = documentDirectory.appendingPathComponent("\(lootItemToDisplay.itemID).png")
                
                let data = try? Data(contentsOf: imageURL)
                
                let image = UIImage(data: data!)
                
                
                
                let imageScaled = self.resizeImage(image!, newWidth: 365)
                
                self.imageView.image = imageScaled
                
                self.imageToDisplay = imageScaled
                
                self.initializePickUpBoxImageView()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.initializePickUpBoxImageView()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func unwindToImagePickUp(_ segue: UIStoryboardSegue) {
        if let imageDisplayController = segue.source as? ImageDisplayViewController {
            //fromUnload = true
            //Add new lootitem with image to the map
        }
    }
    
    //MARK: Initializer
    func initializePickUpBoxImageView(){
        pickUpBox.layer.cornerRadius = 24
        pickUpBox.layer.shadowColor = UIColor.black.cgColor
        pickUpBox.layer.shadowOpacity = 0.7
        pickUpBox.layer.shadowOffset = CGSize.zero
        pickUpBox.layer.shadowRadius = 5
        imageView.layer.cornerRadius = 24
        imageView.clipsToBounds = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ImagePickUpViewController.imageTapped(_:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
        
        timeOfDropTextLabel.text = lootItemToDisplay.created
        
        if (lootItemToDisplay.localLoot == true){
            lootButton.isEnabled = false
        }
        
    }
    
    func localFileDisplay(){
        let imageFile = readFromImageFile(lootItemToDisplay.itemID)
        let imageFileURL = URL(fileURLWithPath: imageFile)
        let data = try? Data(contentsOf: imageFileURL)
        
        let image = UIImage(data: data!)
        
        let imageScaled = resizeImage(image!, newWidth: 365)
        
        imageView.image = imageScaled
        imageToDisplay = imageScaled
        //pickUpBoxImageView.image = cropToBounds(imageScaled, width: 312, height: 317)
        initializePickUpBoxImageView()
    }

    func moveImageToDocuments(_ lootItem: LootItem){
        let path = NSTemporaryDirectory() as String
        
        let tempFile = path + "\(lootItem.itemID).png"
        
        let tempURL = URL(fileURLWithPath: tempFile)
        
        let dirPath = self.directoryImageURL(lootItem.itemID)
        
        
        do {
            try FileManager.default.moveItem(at: tempURL, to: dirPath.newPath)
        }
        catch let error as NSError {

        }
    }
    
    @IBAction func buffDidTouch(_ sender: AnyObject){
            buffLoot()
            buffButton.isEnabled = false
        let token = FIRInstanceID.instanceID().token()

    }
    
    func buffLoot(){
        let realm = try! Realm()
        
        try! realm.write {
            lootItemToDisplay.beenLiked = true
        }
        var ref: FIRDatabaseReference!
        
        var _refHandle: FIRDatabaseHandle!
        
        ref = FIRDatabase.database().reference()
        
        let lootLocal = LootItem()
        
        ref.root.child("MetaData").child(self.lootItemToDisplay.itemID).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            
            let postDict = snapshot.value as! [String : AnyObject]
            
            var likes = (postDict["likes"]!) as! Int
            
            likes = likes + 1
            
            let likesString = String(likes)
            
            self.likeLabel.text = likesString
            
            let newLootDict = ["itemid": self.lootItemToDisplay.itemID,
                "mediatype": self.lootItemToDisplay.mediatype,
                "latitude": self.lootItemToDisplay.latitude,
                "longitude": self.lootItemToDisplay.longitude,
                "created": self.lootItemToDisplay.created,
                "likes": likes,
                "isdeleted": self.lootItemToDisplay.isDeleted,
                "beenuploaded": self.lootItemToDisplay.beenUploaded,
                "hascaption": self.lootItemToDisplay.hasCaption,
                "caption": self.lootItemToDisplay.caption] as [String : Any]
            
            ref.root.child("MetaData").child(self.lootItemToDisplay.itemID).setValue(newLootDict)
            
        }) { (error) in
            
        }
        

    }
    func directoryImageURL(_ UUID: String) -> (newPath: URL, path: URL) {
        
        let path = try! FileManager.default.url(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
        
        let newPath = path.appendingPathComponent("\(UUID).png")
        
        return (newPath, path)
    }

    func readFromImageFile(_ itemID: String) -> String{
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                           .userDomainMask, true)
        let documentsDirectory = dirPaths[0]
        
        let fileName = itemID
        
        let finalFilePath = "\(documentsDirectory)/\(fileName).png"
        
        return finalFilePath
    }
    
    //MARK: Image Scaling
    func resizeImage(_ image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
    func cropToBounds(_ image: UIImage, width: Double, height: Double) -> UIImage {
        
        let contextImage: UIImage = UIImage(cgImage: image.cgImage!)
        
        let contextSize: CGSize = contextImage.size
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
    
    //MARK: Fullscreening Image
    func imageTapped(_ img: AnyObject)
    {
     
        self.navigationController?.isNavigationBarHidden = true
        //let newImageView = UIImageView(image: imageToDisplay)
        //newImageView.frame = self.view.frame
        //newImageView.backgroundColor = .blackColor()
        //newImageView.contentMode = .ScaleAspectFit
        //newImageView.userInteractionEnabled = true
        //let tap = UITapGestureRecognizer(target: self, action: #selector(ImagePickUpViewController.dismissFullscreenImage(_:)))
        //newImageView.addGestureRecognizer(tap)
        //self.view.addSubview(newImageView)
        performSegue(withIdentifier: "ImageDisplaySegue", sender: self)
    }
    
    func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        self.navigationController?.isNavigationBarHidden = false
        sender.view?.removeFromSuperview()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ImageDisplaySegue"){
            if let imageDisplayView = segue.destination as? ImageDisplayViewController{
                imageDisplayView.imgString = segueFileCheck(lootItemToDisplay.itemID)
                imageDisplayView.fromImagePickUp = fromImagePickup
                imageDisplayView.captionString = lootItemToDisplay.caption
            }
        }
    }
    
    func segueFileCheck(_ itemID: String) -> String{
        if lootItemToDisplay.cloudFlag == false {
            return readFromImageFile(itemID)
        }
        else{
            
            let tempFile = NSTemporaryDirectory()
            
            let fileName = "\(tempFile)\(lootItemToDisplay.itemID).png"
            
            let fileManager = FileManager.default

            if(fileManager.fileExists(atPath: fileName)){
                return fileName
            }
            else{
                let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
                let documentDirectory = urls[0] as URL
                let imageURL = documentDirectory.appendingPathComponent("\(lootItemToDisplay.itemID).png")
                
                let imgString = String(describing: imageURL)
                
                return imgString

            }
        }
    
    }
    
   }
