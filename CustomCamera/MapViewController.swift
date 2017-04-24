//
//  MapViewController.swift
//  CustomCamera
//
//  Created by It's Happen Inc. on 2016-05-26.
//  Copyright © 2016 It's Happen Inc. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase
import RealmSwift

class MapViewController: UIViewController{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var dropTextView: UITextView!
    @IBOutlet weak var dropButton: UIButton!
    @IBOutlet weak var centerButton: UIButton!
    
    @IBOutlet weak var zoomInButton: UIButton!
    @IBOutlet weak var zoomOutButton: UIButton!

    @IBOutlet weak var dropButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var dropTextViewBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var downloadingTextLabel: UILabel!
    
    //MARK: All our lootItems
    var lootItems = try! Realm().objects(LootItem.self)
    

    
    //MARK: Temp Received Loot to be dropped
    var lootToDrop = LootItem()
    var fromUnload = false
    var lootItemToDisplay = LootItem()


    var lootToBeDeleted = LootItem()
    
    var firstLoad = true

    
    //MARK: Search
    var resultSearchController:UISearchController? = nil
    var selectedPin:MKPlacemark? = nil
    
    //MARK: Map management related variables
    var locationManager = CLLocationManager()
    let regionRadius: CLLocationDistance = 100
    var mapChangedFromUserInteraction = false


    
    //MARK: FireBase
    fileprivate var _refHandle: FIRDatabaseHandle!
    var ref: FIRDatabaseReference!
    var storageRef: FIRStorageReference!

    
    
    //MARK: Unwinders
    @IBAction func unwindToMap(_ segue: UIStoryboardSegue) {
        
        mapView.isUserInteractionEnabled = true
        
        if let imageViewController = segue.source as? ImageViewController {
           fromUnload = true
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "droppedNewLoot"), object: nil)
        }

        else if let imagePickUpViewController = segue.source as? ImagePickUpViewController{
            
        }

        else if let myLootViewController = segue.source as? MyLootTableViewController{
            //Location Button Pressed
        }
        else if let searchViewController = segue.source as? SearchTableViewController{
            dropPinZoomIn(selectedPin!)
        }
    }
    
    //MARK: ALL View Functions
    
    //MARK: ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
     
        mapView.delegate = self
        initializeMapView()
        
        locationManager.delegate = self
        initializeLocationManager()
        
        initializeButtons()
        
        initializeSearchBar()
        
        
        
        //Notifications running to send media back when dropped
        NotificationCenter.default.addObserver(self, selector:#selector(MapViewController.grabLoot(_:)), name: NSNotification.Name(rawValue: "passImageLootBack"), object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.setTheLootToBeDeleted), name: NSNotification.Name(rawValue: "passDeletedLootBack"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.dropButtonDidTouch), name: NSNotification.Name(rawValue: "drop-button-touched"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.zoomToLoot(_:)), name: NSNotification.Name(rawValue: "passLocationLootBack"), object: nil)
        

        //MARK: Never need to deinitialize these observors
        
        NotificationCenter.default.addObserver(self, selector: #selector (resetDropState), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector (resetDropState), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        
        populateMapWithLocalLoot()
        
        populateRealm()
        
    }
    
    //MARK: Dropping new loot on map when returning from drop mediaviewcontrollers
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        //Drop the new loot item if coming from an unwind
        if (fromUnload){
            dropNewPin(CLLocationCoordinate2DMake(lootToDrop.latitude, lootToDrop.longitude), withThisLootItem: lootToDrop)
        }
        fromUnload = false
    }
    
    //MARK: ViewWill Appear managing the keyboard notifications
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.topItem?.title = "Loot"
        self.navigationController?.isNavigationBarHidden = false
        
        
        mapView.isUserInteractionEnabled = true
        

    }
    
    //MARK: Remove all observors when view disappears
    override func viewWillDisappear(_ animated: Bool) {
       
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    //MARK: Initializers:
    func initializeMapView(){
        
        mapView.showsUserLocation = true
        mapView.userLocation.title = ""
        mapView.mapType = MKMapType(rawValue: 0)!
        mapView.userTrackingMode = MKUserTrackingMode(rawValue: 1)!
    }
    
    func initializeLocationManager(){
        let status = CLLocationManager.authorizationStatus()
        
        //Make sure status is .Accepted so that the user can use our app
        if (status == .notDetermined || status == .denied) {
            locationManager.requestWhenInUseAuthorization()
        }
        //Can now enable the location manager to stat updating location since auth was accepted
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    func centerMapOnLocation(_ location : CLLocation){
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius*2, regionRadius*2)
        
        mapView.setRegion(coordinateRegion, animated: true)
    }

    func initializeButtons(){
        let zoomInLongPress = UILongPressGestureRecognizer(target: self, action: #selector(zoomInHold))
        zoomInButton.addGestureRecognizer(zoomInLongPress)
        let zoomInShortPress = UITapGestureRecognizer(target: self, action: #selector(zoomInTap))
        zoomInButton.addGestureRecognizer(zoomInShortPress)
        
        let zoomOutLongPress = UILongPressGestureRecognizer(target: self, action: #selector(zoomOutHold))
        zoomOutButton.addGestureRecognizer(zoomOutLongPress)
        let zoomOutShortPress = UITapGestureRecognizer(target: self, action: #selector(zoomOutTap))
        zoomOutButton.addGestureRecognizer(zoomOutShortPress)
        
        downloadingTextLabel.isHidden = true
    }
    
    func initializeSearchBar(){
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! SearchTableViewController
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(searchSegue))
        dropTextView.addGestureRecognizer(tap)
        
    }

    
    
    //MARK: Interactive Buttons on mapView
    func searchSegue(){
        performSegue(withIdentifier: "searchSegue", sender: self)
    }
    
    
    func zoomInHold(_ gesture: UILongPressGestureRecognizer){
        var region = self.mapView.region

 
                region.span.latitudeDelta = region.span.latitudeDelta/4
                region.span.longitudeDelta = region.span.longitudeDelta/4
                mapView.setRegion(region, animated: false)

    }
    func zoomInTap(){
        var region = self.mapView.region
        region.span.latitudeDelta = region.span.latitudeDelta/2
        region.span.longitudeDelta = region.span.longitudeDelta/2
        mapView.setRegion(region, animated: true)

    }
    func zoomOutHold(_ gesture: UILongPressGestureRecognizer){
        var region = self.mapView.region

        //if gesture.state == .Began {
            //while (gesture.state == .Began){
                region.span.latitudeDelta = min(region.span.latitudeDelta*1.5, 180)
                region.span.longitudeDelta = min(region.span.longitudeDelta*1.5, 180)
                mapView.setRegion(region, animated: false)
            //}

        //}
    }
    func zoomOutTap(){
        var region = self.mapView.region
        
        region.span.latitudeDelta = min(region.span.latitudeDelta*2, 180)
        region.span.longitudeDelta = min(region.span.longitudeDelta*2, 180)
        mapView.setRegion(region, animated: true)
    }
    
    
    @IBAction func centerButtonDidTouch(_ sender: AnyObject) {
        centerMapOnLocation(locationManager.location!)
        activateCenterButton()
    }
    
    func dropButtonDidTouch(_ notification: Foundation.Notification){
        performSegue(withIdentifier: "cameraSegue", sender: self)
    }
    
    //MARK: Populate Functions
    
    func populateMapWithLocalLoot(){
        for lootItem in lootItems{
            if (lootItem.localLoot){
                let location = CLLocationCoordinate2D(latitude: lootItem.latitude, longitude: lootItem.longitude)
                dropNewPin(location, withThisLootItem: lootItem)
            }
        }
    }
    
    func populateRealm() {
        ref = FIRDatabase.database().reference()
        

        _refHandle = ref.root.child("MetaData").observe(FIRDataEventType.value, with: { (snapshot) in
                
            if snapshot.exists(){

            let postDict = snapshot.value as! [String : AnyObject]
            
            for (key,value) in postDict {
                let itemid = (postDict[key]!["itemid"]!)!
                let latitude = (postDict[key]!["latitude"]!)!
                let longitude = (postDict[key]!["longitude"]!)!
                let mediaType = (postDict[key]!["mediatype"]!)!
                let date = (postDict[key]!["created"]!)!
                let likes = (postDict[key]!["likes"]!)!
                let isdeleted = (postDict[key]!["isdeleted"]!)!
                let beenuploaded = (postDict[key]!["beenuploaded"]!)!
                let hasCaption = (postDict[key]!["hascaption"]!)!
                let caption = (postDict[key]!["caption"]!)!
                
                
                let realm = try! Realm()
                
                let newLootItem = LootItem()
            
                newLootItem.itemID = itemid as! String
                newLootItem.mediatype = mediaType as! String
                newLootItem.latitude = latitude as! Double
                newLootItem.longitude = longitude as! Double
                newLootItem.created = date as! String
                newLootItem.cloudFlag = true
                newLootItem.localLoot = false
                newLootItem.likes = likes as! Int
                newLootItem.isDeleted = isdeleted as! Bool
                newLootItem.beenUploaded = beenuploaded as! Bool
                newLootItem.hasCaption = hasCaption as! Bool
                newLootItem.caption = caption as! String
                
                //Check if the item has expired before saving it to realm/displaying on map
            
                let timeSince = Int(self.stringToDate(newLootItem.created).timeIntervalSinceNow)
                let timeOut = 43200*(-1)
                    
                if timeSince < timeOut {
                  newLootItem.hasExpired = true
                }else{
                    newLootItem.hasExpired = false
                }
                
                //Here we check whether the objects originated from the user, and set the appropriate flags before writing
                if let lootExists = realm.object(ofType: LootItem.self, forPrimaryKey: newLootItem.itemID)
                {
                    try! realm.write{
                        if (lootExists.localLoot){
                            lootExists.cloudFlag = false
                            lootExists.isDeleted = newLootItem.isDeleted
                            lootExists.hasExpired = newLootItem.hasExpired
                            lootExists.beenUploaded = newLootItem.beenUploaded
                        }else{
                            lootExists.cloudFlag = true
                            lootExists.isDeleted = newLootItem.isDeleted
                            lootExists.hasExpired = newLootItem.hasExpired
                            lootExists.beenUploaded = newLootItem.beenUploaded
                    }
                    
                    realm.create(LootItem.self, value: lootExists, update: true)
                }
                }else{
                    try! realm.write{
                        realm.create(LootItem.self, value: newLootItem, update: true)
                    }
                }
                
                //MARK: If the items need to be deleted but the user has not looted them, we remove the annotation
                //      and delete the object from our realm
                
                let lootItemsToBeDeleted = try! Realm().objects(LootItem).filter("isDeleted == true && lootedAt == 'NOTLOOTED'")
                
                for lootItem in lootItemsToBeDeleted{
                    self.removeAnnotationFromMap(lootItem)
                }

                try! realm.write{
                    realm.delete(lootItemsToBeDeleted)
                }
                
                
                
                //MARK: If the items need to be deleted and the user looted them, we only remove the annotation from the map
                let lootItemsToBeRemovedFromMap = try! Realm().objects(LootItem).filter("isDeleted == true || lootedAt != 'NOTLOOTED' || hasExpired == true")
                
                for lootItem in lootItemsToBeRemovedFromMap{
                        self.removeAnnotationFromMap(lootItem)
                }
                
                self.populateMap()

            }
            }else{
                //No data
            }
        })
    }
    
    deinit{
        ref.removeAllObservers()
    }
    
    func populateMap(){

        let realm = try! Realm()
        
        let lootItemsToLoad = try! Realm().objects(LootItem).filter("beenLoaded == false AND beenUploaded == true AND hasExpired == false")

        // Create annotations for each one
        for lootItem in lootItemsToLoad {
            let coord = CLLocationCoordinate2D(latitude: lootItem.latitude, longitude: lootItem.longitude);
            try! realm.write{
                lootItem.beenLoaded = true
            }
            if lootItem.localLoot == false{
                dropNewPin(coord, withThisLootItem: lootItem)
            }
        }
    }

    func dropNewPin(_ atThisLocation: CLLocationCoordinate2D, withThisLootItem: LootItem?) {
        let title = "\(atThisLocation.latitude), \(atThisLocation.longitude)"
        
        let lootPin = LootItemAnnotation(coordinate: atThisLocation, title: title, subtitle: (withThisLootItem?.mediatype)!, lootitem: withThisLootItem)
        
        mapView.addAnnotation(lootPin)
    }

    
    //MARK: Reset drop state
    func resetDropState(){
        lootItems = try! Realm().objects(LootItem)
        
        firstLoad = true
        
        // Create annotations for each one
        for lootItem in lootItems { // 3
            
            try! Realm().write{
                lootItem.beenLoaded = false
            }
        }
    }
    
    //MARK: Notification responder functions
    //MARK: Responds to loot drop event and sends the media dropped to this controller
    func grabLoot(_ notification: Foundation.Notification){
        let key:NSObject = "key" as NSObject
        lootToDrop = (notification as NSNotification).userInfo![key] as! LootItem
    }
    
    func setTheLootToBeDeleted(_ notification: Foundation.Notification){
        let key:NSObject = "key" as NSObject
        lootToBeDeleted = (notification as NSNotification).userInfo![key] as! LootItem
        
        for annotation in mapView.annotations {
            if annotation is LootItemAnnotation {
                let annotation = annotation as! LootItemAnnotation
                if annotation.lootitem == lootToBeDeleted{
                    mapView.removeAnnotation(annotation)
                }
            }
            else{
                //Do nothing
            }
        }
    }
    
    func zoomToLoot(_ notification: Foundation.Notification){
        let key:NSObject = "key" as NSObject
        let lootToZoom = (notification as NSNotification).userInfo![key] as! LootItem
        
        
        
        // clear existing pins
        
        let annotation = MarkerAnnotation(coordinate: (CLLocationCoordinate2D(latitude: lootToZoom.latitude, longitude: lootToZoom.longitude)), title: lootToZoom.caption, subtitle: lootToZoom.created)
        
        for annotation in mapView.annotations {
            if annotation is MarkerAnnotation {
                mapView.removeAnnotation(annotation)
            }
            else{
                //Do nothing since they are other annotation types
            }
        }
        
        

        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.01, 0.01)
        let region = MKCoordinateRegionMake(annotation.coordinate, span)
        mapView.setRegion(region, animated: true)

        
    }
    
    //MARK: Search radius algorithm - not used yet but we will need to use it later on when we have more drops
    func searchRadius() -> (minX: CLLocationDegrees, maxX: CLLocationDegrees, minY: CLLocationDegrees, maxY: CLLocationDegrees) {
        let mRect = mapView.visibleMapRect
        
        let coordinateMapRect = MKCoordinateRegionForMapRect(mRect)
        let span = coordinateMapRect.span
        let center = coordinateMapRect.center
   
        let spanConstantLongitude = span.longitudeDelta/2
        let spanConstantLatitude = span.latitudeDelta/2
        
        let minX = center.longitude - spanConstantLongitude
        let maxX = center.longitude + spanConstantLongitude
        let minY = center.latitude - spanConstantLatitude
        let maxY = center.latitude + spanConstantLatitude
        
        return (minX, maxX, minY, maxY)
    }
    
    
    func removeAnnotationFromMap(_ lootItemToRemove: LootItem) {
        
        for annotation in mapView.annotations {
            if annotation is LootItemAnnotation {
                let annotation = annotation as! LootItemAnnotation
                if annotation.lootitem == lootItemToRemove{
                    mapView.removeAnnotation(annotation)
                }
            }
            else{
                //Do nothing since they are other annotation types
            }
        }
    }
    
    //MARK: Segue - passing location data
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "cameraSegue"){
            let nextView = segue.destination as! ViewController
            nextView.locationAtDropPress = locationManager.location!
        }
        else if(segue.identifier == "pickupimagesegue"){
            //Need to pass all the drop related info
            let pickUpView = segue.destination as! ImagePickUpViewController
            pickUpView.lootItemToDisplay = lootItemToDisplay
        }
        else if(segue.identifier == "searchSegue"){
            let pickUpView = segue.destination as! SearchTableViewController
            pickUpView.mapView = mapView
        }
    }
    
    
  
    //MARK: State Management
    func deActivateReCenterButton(){
            centerButton.setImage(UIImage(named: "inactive-center-button"), for: UIControlState())
    }
    
    func activateCenterButton(){
            centerButton.setImage(UIImage(named: "active-center-button"), for: UIControlState())
    }
    func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view: UIView = mapView.subviews[0] as UIView
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if( recognizer.state == UIGestureRecognizerState.began || recognizer.state == UIGestureRecognizerState.ended ) {
                    return true
                }
            }
        }
        return false
    }
    
    func dropPinZoomIn(_ placemark:MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        
        let annotation = MKPointAnnotation()
        
        for annotation in mapView.annotations {
            if annotation is MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            }
            else{
                //Do nothing since they are other annotation types
            }
        }
        
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.02, 0.02)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
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
extension MapViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction()
        if (mapChangedFromUserInteraction) {
            // user changed map region
            deActivateReCenterButton()
            
            for annotation in mapView.annotations {
                if (annotation is MKPointAnnotation || annotation is MarkerAnnotation){
                    mapView.removeAnnotation(annotation)
                }
                else{
                    //Do nothing since they are other annotation types
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if (mapChangedFromUserInteraction) {
            // user changed map region
            deActivateReCenterButton()
        }
    }
    
    //MARK: Annotations
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let subtitle = annotation.subtitle! else { return nil }
        
        if (annotation is LootItemAnnotation) {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: subtitle) {
                return annotationView
            } else {
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: subtitle)
                
                    annotationView.image = UIImage(named: "active-lootbag")
                
                    annotationView.isEnabled = true

                return annotationView
            }
        }
        
        if (annotation is MarkerAnnotation){
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: subtitle) {
                return annotationView
            } else {
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: subtitle)
                
                annotationView.image = UIImage(named: "xAnnotation")
                
                annotationView.isEnabled = true
                
                return annotationView
            }

        }
        return nil
    }
    
    //MARK: Annotation Animations can be modified here
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for annotationView in views {
            if annotationView.annotation is LootItemAnnotation{
                let lootItemToDrop = annotationView.annotation as! LootItemAnnotation
                
                
                if lootItemToDrop.lootitem?.beenSelected == true{
                    if (lootItemToDrop.lootitem?.localLoot == false){
                        annotationView.image = UIImage (named: "inactive-lootbag")
                    }
                    else{
                        annotationView.image = UIImage (named: "active-myLootBag")
                    }
                    mapView.sendSubview(toBack: annotationView)
                }else if lootItemToDrop.lootitem?.localLoot == true{
                    
                    annotationView.image = UIImage (named: "active-myLootBag")
                }
                else {
                    annotationView.image = UIImage (named: "active-lootbag")
                }
            
                annotationView.transform = CGAffineTransform(translationX: 0, y: -500)
                UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveLinear, animations: {
                    annotationView.transform = CGAffineTransform(translationX: 0, y: 0)
                    }, completion: nil)
                    
                    
            }
            else if annotationView.annotation is MarkerAnnotation{
                annotationView.image = UIImage(named:"xAnnotation")
                annotationView.transform = CGAffineTransform(translationX: 0, y: -500)
                UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveLinear, animations: {
                    annotationView.transform = CGAffineTransform(translationX: 0, y: 0)
                    }, completion: nil)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if view.annotation is LootItemAnnotation{
           
            mapView.isUserInteractionEnabled = false
            
            let annotation = view.annotation as! LootItemAnnotation
            
            view.sendSubview(toBack: mapView)
            
            lootItemToDisplay = annotation.lootitem!

            if lootItemToDisplay.localLoot == true{
                view.image = UIImage (named: "active-myLootBag")
            }else{
                view.image = UIImage (named: "inactive-lootbag")
            }
            
            let realm = try! Realm()
            
            try! realm.write{
                lootItemToDisplay.beenSelected = true
            }
            
            let fileManager = FileManager.default
            
            let tempFile = NSTemporaryDirectory()
            
            let fileVideoName = "\(tempFile)\(lootItemToDisplay.itemID).mp4"
            
            if (annotation.lootitem?.mediatype == "Picture"){
                
                let fileName = "\(tempFile)\(lootItemToDisplay.itemID).png"

                
                if (lootItemToDisplay.cloudFlag == false){
                    mapView.deselectAnnotation(view.annotation, animated: false)
                    performSegue(withIdentifier: "pickupimagesegue", sender: self)
                }
                
                if (fileManager.fileExists(atPath: fileName)){
                    mapView.deselectAnnotation(view.annotation, animated: false)
                    performSegue(withIdentifier: "pickupimagesegue", sender: self)
                    
                }else{
                    
                    downloadingTextLabel.isHidden = false

                    storageRef = FIRStorage.storage().reference(forURL: "gs://loot-c340a.appspot.com")
                
                    let fileRef = storageRef.child("LootImage/\(lootItemToDisplay.itemID).png")
                
                    let localURL = URL(fileURLWithPath: fileName)
                    
                    let downloadTask = fileRef.write(toFile: localURL) { (URL, error) -> Void in
                    
                        if (error != nil) {
                            self.downloadingTextLabel.isHidden = true
                        
                        } else {
                            self.downloadingTextLabel.isHidden = true
                            mapView.deselectAnnotation(view.annotation, animated: false)
                            self.performSegue(withIdentifier: "pickupimagesegue", sender: self)
                        }
                    }
                }
            }
            else if (annotation.lootitem?.mediatype == "Video"){
                //performSegueWithIdentifier("pickupvideosegue", sender: self)
                
                let videoFileName = "\(tempFile)\(lootItemToDisplay.itemID).mp4"
                
                if (lootItemToDisplay.cloudFlag == false){
                    mapView.deselectAnnotation(view.annotation, animated: false)
                    performSegue(withIdentifier: "pickupvideosegue", sender: self)
                }
                
                if (fileManager.fileExists(atPath: videoFileName)){
                    mapView.deselectAnnotation(view.annotation, animated: false)
                    performSegue(withIdentifier: "pickupvideosegue", sender: self)
                    
                }else{
                    
                    
                    downloadingTextLabel.isHidden = false
                    
                    storageRef = FIRStorage.storage().reference(forURL: "gs://loot-c340a.appspot.com")
                    
                    let fileRef = storageRef.child("LootVideo/\(lootItemToDisplay.itemID).mp4")
                    
                    let localURL = URL(fileURLWithPath: videoFileName)
                    
                    let downloadTask = fileRef.write(toFile: localURL) { (URL, error) -> Void in
                        
                        if (error != nil) {
                            
                        } else {
                            mapView.deselectAnnotation(view.annotation, animated: false)
                            self.performSegue(withIdentifier: "pickupvideosegue", sender: self)
                        }
                    }
                }
            }
        }
        //Do nothing on mylocation press
        else{
            view.canShowCallout = false
        }
    }
}
extension MapViewController: CLLocationManagerDelegate{
    //Required Functions
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
    }
    

}
