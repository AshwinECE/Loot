//
//  MessagesViewController.swift
//  CustomCamera
//
//  Created by Akshay Sampath on 2016-06-25.
//  Copyright © 2016 Akshay Sampath. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import FirebaseAuth
import JSQMessagesViewController
import JSQSystemSoundPlayer
import FirebaseMessaging

class MessagesViewController: JSQMessagesViewController{
    
    var lootItemToChat = LootItem()
    
    var messages = [JSQMessage]()
    
    var user = ""
    
    var avatars = Dictionary<String, UIImage>()
    var outgoingBubbleImageView = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
    var incomingBubbleImageView = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    var senderImageUrl: String!
    var batchMessages = true
    
    private var _refHandle: FIRDatabaseHandle!
    var ref: FIRDatabaseReference!
    var storageRef: FIRStorageReference!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        inputToolbar.contentView.leftBarButtonItem = nil
        automaticallyScrollsToMostRecentMessage = true
        //navigationController?.navigationBar.topItem?.title = "Logout"
        
        print(lootItemToChat.itemID)
        
        self.collectionView.reloadData()
        self.senderDisplayName = user
        self.senderId = user
        
        
        setupFirebase()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupFirebase() {
        // *** STEP 2: SETUP FIREBASE
        
    ref = FIRDatabase.database().referenceFromURL("https://loot-c340a.firebaseio.com/")
        
        ////
//                        _refHandle = self.ref.root.observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
//                            //self.loot.append(snapshot)
//                 })
        
  //       *** STEP 4: RECEIVE MESSAGES FROM FIREBASE (limited to latest 25 messages)
        ref.root.child("Messages").child(lootItemToChat.itemID).observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            
            if (snapshot.exists()){
                let postDict = snapshot.value as! [String : AnyObject]
                    print (postDict)
            
                for (key,value) in postDict{
                    let text = (postDict[key]!["text"]) as? String
                    let sender = (postDict[key]!["sender"]!)  as? String
            
                    let message = JSQMessage(senderId: sender, displayName: sender, text: text)
                    if self.messages.contains(message){
                
                    }else{
                        self.messages.append(message)
                    }
                self.finishReceivingMessage()
                }
            }else{
                
            }
        })
   }
    
    func sendMessage(text: String!, sender: String!) {
        // *** STEP 3: ADD A MESSAGE TO FIREBASE
        ref.root.child("Messages").child(lootItemToChat.itemID).childByAutoId().setValue([
            "text":text,
            "sender":sender
            ])
    }
    
    func tempSendMessage(text: String!, sender: String!) {
        let message = JSQMessage(senderId: sender, displayName: sender, text: text)
        messages.append(message)
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        self.sendMessage(text, sender: senderDisplayName)
            
                let message = JSQMessage(senderId: senderDisplayName, displayName: senderDisplayName, text: text)
            
                if self.messages.contains(message){
                
                }else{
                    self.messages.append(message)
                }
            self.finishSendingMessage()
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        if message.senderDisplayName == user {
            cell.textView.textColor = UIColor.whiteColor()
        } else {
            cell.textView.textColor = UIColor.blackColor()
        }
        
        //cell.cellTopLabel.textInsets = UIEdgeInsetsMake(0, 20.0, 0, 0)
        cell.messageBubbleTopLabel.textInsets = UIEdgeInsetsMake(0, 20.0, 0, 0)
        //cell.messageBubbleTopLabel.textInsets = UIEdgeInsetsMake(0, 10.0, 0, 0)
        cell.cellBottomLabel.textInsets = UIEdgeInsetsMake(0, 10.0, 0, 0)
        
        
        let attributes : [String:AnyObject] = [NSForegroundColorAttributeName:cell.textView.textColor!, NSUnderlineStyleAttributeName: 1]
        cell.textView.linkTextAttributes = attributes
        
        //        cell.textView.linkTextAttributes = [NSForegroundColorAttributeName: cell.textView.textColor,
        //            NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle]
        return cell

    }

//    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
//        
//        let message = messages[indexPath.item]
//        
//        return NSAttributedString(string: message.senderDisplayName)
//    }
    
//    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
//        return 20.0
//    }
    
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        
        var data = self.messages[indexPath.row]
        return data
        
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message: JSQMessage = self.messages[indexPath.item]
        
        return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 10.0
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        
        return NSAttributedString(string: message.senderDisplayName)
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 20.0
    }
    
    func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 10.0
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let message = messages[indexPath.item]
        
        if message.senderDisplayName == user{
            return self.outgoingBubbleImageView
        }else{
            return self.incomingBubbleImageView
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
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
