//
//  FeedVC.swift
// Wilbur
//
//  Created by Ben Sullivan on 16/05/2016.
//  Copyright © 2016 Sullivan Applications. All rights reserved.
//

import UIKit
import Firebase
import FDWaveformView
import AVFoundation
import FirebaseStorage

protocol PostCellDelegate: class {
  func showAlert(post: Post)
  func reloadTable()
  func customCellCommentButtonPressed()
}

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, PostCellDelegate {
  
  @IBOutlet weak var tableView: UITableView!
  private var cellImage: UIImage? = nil
  
  func reloadTable() {
    
    tableView.reloadData()
    
  }
  
  func customCellCommentButtonPressed() {
    
    performSegueWithIdentifier("showComments", sender: self)
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FeedVC.reloadTable), name: "imageSaved", object: nil)
    
    self.tableView.estimatedRowHeight = 300
    self.tableView.rowHeight = UITableViewAutomaticDimension
    
    self.tableView.scrollsToTop = false
    DataService.ds.delegate = self
    DataService.ds.downloadTableContent()
    
    AppState.shared.currentState = .Feed
    
    //    AudioControls.shared.setupRecording()
    
    tableView.delegate = self
    tableView.dataSource = self
    
    NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: #selector(self.checkLoggedIn), userInfo: nil, repeats: false)
  }
  
  
  override func viewWillAppear(animated: Bool) {
    
    AppState.shared.currentState = .Feed
    tableView.reloadData()
  }
  
  
  //MARK: - TABLE VIEW
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return DataService.ds.posts.count ?? 0
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    if AppState.shared.currentState == .Feed {
      
      if let cell = tableView.dequeueReusableCellWithIdentifier("postCell") as? PostCell {
        
        let post = DataService.ds.posts[indexPath.row]
        
        var img: UIImage?
        var profileImg: UIImage?
        
        cell.showcaseImg.hidden = true
        cell.showcaseImg.image = nil
        
        if let url = post.imageUrl {
          img = Cache.FeedVC.imageCache.objectForKey(url) as? UIImage
          cell.showcaseImg.hidden = false
          cell.showcaseImg.image = UIImage(named: "DownloadingImageBackground")
        }
        
        if let profileImage = Cache.FeedVC.profileImageCache.objectForKey(post.userKey) as? UIImage {
          
          profileImg = profileImage
          
          dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            
            if post.username == NSUserDefaults.standardUserDefaults().valueForKey("username") as? String && TempProfileImageStorage.shared.profileImage == nil {
              TempProfileImageStorage.shared.profileImage = profileImg
              
            }
              cell.profileImg.clipsToBounds = true
              cell.profileImg.layer.cornerRadius = cell.profileImg.layer.frame.width / 2
            
            dispatch_async(dispatch_get_main_queue(), {
              cell.profileImg.image = profileImg
            })
          }
          
        }
        
        cell.delegate = self
        cell.configureCell(post, img: img, profileImg: profileImg)
        
        return cell
      }
    }
    return UITableViewCell()
  }
  
  
  //MARK: - ALERTS
  
  func showAlert(post: Post) {
    displayDeleteAlert(post)
  }
  
  func displayDeleteAlert(post: Post) {
    
    let storageImageRef = FIRStorage.storage().reference()
    let postRef = DataService.ds.REF_POSTS.child(post.postKey) as FIRDatabaseReference!
    let userPostRef = DataService.ds.REF_USER_CURRENT.child("posts").child(post.postKey) as FIRDatabaseReference!
    
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
    
    if post.userKey == NSUserDefaults.standardUserDefaults().objectForKey(Constants.shared.KEY_UID) as! String {
      
      alert.addAction(UIAlertAction(title: "Mark as Answered", style: .Default, handler: { (action) in
        
        postRef.child("answered")
        postRef.setValue(true)
        
      }))
      
      alert.addAction(UIAlertAction(title: "Delete Post", style: .Default, handler: { (action) in
        
        userPostRef.removeValue()
        postRef.removeValue()
        
        let deleteMethod = storageImageRef.child("images").child(post.postKey + ".jpg")
        
        deleteMethod.deleteWithCompletion({ (error) in
          
          guard error == nil else { print("delete error", error.debugDescription) ; return }
          
          print("storage image removed")
        })
        
      }))
      
    } else {
      
      alert.addAction(UIAlertAction(title: "Report", style: .Default, handler: { (action) in
        
        self.reportAlert(post)
      
      }))
      
      alert.addAction(UIAlertAction(title: "Block User", style: .Default, handler: { (action) in
        
        
        
      }))
      
    }
    
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
    
    self.presentViewController(alert, animated: true, completion: nil)
    
  }
  
  func reportAlert(post: Post) {
    
    let userKey = NSUserDefaults.standardUserDefaults().objectForKey(Constants.shared.KEY_UID) as! String
    
    let alert = UIAlertController(title: "Submit report", message: nil, preferredStyle: .Alert)
    
    alert.addTextFieldWithConfigurationHandler { (textField) in
      
      textField.placeholder = "Reason for report"
      textField.returnKeyType = .Default
    }
    
    alert.addAction(UIAlertAction(title: "Submit", style: .Default, handler: { (action) in
      
      let reportText = alert.textFields![0].text
      let postRef = DataService.ds.REF_BASE.child("reportedPosts").child(post.postKey).child(userKey) as FIRDatabaseReference!
      
      postRef.setValue(reportText)
      
      //Post needs to be marked as reported or deleted
      
    }))
      
    self.presentViewController(alert, animated: true, completion:  nil)
  }
  
  //MARK: - OTHER FUNCTIONS
  
  func checkLoggedIn() {
    
    if DataService.ds.posts.isEmpty {
      NSUserDefaults.standardUserDefaults().setValue(nil, forKey: Constants.shared.KEY_UID)
      dismissViewControllerAnimated(true, completion: nil)
    }
  }
  
  
  @IBAction func profileButtonPressed(sender: UIButton) {
    performSegueWithIdentifier(Constants.sharedSegues.showProfile, sender: self)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
    if segue.identifier == Constants.sharedSegues.showProfile {
      let backItem = UIBarButtonItem()
      backItem.title = "Back"
      navigationItem.backBarButtonItem = backItem
    }
  }
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return .LightContent
  }
  
}
