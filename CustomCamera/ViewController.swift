//
//  ViewController.swift
//  CustomCamera
//
//  Created by It's Happen Inc. on 2016-05-23.
//  Copyright © 2016 It's Happen Inc. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Foundation
import MobileCoreServices
import CoreLocation

class ViewController: UIViewController, UINavigationControllerDelegate {

    //Incoming location from previous view
    var locationAtDropPress = CLLocation()
    
    @IBOutlet weak var cameraView: UIView!
    
    @IBOutlet weak var fromPhoneButton: UIButton!
    
    @IBOutlet weak var recordButton: UIButton!
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var switchCameraButton: UIButton!
   
    @IBOutlet weak var renderingUILabel: UILabel!
    
    
    //Setting Up Video
    var session: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    
    
    
    var isFrontCamera = false
    
    var myImage = UIImage()
    
    let imagePicker = UIImagePickerController()
    
    @IBAction func switchCameraDidTouch(_ sender: AnyObject) {
        if (isFrontCamera){
            switchCameraButton.setImage(UIImage(named: "face-camera-button"), for: UIControlState())
            setupCamera(isFront: isFrontCamera)
            isFrontCamera = false
        }
        else{
            switchCameraButton.setImage(UIImage(named: "main-camera-button"), for: UIControlState())
            setupCamera(isFront: isFrontCamera)
            isFrontCamera = true
        }
    } 

    @IBAction func fromPhoneDidTouch(_ sender: AnyObject) {
        self.present(imagePicker, animated: true,
                                   completion: nil)
    }
    @IBAction func backButtonDidTouch(_ sender: AnyObject) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func recordButtonDidTouch(_ sender: AnyObject) {
        if let videoConnection = stillImageOutput!.connection(withMediaType: AVMediaTypeVideo) {
            // ...
            // Code for photo capture goes here...
            recordButton.isEnabled = false
            
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in
                // ...
                // Process the image data (sampleBuffer) here to get an image file we can put in our captureImageView
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProvider(data: imageData as! CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
                    let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                    
                    let vc: ImageViewController? = self.storyboard?.instantiateViewController(withIdentifier: "ImageVC") as? ImageViewController
                    if let validVC: ImageViewController = vc{
                        validVC.image = image
                        
                        
                        validVC.isFrontCamera = self.isFrontCamera
                        
                        
                        validVC.locationAtDropPress = self.locationAtDropPress
                        self.renderingUILabel.isHidden = false
                        self.navigationController?.pushViewController(validVC, animated: true)
    
                        self.session?.stopRunning()
                        
        
                        
                        
                    }
                    
                }
            })
        }

        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        
        
        
        initializeCameraView()
        
        initializeImagePicker()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        recordButton.isEnabled = true
        renderingUILabel.isHidden = true
        
        //Initially should show back camera and smiley face for switch camera button
        setupCamera (isFront: true)
        switchCameraButton.setImage(UIImage(named: "face-camera-button"), for: UIControlState.normal)

        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoPreviewLayer!.frame = cameraView.bounds
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ImageSegue"){
            let nextView = segue.destination as! ImageViewController
            nextView.locationAtDropPress = self.locationAtDropPress
        }
//        else if (segue.identifier == "VideoSegue"){
//            let nextView = segue.destination as! VideoViewController
//            nextView.locationAtDropPress = self.locationAtDropPress
//            nextView.user = self.user
//        }
    }
    

    
    func initializeCameraView(){
        
        
        let pinchToZoom = UIPinchGestureRecognizer(target: self, action: #selector(zoom))
        cameraView.addGestureRecognizer(pinchToZoom)
        
        
        let swipeToDismiss = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight))
        cameraView.addGestureRecognizer(swipeToDismiss)
        //TODO: Grab a still of the   facing camera, and set that image to the switchcamera button
        
        
        
              
    }
    
    func swipeRight(_ gesture: UISwipeGestureRecognizer){
        if (gesture.direction == .right){
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func zoom(_ gesture: UIPinchGestureRecognizer){
        CGAffineTransform(scaleX: gesture.scale, y: gesture.scale)
    }
    
    
    func initializeImagePicker(){
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.savedPhotosAlbum
        imagePicker.mediaTypes = NSArray(objects: kUTTypeImage) as! [String]
        imagePicker.allowsEditing = false
    }
    
    
    //MARK: For Pictures

    func setupCamera (isFront: Bool){
        session = AVCaptureSession()
        //Set Capture Quality here:
        session!.sessionPreset = AVCaptureSessionPresetPhoto
        
        
        var camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        //session!.sessionPreset = AVCaptureSessionPresetPhoto
        if (isFront){
            camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        else{
            let videoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
            
            
            for device in videoDevices!{
                let device = device as! AVCaptureDevice
                if device.position == AVCaptureDevicePosition.front {
                    camera = device
                }
            }
        }
        
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: camera)
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        
        
        if error == nil && session!.canAddInput(input) {
            session!.addInput(input)
            // ...
            // The remainder of the session setup will go here...
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            
            if session!.canAddOutput(stillImageOutput) {
                session!.addOutput(stillImageOutput)
                // ...
                // Configure the Live Preview here...
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                cameraView.layer.addSublayer(videoPreviewLayer!)
                cameraView.layer.addSublayer(recordButton.layer)
                cameraView.layer.addSublayer(switchCameraButton.layer)
                cameraView.layer.addSublayer(fromPhoneButton.layer)
                cameraView.layer.addSublayer(backButton.layer)
                session!.startRunning()
                videoPreviewLayer!.frame = cameraView.bounds
            }
        }
        
    }

    
    func directoryVideoURL() -> (newPath: URL, path: URL) {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        let videoURL = documentDirectory.appendingPathComponent("video.mp4")
        return (videoURL, documentDirectory)
    }
}
        
extension ViewController: UIImagePickerControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            
            // Media is an image
            let image = info[UIImagePickerControllerOriginalImage] as? UIImage
            
            let vc: ImageViewController? = self.storyboard?.instantiateViewController(withIdentifier: "ImageVC") as? ImageViewController
            
            if let validVC: ImageViewController = vc{
                if let capturedImage = image {
                    
                    validVC.image = image
                    validVC.locationAtDropPress = locationAtDropPress
                    self.navigationController?.pushViewController(validVC, animated: true)
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else if mediaType.isEqual(to: kUTTypeMovie as String) {
            // Media is a video currently removed due to space issues and video length restrictions not being implemented

        }
        
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }

}
