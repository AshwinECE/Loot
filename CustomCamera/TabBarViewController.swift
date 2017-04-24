//
//  TabBarViewController.swift
//  CustomCamera
//
//  Created by It's Happen Inc. on 2016-06-10.
//  Copyright © 2016 It's Happen Inc. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    
    var dropButton = UIButton(type: UIButtonType.custom)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedIndex = 3
        
        self.tabBarController?.tabBar.itemPositioning = .centered
        self.tabBarController?.tabBar.itemSpacing = 100
        
        
        let buttonImage = UIImage(named: "plus-lootBag-drop-button")
        
        dropButton.frame = CGRect(x: 0.0, y: 0.0, width: (((buttonImage?.size.width)!)), height: (buttonImage?.size.height)!)
        dropButton.setImage(UIImage(named: "plus-lootBag-drop-button"), for: UIControlState())
        
        dropButton.addTarget(self, action: #selector (buttonAction), for: UIControlEvents.touchUpInside)
        
        let heightDiff = (buttonImage?.size.height)! - self.tabBar.frame.size.height
        
        if (heightDiff < 0){
            dropButton.center = self.tabBar.center
        }
        else{
            var center = self.tabBar.center
            center.y = center.y - heightDiff/2.0
            dropButton.center = center
        }
        
        self.view.addSubview(dropButton)
        
        
        // Do any additional setup after loading the view.
    }
    
    func buttonAction (_ sender: UIButton!){
        //want to notify viewController
        
        if Reachability.isConnectedToNetwork(){
            NotificationCenter.default.post(name: Notification.Name(rawValue: "drop-button-touched"), object: nil)
        }else{
            //No internet connection so don't let user take a picture
            let alertController = UIAlertController(title: "Error", message: "What are you doing? Connect to the internet first.", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            
            present(alertController, animated: true, completion: nil)

        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
