//
//  FeedVC.swift
//  Showcase-app
//
//  Created by Aris Doxakis on 1/29/16.
//  Copyright © 2016 DASoftware. All rights reserved.
//

import UIKit
import Firebase
import Alamofire

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var imagePicker: UIImagePickerController!
    var imageSelected = false
    
    var posts: [Post] = []
    static var imageCache = NSCache()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var postTextField: UITextField!
    @IBOutlet weak var imageSelectorImg: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.estimatedRowHeight = 317
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        DataService.ds.REF_POSTS.observeEventType(.Value, withBlock: {snapshot in
            if let snapshots = snapshot.children.allObjects as? [FDataSnapshot] {
                self.posts = []
                
                for snap in snapshots {
                    if let postDict = snap.value as? Dictionary<String,AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        
                        self.posts.append(post)
                    }
                }
            }
            
            self.tableView.reloadData()
        })
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let post = posts[indexPath.row]
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as? PostCell {
            cell.request?.cancel()
            
            var img: UIImage?
            
            if let url = post.postImgUrl {
                img = FeedVC.imageCache.objectForKey(url) as? UIImage
            }
            
            cell.configureCell(post, img: img)
            
            return cell
        } else {
            return PostCell()
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = posts[indexPath.row]
        
        if post.postImgUrl == nil {
            return 150
        } else {
            return tableView.estimatedRowHeight
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageSelectorImg.image = image
        imageSelected = true
    }
    
    @IBAction func selectImage(sender: UITapGestureRecognizer) {
        presentViewController(imagePicker, animated: true, completion: nil)        
    }
    
    @IBAction func makePost(sender: AnyObject) {
        if let descr = postTextField.text where descr != "" {
            
            if let img = imageSelectorImg.image where imageSelected == true {
                
                let urlStr = "https://post.imageshack.us/upload_api.php"
                let nsUrl = NSURL(string: urlStr)!
                
                let imgData = UIImageJPEGRepresentation(img, 0.2)!
                
                Alamofire.upload(.POST, nsUrl, multipartFormData: { multipartFormData in
                    
                    multipartFormData.appendBodyPart(data: imgData, name: "fileupload", fileName: "image", mimeType: "image/jpg")
                    multipartFormData.appendBodyPart(data: IMAGE_SHACK_KEY, name: "key")
                    multipartFormData.appendBodyPart(data: IMAGE_SHACK_JSON, name: "format")
                    
                    }) { encodingResult in
                        
                        switch encodingResult {
                        case .Success(let upload, _, _):
                            upload.responseJSON(completionHandler: { response in
                                if let info = response.result.value as? Dictionary<String,AnyObject> {
                                    if let links = info["links"] as? Dictionary<String, AnyObject> {
                                        if let imgLink = links["image_link"] as? String {
                                            self.postToFirebase(imgLink)
                                        }
                                    }
                                }
                            })
                        case .Failure(let err):
                            print(err)
                        }
                }
            } else {
                self.postToFirebase(nil)
            }
        }
    }
    
    func postToFirebase(imgUrl: String?) {
        var post: Dictionary<String,AnyObject> = [
            "description": postTextField.text!,
            "likes": 0,
            "userId": "\(NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID)!)"
        ]
        
        if imgUrl != nil {
            post["img_url"] = imgUrl
        }
        
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        
        postTextField.text = ""
        imageSelectorImg.image = UIImage(named: "camera")
        tableView.reloadData()
        
        imageSelected = false
    }
    
}