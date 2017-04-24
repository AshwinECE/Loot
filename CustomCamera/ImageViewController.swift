//
//  ImageViewController.swift
//  CustomCamera
//
//  Created by It's Happen Inc. on 2016-05-23.
//  Copyright © 2016 It's Happen Inc. All rights reserved.
//

import UIKit

import CoreLocation
import RealmSwift
import Firebase

class ImageViewController: UIViewController, UITextFieldDelegate {
   
    
    @IBOutlet weak var renderingUILabel: UILabel!
    
    @IBOutlet weak var captionTextField: UITextField!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var dropButton: UIButton!
    
    
    //Incoming location from previous view
    var locationAtDropPress = CLLocation()

    
    
    
    var fromInventory = false
    
    var isFrontCamera = false
    
    
    //let imagePath = self.directoryImageURL()
    var image: UIImage?

 
    @IBOutlet weak var imageView: UIImageView!
    
    //var loot: UILayoutSupport: [FIRDataSnapshot]! = []
    var msglength: NSNumber = 50
    fileprivate var _refHandle: FIRDatabaseHandle!
    var storageRef: FIRStorageReference!
    var ref: FIRDatabaseReference!
    
    var newImageLoot = LootItem()
    
    var location = CLLocationCoordinate2D()

    @IBAction func backButtonDidTouch(_ sender: AnyObject) {
        self.navigationController?.popViewController(animated: true)
    }
    //MARK: Drop!!
    @IBAction func dropButtonDidTouch(_ sender: AnyObject) {
        //TODO: 1. Create the lootItem metaData in the realm
            //  2. Write image file to Documents directory with correct name (UUID of lootItem)
            //  3. Unwind to MapViewController
            //  4. Inform MapViewController of new loot item to display on map
        
        
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async{
            self.renderingUILabel.isHidden = false
        }
        
 
        
        
        newImageLoot = writeToRealm(newImageLoot)
        
        
        
        writeImageToDocumentsDirectory(newImageLoot.itemID, image: image)
        
        uploadImageToCloud(newImageLoot)
        
        addLootToCloud(newImageLoot)
        
        location.latitude = newImageLoot.latitude
        location.longitude = newImageLoot.longitude
        

        
        let key:NSObject = "key" as NSObject
        
        let dictionaryToPassLoot = [key:newImageLoot]
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "passImageLootBack"), object: nil, userInfo: dictionaryToPassLoot)
        
        performSegue(withIdentifier: "UnwindToMapFromImage", sender: self)
    }
    
    func keyboardWasShown(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        if (captionTextField.text == "Whatchu sayin'?"){
            captionTextField.text = ""
        }
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height + 20
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        captionTextField.endEditing(true)
        
       resetField()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        
        
        captionTextField.delegate = self
        //This could error since it is outside the unwrapping statement
        
        if isFrontCamera {
            image = UIImage(cgImage: (image?.cgImage)!, scale: image!.scale, orientation: .leftMirrored)
        }else{
        
        }
        
        imageView.image = image
        
        configureDatabase()
        configureStorage()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        
        captionTextField.text = "Whatchu sayin'?"
        

        
    }
    
    func textFieldShouldReturn(_ textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        resetField()
        return true
    }
    
    func resetField(){
        if (captionTextField.text == ""){
            captionTextField.text = "Whatchu sayin'?"
        }
        
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.bottomConstraint.constant = 126
        })

    }
    
    override func viewWillAppear(_ animated: Bool) {
        renderingUILabel.isHidden = true
    }
    

    
    func addLootToCloud(_ newImageLoot: LootItem){
        let newCloudImageLoot = CloudLootItem()
        newCloudImageLoot.itemID = newImageLoot.itemID
        newCloudImageLoot.latitude = self.locationAtDropPress.coordinate.latitude
        newCloudImageLoot.longitude = self.locationAtDropPress.coordinate.longitude
        newCloudImageLoot.mediatype = "Picture"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        //dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        let date = Date()
        
        
        
        newCloudImageLoot.created = dateFormatter.string(from: date)
        newCloudImageLoot.likes = 0
        newCloudImageLoot.isDeleted = false
        
        newCloudImageLoot.hasCaption = newImageLoot.hasCaption
        newCloudImageLoot.caption = newImageLoot.caption
        
        let newLootDict = ["itemid": newCloudImageLoot.itemID,
                           "mediatype": newCloudImageLoot.mediatype,
                           "latitude": newCloudImageLoot.latitude,
                           "longitude": newCloudImageLoot.longitude, 
                           "created": newCloudImageLoot.created,
                           "likes": newCloudImageLoot.likes,
                           "isdeleted": newCloudImageLoot.isDeleted,
                           "beenuploaded": newCloudImageLoot.beenUploaded,
                           "hascaption": newCloudImageLoot.hasCaption,
                           "caption": newCloudImageLoot.caption] as [String : Any]
        
        self.ref.root.child("MetaData").child(newCloudImageLoot.itemID).setValue(newLootDict)
    }
    
    func uploadImageToCloud(_ newImageLoot: LootItem){
        let metadata = FIRStorageMetadata()
        // File located on disk
        let localFile = directoryImageURL(newImageLoot.itemID)
        metadata.contentType = "png"
        // Create a reference to the file you want to upload
        let textRef = storageRef.child("LootImage/\(newImageLoot.itemID).png")
        
        // Upload the file to the path "images/rivers.jpg"
        let uploadTask = textRef.putFile(localFile.newPath, metadata: metadata) { metadata, error in
            if (error != nil) {
                // Uh-oh, an error occurred!
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL
                
                self.ref.root.child("MetaData").child(newImageLoot.itemID).child("beenuploaded").setValue(true)
            }
        }
    }
    
    //MARK: Firebase configurations
    func configureDatabase() {
        ref = FIRDatabase.database().reference()
        // Listen for new messages in the Firebase database
        _refHandle = self.ref.root.observe(.childAdded, with: { (snapshot) -> Void in
            //self.loot.append(snapshot)
        })
    }
    
    
    func configureStorage(){
        storageRef = FIRStorage.storage().reference(forURL: "gs://loot-c340a.appspot.com")
    }
    
    //MARK: Writing to the Realm Table
    func writeToRealm(_ newImageLoot: LootItem) -> LootItem {
        let realm = try! Realm()
        
        try! realm.write{
            newImageLoot.itemID = UUID().uuidString
            newImageLoot.latitude = self.locationAtDropPress.coordinate.latitude
            newImageLoot.longitude = self.locationAtDropPress.coordinate.longitude
            newImageLoot.beenLoaded = false
            newImageLoot.mediatype = "Picture"
            newImageLoot.localLoot = true
            
        
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short

            let date = Date()
            
            newImageLoot.created = dateFormatter.string(from: date)
            newImageLoot.likes = 0
            
            
            
            if (captionTextField.text == "" || captionTextField.text == "Whatchu sayin'?"){
                //Dont add a caption
                newImageLoot.hasCaption = false
            }else{
                //User added a custom caption
                newImageLoot.hasCaption = true
                newImageLoot.caption = captionTextField.text!
            }
            
            realm.add(newImageLoot)
        }
        return newImageLoot
    }
    
    
    //MARK: Writing Image to file
    func writeImageToDocumentsDirectory(_ lootID: String, image: UIImage?){
        let imagePath = directoryImageURL(lootID)
            if let validImage = image {
                
                
                
                //let pngImageData = UIImagePNGRepresentation(validImage)
                let pngImageData = validImage.lowQualityJPEGNSData
                
                let result = (try? pngImageData.write(to: URL(fileURLWithPath: imagePath.newPath.path), options: [.atomic])) != nil
                
            }else{
                
            }
    }

    func directoryImageURL(_ UUID: String) -> (newPath: URL, path: URL) {
        
        let path = try! FileManager.default.url(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
        
        let newPath = path.appendingPathComponent("\(UUID).png")
        
        return (newPath, path)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}



extension UIImage
{
    var highestQualityJPEGNSData: Data { return UIImageJPEGRepresentation(self, 1.0)! }
    var highQualityJPEGNSData: Data    { return UIImageJPEGRepresentation(self, 0.75)!}
    var mediumQualityJPEGNSData: Data  { return UIImageJPEGRepresentation(self, 0.5)! }
    var lowQualityJPEGNSData: Data     { return UIImageJPEGRepresentation(self, 0.25)!}
    var lowestQualityJPEGNSData: Data  { return UIImageJPEGRepresentation(self, 0.0)! }
}
