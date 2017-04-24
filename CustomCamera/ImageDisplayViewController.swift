 //
//  ImageDisplayViewController.swift
//  CustomCamera
//
//  Created by It's Happen Inc. on 2016-06-19.
//  Copyright © 2016 It's Happen Inc. All rights reserved.
//

import UIKit

class ImageDisplayViewController: UIViewController
{
    
    @IBOutlet weak var newImageView: UIImageView!
    
    @IBOutlet weak var captionLabel: UILabel!
    var imgString = ""
    var captionString = ""
    var fromImagePickUp = false

    override func viewDidLoad() {
        super.viewDidLoad()
  
        
            self.setNeedsStatusBarAppearanceUpdate()
        
            if (captionString == "" || captionString == "Tap to add a caption"){
               captionLabel.isHidden = true
            }
            else{
                captionLabel.isHidden = false
            }
            captionLabel.text = "  \(captionString)"
        
        
            let imgData = try? Data(contentsOf: URL(fileURLWithPath: imgString))
        
            let img = UIImage(data: imgData!)
        
        
            //need width to be screen width not just 365
            let imageScaled = self.resizeImage(img!, newWidth: 365)
        
            self.navigationController?.isNavigationBarHidden = true
            self.tabBarController?.tabBar.isHidden = true
        
            newImageView.image = imageScaled
        
            let tap = UITapGestureRecognizer(target: self, action: #selector(ImageDisplayViewController.dismissFullscreenImage(_:)))
        
            newImageView.addGestureRecognizer(tap)
        
            let zoom = UIPinchGestureRecognizer(target: self, action: #selector(ImageDisplayViewController.zoomfeature))
        
            newImageView.addGestureRecognizer(zoom)
        
        
            let swipeToDismiss = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight))
            newImageView.addGestureRecognizer(swipeToDismiss)
        
            // Do any additional setup after loading the view.
    }

    func swipeRight(_ gesture: UISwipeGestureRecognizer){
        if (gesture.direction == .right){
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }
    

    func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        self.navigationController?.isNavigationBarHidden = false
        self.tabBarController?.tabBar.isHidden = false
        
        if(fromImagePickUp){
            performSegue(withIdentifier: "UnwindToImagePickUp", sender: self)
        }
        else{
            self.navigationController?.popViewController(animated: true)
            
            
        }
    }
    func zoomfeature(_ gesture: UIPinchGestureRecognizer){
        CGAffineTransform(scaleX: gesture.scale, y: gesture.scale)
        gesture.scale = 1
        
    }
    
    func resizeImage(_ image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
