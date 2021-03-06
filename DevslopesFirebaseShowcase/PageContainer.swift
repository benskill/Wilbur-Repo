//
//  PageContainer.swift
//  Wilbur
//
//  Created by Ben Sullivan on 17/06/2016.
//  Copyright © 2016 Sullivan Applications. All rights reserved.
//

import UIKit

class PageContainer: UIViewController, UpdateNavButtonsDelegate, NavigationBarDelegate {
  
  @IBOutlet weak var createPostButton: UIButton!
  @IBOutlet weak var feedButton: UIButton!
  @IBOutlet weak var completeButton: UIButton!
  @IBOutlet weak var postButton: UIButton!
  
  var selectedPost: Post? = nil
  var selectedPostImage: UIImage? = nil
  var textFrame = CGRect()
  
  weak var createPostDelegate: PostButtonPressedDelegate? = nil
  weak var navigationBarDelegate: NavigationBarDelegate? = nil {
    didSet {
      
    }
  }
  
  private struct Colours {
    static let highlighted = UIColor(colorLiteralRed: 223/255, green: 223/255, blue: 230/255, alpha: 1)
    static let standard = UIColor(colorLiteralRed: 239/255, green: 239/255, blue: 244/255, alpha: 1)
  }
  
  //MARK: - VC LIFECYCLE
  
  override func viewDidLoad() {
    
    postButton.alpha = 0
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PageContainer.customCellCommentButtonPressed(_:)), name: "segueToComments", object: nil)
  }
  
  override func viewWillAppear(animated: Bool) {
    
    if AppState.shared.currentState != .CreatingPost {
      postButton.alpha = 0
    }
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
    if segue.identifier == Constants.Segues.embedSegue.rawValue {
      
      if let dest = segue.destinationViewController as? PagingVC {
        
        dest.navButtonsDelegate = self
        dest.rootController = self
        navigationBarDelegate = dest
      }
    }
    
    if segue.identifier == Constants.Segues.comments.rawValue {
      
      if let dest = segue.destinationViewController as? CommentsVC {
        
        dest.post = selectedPost
        dest.postImage = selectedPostImage
        dest.textFrame = textFrame
        
        selectedPost = nil
        selectedPostImage = nil
      }
    }
    
  }
  
  
  //MARK: - BUTTONS
  
  @IBAction func profileButtonPressed(sender: AnyObject) {
    performSegueWithIdentifier(Constants.Segues.showProfile.rawValue, sender: self)
  }
  
  @IBAction func postButtonPressed(sender: AnyObject) {
    postButtonPressed()
    
  }
  
  @IBAction func feedButton(sender: AnyObject) {
    didSelectSegment(1)
    updateColours(1)
    UIView.animateWithDuration(0.2, animations: {
      self.postButton.alpha = 0
    })
    
  }
  
  @IBAction func createPostButton(sender: AnyObject) {
    
    didSelectSegment(0)

    updateColours(0)
    UIView.animateWithDuration(0.5, animations: {
      self.postButton.alpha = 1
    })

  }
  
  @IBAction func completeButton(sender: AnyObject) {
    didSelectSegment(2)
    updateColours(2)
    UIView.animateWithDuration(0.2, animations: {
      self.postButton.alpha = 0
    })
    
  }
  
  
  //MARK: - DELEGATE FUNCTIONS
  
  func postButtonPressed() {
    
    createPostDelegate?.postButtonPressed()
  }
  
  //Notifies paging VC to scroll to selected segment
  func didSelectSegment(segment: Int) {
    
    navigationBarDelegate?.didSelectSegment(segment)
  }
  
  func customCellCommentButtonPressed(notification: NSNotification) {
    
    if let post = notification.userInfo!["post"] as? Wrap<Post> {
      
      if let image = notification.userInfo!["image"] as? UIImage {
        
        selectedPostImage = image
        selectedPost = post.wrappedValue
        
        if let text = notification.userInfo!["text"] as? UILabel {

        textFrame = text.frame
        
        performSegueWithIdentifier("comments", sender: self)
          
        }
        
        
      } else { //if there is no image
        selectedPost = post.wrappedValue
        performSegueWithIdentifier("comments", sender: self)
        
      }
      
    }
  }
  
  
  //MARK: - STYLE NAV BUTTONS
  
  func updateNavButtons() {
    
    switch AppState.shared.currentState {
      
    case .CreatingPost:
      updateColours(0)
      UIView.animateWithDuration(0.5, animations: {
        self.postButton.alpha = 1
      })
    case .Feed:
      updateColours(1)
      UIView.animateWithDuration(0.2, animations: {
        self.postButton.alpha = 0
      })
    case .Answered:
      updateColours(2)
      UIView.animateWithDuration(0.2, animations: {
        self.postButton.alpha = 0
      })
    default:
      print("PageContainer, updateNavButtons default case")
    }
  }
  
  func updateColours(segment: Int) {
    
    switch segment {
      
    case 0:
      createPostButton.backgroundColor = Colours.highlighted
      feedButton.backgroundColor = Colours.standard
      completeButton.backgroundColor = Colours.standard
      
    case 1:
      createPostButton.backgroundColor = Colours.standard
      feedButton.backgroundColor = Colours.highlighted
      completeButton.backgroundColor = Colours.standard
      
    case 2:
      createPostButton.backgroundColor = Colours.standard
      feedButton.backgroundColor = Colours.standard
      completeButton.backgroundColor = Colours.highlighted
      
    default:
      print("Page Container, updateColours, default case")
    }
  }
  
  
  //MARK: - MISC FUNCTIONS
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return .LightContent
  }
}
