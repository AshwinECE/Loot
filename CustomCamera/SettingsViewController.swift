//
//  SettingsViewController.swift
//  CustomCamera
//
//  Created by It's Happen Inc. on 2016-10-06.
//  Copyright © 2016 It's Happen Inc. All rights reserved.
//

import UIKit
import Firebase

class SettingsViewController: UIViewController {

    var ref: FIRDatabaseReference!
    fileprivate var _refHandle: FIRDatabaseHandle!

    
    @IBOutlet weak var feedBackFormTextView: UITextView!
    
    @IBAction func sendFeedbackButtonDidTouch(_ sender: AnyObject) {
        //Want to pop up an alert saying thank you if form filled
        //Or an alert saying error - cant send empty form
        
        if (feedBackFormTextView.text == "" || feedBackFormTextView.text == "Tap to begin typing feedback..."){
            let alertController = UIAlertController(title: "Error", message: "Please enter your feedback first.", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
        
            present(alertController, animated: true, completion: nil)
        }
        else{
            //TODO: Save the feedback and send it to Firebase?
            
            
            let newFeedbackDict = ["feedback": feedBackFormTextView.text] as [String : Any]
            
            let feedbackID = UUID().uuidString
            
            self.ref.root.child("Feedback").child(feedbackID).setValue(newFeedbackDict)

            
            
            
            let alertController = UIAlertController(title: "Thank You", message: "You're awesome. We love hearing from you.", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: {
                action in
                self.feedBackFormTextView.text = "Tap to begin typing feedback..."
            })
            
            
            
            alertController.addAction(defaultAction)
            
            present(alertController, animated: true, completion: nil)
            
        }
    }
    
    func clearForm(){
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        configureDatabase()
        
        feedBackFormTextView.layer.borderColor = UIColor.black.cgColor
        feedBackFormTextView.layer.borderWidth = 1
        feedBackFormTextView.layer.cornerRadius = 10
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.topItem?.title = "Settings"
        
        self.navigationController?.isNavigationBarHidden = false

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureDatabase() {
        ref = FIRDatabase.database().reference()
        // Listen for new messages in the Firebase database
        _refHandle = self.ref.root.observe(.childAdded, with: { (snapshot) -> Void in
            //self.loot.append(snapshot)
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        feedBackFormTextView.endEditing(true)
        if (feedBackFormTextView.text == ""){
            feedBackFormTextView.text = "Tap to begin typing feedback..."
        }
    }

    
    func keyboardWasShown(notification: NSNotification) {
//        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        if (feedBackFormTextView.text == "Tap to begin typing feedback..."){
            feedBackFormTextView.text = ""
        }

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
