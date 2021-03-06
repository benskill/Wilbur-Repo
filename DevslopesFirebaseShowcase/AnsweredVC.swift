//
//  Answered
//  Wilbur
//
//  Created by Ben Sullivan on 16/05/2016.
//  Copyright © 2016 Sullivan Applications. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation
import FirebaseStorage

class AnsweredVC: UIViewController, UITableViewDelegate, UITableViewDataSource, PostCellDelegate, ReloadTableDelegate {
  
  @IBOutlet weak var tableView: UITableView!
    
  //MARK: - VC LIFECYCLE
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AnsweredVC.reloadTable), name: "reloadTables", object: nil)
    
    self.tableView.estimatedRowHeight = 300
    self.tableView.rowHeight = UITableViewAutomaticDimension
    
    self.tableView.scrollsToTop = false
    DataService.ds.delegate = self
    DataService.ds.downloadTableContent()
    
    tableView.delegate = self
    tableView.dataSource = self
  }
  
  
  override func viewWillAppear(animated: Bool) {
    
    if AppState.shared.currentState == .PresentLoginFromComments {
      
      dismissViewControllerAnimated(false, completion: nil)
      
    } else {
      
      AppState.shared.currentState = .Answered
      tableView.reloadData()
    }
    
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
    if segue.identifier == Constants.Segues.showProfile.rawValue {
      let backItem = UIBarButtonItem()
      backItem.title = "Back"
      navigationItem.backBarButtonItem = backItem
    }
  }
  
  //MARK: - BUTTONS
  
  @IBAction func profileButtonPressed(sender: UIButton) {
    performSegueWithIdentifier(Constants.Segues.showProfile.rawValue, sender: self)
  }
  
  
  //MARK: - TABLE VIEW
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return DataService.ds.answeredPosts.count ?? 0
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    if AppState.shared.currentState == .Answered {
      
      if let cell = tableView.dequeueReusableCellWithIdentifier("answeredCell") as? AnsweredCell {

        print("indexPath = ", indexPath.row)
        
        let post = DataService.ds.answeredPosts[indexPath.row]
        
        var img: UIImage?
        var profileImg: UIImage?
        
        cell.showcaseImg.hidden = false
        cell.showcaseImg.image = nil
        cell.profileImg.hidden = false
        cell.profileImg.image = nil
        
        if let url = post.imageUrl {
          img = Cache.shared.imageCache.objectForKey(url) as? UIImage
          cell.showcaseImg.hidden = false
          cell.showcaseImg.image = UIImage(named: "DownloadingImageBackground")
        }
        
        if let profileImage = Cache.shared.profileImageCache.objectForKey(post.userKey) as? UIImage {
          profileImg = profileImage
        }
        
        cell.delegate = self
        cell.reloadTableDelegate = self
        cell.configureCell(post, img: img, profileImg: profileImg)
        
        return cell
      }
    }
    return UITableViewCell()
  }
  
  
  //MARK - POST CELL DELEGATE
  
  func reloadTable() {
    
//    tableView.reloadData()
    
  }
  
  func showAlert(post: Post) {
    displayAlert(post)
  }
  
  func customCellCommentButtonPressed() {
    
    performSegueWithIdentifier("showComments", sender: self)
  }
  
  
  //MARK: - ALERTS
  
  func displayAlert(post: Post) {
    
    guard let user = DataService.ds.currentUserKey else { guestAlert(); return }
    
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
    
    //post belongs to user
    if post.userKey == user {
      
      //Potentially change this to mark as unanswered
//      alert.addAction(UIAlertAction(title: "Update answer", style: .Default, handler: { (action) in
//        
////        DataService.ds.markPostAsAnswered(post)
//        
//      }))
      
      alert.addAction(UIAlertAction(title: "   Delete Post 👋", style: .Default, handler: { (action) in
        
        DataService.ds.deletePost(post)
        
      }))
      
    } else {
      
      alert.addAction(UIAlertAction(title: "Report", style: .Default, handler: { action in
        
        self.reportAlert(post)
        
      }))
      
      alert.addAction(UIAlertAction(title: "Block User", style: .Default, handler: { action in
        
        DataService.ds.blockUser(post)
        
      }))
      
    }
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
    
    self.presentViewController(alert, animated: true, completion: nil)
  }
  
  func reportAlert(post: Post) {
    
    let alert = UIAlertController(title: "Submit report", message: nil, preferredStyle: .Alert)
    
    alert.addTextFieldWithConfigurationHandler { (textField) in
      
      textField.placeholder = "Reason for report"
      textField.returnKeyType = .Default
    }
    
    alert.addAction(UIAlertAction(title: "Submit", style: .Default, handler: { (action) in
      
      DataService.ds.reportPost(post, reason: alert.textFields![0].text!)
      
    }))
    
    self.presentViewController(alert, animated: true, completion:  nil)
  }
  
  func guestAlert() {
    
    let alert = UIAlertController(title: "Function unavailable 😕", message: "You must be logged in to comment", preferredStyle: .Alert)
    
    alert.addAction(UIAlertAction(title: "Login", style: .Default, handler: { action in
      
      self.dismissViewControllerAnimated(false, completion: nil)
      
    }))
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
    
    self.presentViewController(alert, animated: true, completion: nil)
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return .LightContent
  }
  
}
