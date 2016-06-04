//
//  CreatePostVC.swift
//  Fart Club
//
//  Created by Ben Sullivan on 19/05/2016.
//  Copyright © 2016 Sullivan Applications. All rights reserved.
//

import UIKit
import Spring
import AVFoundation
import FDWaveformView
import FirebaseStorage

protocol AudioPlayerDelegate {
  
  func audioRecorded()
}

class CreatePostVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AudioPlayerDelegate {
  
  @IBOutlet weak var recordButton: SpringButton!
  @IBOutlet weak var playButton: SpringButton!
  @IBOutlet weak var pauseButton: SpringButton!
  
  @IBOutlet weak var descriptionTextField: MaterialTextField!
  @IBOutlet weak var controlsBackground: MaterialView!
  @IBOutlet weak var waveFormView: FDWaveformView!
  var checkAudioRecorded = Bool()
  @IBOutlet weak var selectedImage: UIImageView!
  
  var selectedImagePath = NSURL?()
  
  private let imagePicker = UIImagePickerController()
  
  var pressed = false
  //  var recordingSuccess = Bool()
  //  var recordingSession: AVAudioSession!
  //  var audioRecorder: AVAudioRecorder!
  //  var player = AVAudioPlayer()
  
  //MARK: - VC Lifecycle
  
  override func viewDidLoad() {
    
    postedButton.alpha = 0
    postingButton.alpha = 0
    
    AudioControls.shared.delegate = self
    
    AudioControls.shared.setupRecording()
    
    imagePicker.delegate = self
    
    playButton.alpha = 0
    pauseButton.alpha = 0
    
    controlsBackground.backgroundColor = UIColor(colorLiteralRed: 105/255, green: 184/255, blue: 252/255, alpha: 1.0)
    
    playButton.imageView?.contentMode = .ScaleAspectFit
    pauseButton.imageView?.contentMode = .ScaleAspectFit
    recordButton.imageView?.contentMode = .ScaleAspectFit
  }
  
  //MARK: - Audio controls
  
  @IBAction func playButtonPressed(sender: SpringButton!) {
    AudioControls.shared.play(NSURL(fileURLWithPath: String(getDocumentsDirectory()) + "/recording.m4a"))
  }
  
  @IBAction func pauseButtonPressed(sender: AnyObject) {
    AudioControls.shared.pause()
  }
  
  @IBAction func recordButtonPressed(sender: UIButton) {
    
    AudioControls.shared.recordTapped()
    animateRecordControls()
  }
  
  func audioRecorded() {
    showWaveForm(NSURL(fileURLWithPath: String(getDocumentsDirectory()) + "/recording.m4a"))
  }
  
  func showWaveForm(fileURL: NSURL) {
    
    self.waveFormView.audioURL = fileURL
    self.waveFormView.doesAllowScrubbing = false
    self.waveFormView.alpha = 1
    checkAudioRecorded = true

  }
  
  func waveformViewDidRender(waveformView: FDWaveformView) {
    self.waveFormView.alpha = 1
  }
  
  override func viewDidAppear(animated: Bool) {
    
    AppState.shared.currentState = .CreatingPost
  }
  
  @IBAction func takePhotoButtonPressed(sender: AnyObject) {
    
    if UIImagePickerController.isSourceTypeAvailable(.Camera) {
      imagePickerAlert()
    } else {
      presentViewController(imagePicker, animated: true, completion: nil)
    }
  }
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    
    dismissViewControllerAnimated(true, completion: nil)
    
    let image = info[UIImagePickerControllerOriginalImage] as? UIImage
    selectedImage.image = image
    
    let saveDirectory = String(getDocumentsDirectory()) + "/images/tempImage.jpg"
    
    let tempImage = info[UIImagePickerControllerOriginalImage] as! UIImage
    
    saveImage(tempImage, path: saveDirectory)
    
    print("Did finish picking image - ", saveDirectory)
  }
  
  func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
    
    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
    image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
  }
  
  func saveImage (image: UIImage, path: String) -> Bool {
    
    let compressedImage = resizeImage(image, newWidth: 1536)
    let jpgImageData = UIImageJPEGRepresentation(compressedImage, 0)
    let result = jpgImageData!.writeToFile(String(path), atomically: true)
    
    selectedImagePath = NSURL(fileURLWithPath: path)
    
    return result
  }
  
  @IBOutlet weak var postingButton: SpringLabel!
  @IBOutlet weak var postedButton: SpringLabel!
  
  @IBAction func postBarButtonPressed(sender: AnyObject) {

    if checkAudioRecorded == true {

      recordButton.alpha = 0
      playButton.alpha = 0
      pauseButton.alpha = 0
      postingButton.autohide = false
      postingButton.animation = "squeezeRight"
      postingButton.damping = 1
      postingButton.animate()
      postToFirebase()
      
    } else {
      missingAudioAlert()
    }
  }
  
  func postToFirebase() {
    
    print("Posting to firebase")
    //generates new ID for URL
    let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
    
    let audioPath = NSURL(fileURLWithPath: String(getDocumentsDirectory()) + "/recording.m4a")
    
    CreatePost.shared.uploadAudio(audioPath, firebaseReference: firebasePost.key)
    
    guard let username = NSUserDefaults.standardUserDefaults().valueForKey("username") else { print("no username"); return }
    
    guard let userKey = NSUserDefaults.standardUserDefaults().valueForKey(Constants.shared.KEY_UID) as? String else { print("no username key"); return }
    
    var post: [String: AnyObject] = [
      "description" : descriptionTextField.text!,
      "likes": 0,
      "audio": "audio/\(firebasePost.key).m4a",
      "user": username,
      "date": String(NSDate()),
      "userKey": userKey
    ]
    
    if let imagePath = selectedImagePath {
      
      uploadImage(imagePath, firebaseReference: firebasePost.key)
      
      post["imageUrl"] = "images/\(firebasePost.key).jpg"
      
    } else {
      
      self.postingButton.x = 300
      self.postingButton.animateTo()
      
      self.postedButton.autohide = false
      self.postedButton.animation = "squeezeRight"
      self.postedButton.damping = 1
      self.postedButton.animateNext({
        
        self.postedButton.delay = 2
        self.postedButton.animation = "squeezeLeft"
        self.postedButton.animateTo()
        self.recordButton.autohide = true
        self.recordButton.delay = 2.5
        self.recordButton.animation = "fadeIn"
        self.recordButton.animate()
        
        self.playButton.autohide = true
        self.playButton.damping = 0.8
        self.playButton.x = 0
        self.playButton.animateTo()
        self.playButton.alpha = 0
        
        self.pauseButton.autohide = true
        self.pauseButton.damping = 0.8
        self.pauseButton.x = 0
        self.pauseButton.animateTo()
        self.pauseButton.alpha = 0

      })
      
      self.checkAudioRecorded = false
    }
    
    //save to database
    firebasePost.setValue(post)
    
    descriptionTextField.text = ""
    selectedImage.image = UIImage(named: "camera")
    print("Done")
    
    savePostToUser(firebasePost.key)
    
    
    
  }
  
  func savePostToUser(postKey: String) {
    
    let firebasePost = DataService.ds.REF_USER_CURRENT.child("posts").child(postKey)
    
    firebasePost.setValue(postKey)
    
  }
  
  
  func uploadImage(localFile: NSURL, firebaseReference: String) {
    
    
    
    print("uploadImage", localFile)
    let storageRef = FIRStorage.storage().reference()
    let riversRef = storageRef.child("images/\(firebaseReference).jpg")
    
    riversRef.putFile(localFile, metadata: nil) { metadata, error in
      print("putFile")
      guard let metadata = metadata where error == nil else { print("error", error); return }
      
      let downloadURL = metadata.downloadURL
      
      print("success", downloadURL)
      
      
      self.postingButton.x = 300
      self.postingButton.animateTo()
      
      self.postedButton.autohide = false
      self.postedButton.animation = "squeezeRight"
      self.postedButton.damping = 1
      self.postedButton.animateNext({
        
        self.postedButton.delay = 2
        self.postedButton.animation = "squeezeLeft"
        self.postedButton.animateTo()
        self.recordButton.autohide = true
        self.recordButton.delay = 2.5
        
        self.playButton.damping = 0.8
        self.playButton.x = 0
        self.playButton.animateTo()
        self.playButton.alpha = 0
        
        self.pauseButton.damping = 0.8
        self.pauseButton.x = 0
        self.pauseButton.animateTo()
        self.pauseButton.alpha = 0
        
        self.recordButton.animation = "fadeIn"
        self.recordButton.animate()
      })
      
      //      CreatePost.shared.downloadAudio(localFile)
    }
  }
  
  
  
  
  
  func getDocumentsDirectory() -> NSURL {
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    let documentsDirectory = paths[0]
    
    let url = NSURL(string: documentsDirectory)!
    
    return url
  }
  
  
  func missingAudioAlert() {
    
    let alert = UIAlertController(title: "No recording found", message: "Tap the microphone to start recording", preferredStyle: .Alert)
    
    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
    
    presentViewController(alert, animated: true, completion: nil)
  }
  
  func imagePickerAlert() {
    
    let alert = UIAlertController(title: "Share your fartistic side", message: "", preferredStyle: .ActionSheet)
    alert.popoverPresentationController?.sourceView = self.view
    
    alert.addAction(UIAlertAction(title: "Fartograph", style: .Default, handler: { action in
      
      print("camera")
      self.imagePicker.sourceType = .Camera
      self.presentViewController(self.imagePicker, animated: true, completion: nil)
      
    }))
    
    
    alert.addAction(UIAlertAction(title: "Farto Library", style: .Default, handler: { action in
      
      print("photo library")
      
      self.imagePicker.sourceType = .PhotoLibrary
      self.presentViewController(self.imagePicker, animated: true, completion: nil)
      
    }))
    
    alert.addAction(UIAlertAction(title: "Blow Off", style: .Cancel, handler: nil))
    
    presentViewController(alert, animated: true, completion: nil)
  }
  
  
  
  //MARK: - Animations etc...
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    
    self.view.endEditing(true)
  }
  
  func animateRecordButton() -> Bool {
    self.recordButton.duration = 1
    self.recordButton.animation = "pop"
    if self.playButton.alpha == 1 {
      return true
    }
    return false
  }
  
  func animateRecordControls() {
    
    if !pressed {
      //      timerViewCover.alpha = 1
      
      //      timerMic.y = 100
      //      timerMic.duration = 10
      //      timerMic.animateTo()
      
      //      recordButton.setImage(UIImage(named: "micIconRecording"), forState: .Normal)
      
      controlsBackground.backgroundColor = UIColor(colorLiteralRed: 252/255, green: 71/255, blue: 103/255, alpha: 1.0)
      
      recordButton.duration = 1
      recordButton.animation = "pop"
      
      recordButton.animateToNext {
        self.animateRecordButton()
        
        self.recordButton.animateToNext {
          if self.animateRecordButton() {
            return
          }
          
          self.recordButton.animateToNext {
            if self.animateRecordButton() {
              return
            }
            
            self.recordButton.animateToNext {
              if self.animateRecordButton() {
                return
              }
              
              self.recordButton.animateToNext {
                if self.animateRecordButton() {
                  return
                }
                
                self.recordButton.animateToNext {
                  if self.animateRecordButton() {
                    return
                  }
                  
                  self.recordButton.animateToNext {
                    if self.animateRecordButton() {
                      return
                    }
                    
                    self.recordButton.animateToNext {
                      if self.animateRecordButton() {
                        return
                      }
                      
                      self.recordButton.animateToNext {
                        if self.animateRecordButton() {
                          return
                        }
                        
                        self.recordButton.animateToNext {
                          if self.animateRecordButton() {
                            return
                          }
                          
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      pressed = true
      
      if playButton.alpha == 1 {
        
        playButton.damping = 0.8
        playButton.x = 0
        playButton.animateTo()
        playButton.alpha = 0
        
        pauseButton.damping = 0.8
        pauseButton.x = 0
        pauseButton.animateTo()
        pauseButton.alpha = 0
        
      }
      
    } else {
      
      pauseButton.alpha = 1
      
      playButton.damping = 0.8
      playButton.x = -self.view.bounds.width / 3.5
      playButton.animateTo()
      
      pauseButton.alpha = 1
      
      pauseButton.damping = 0.8
      pauseButton.x = self.view.bounds.width / 3.5
      pauseButton.animateTo()
      
      controlsBackground.backgroundColor = UIColor(colorLiteralRed: 105/255, green: 184/255, blue: 252/255, alpha: 1.0)
      
      pressed = false
    }
    
  }
}

class Pootorial: UIViewController {
  
  @IBOutlet weak var materialView: MaterialView!
  
  @IBOutlet weak var recordButton: SpringButton!
  
  @IBAction func dismissButtonPressed(sender: AnyObject) {
    
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func viewDidLoad() {
    
    
    
    recordButton.imageView?.contentMode = .ScaleAspectFit
    
    //    materialView.backgroundColor = UIColor(colorLiteralRed: 105/255, green: 184/255, blue: 252/255, alpha: 1.0)
  }
  
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return .LightContent
  }
}
