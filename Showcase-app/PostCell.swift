//
//  PostCell.swift
//  Showcase-app
//
//  Created by Aris Doxakis on 1/29/16.
//  Copyright © 2016 DASoftware. All rights reserved.
//

import UIKit
import Alamofire
import Firebase

class PostCell: UITableViewCell {

    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var showCaseImg: UIImageView!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var likesImg: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    
    var post: Post!
    var request: Request?
    var likeRef: Firebase!
    var userRef: Firebase!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: "likeTapped:")
        tap.numberOfTapsRequired = 1
        likesImg.addGestureRecognizer(tap)
        likesImg.userInteractionEnabled = true
        
        self.roundingUIView(self.userImage, cornerRadiusParam: 150.0)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func drawRect(rect: CGRect) {
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true
        
        showCaseImg.clipsToBounds = true
    }
 
    func configureCell(post: Post, img: UIImage?) {
        self.post = post
        
        likeRef = DataService.ds.REF_USER_CURRENT.childByAppendingPath("likes").childByAppendingPath(post.postKey)
        userRef = DataService.ds.REF_USERS.childByAppendingPath(post.userId)
        
        self.descriptionText.text = post.postDescription
        self.likesLbl.text = "\(post.postLikes)"
        
        if post.postImgUrl != nil {
            if img != nil {
                // Load image from cache.
                self.showCaseImg.image = img
            } else {
                // Download image from internet using Alamofire async.
                request = Alamofire.request(.GET, post.postImgUrl!).validate(contentType: ["image/*"]).response(completionHandler: { (request, Response, data, err) -> Void in
                    if err == nil {
                        let img = UIImage(data: data!)!
                        self.showCaseImg.image = img
                        FeedVC.imageCache.setObject(img, forKey: post.postImgUrl!)
                    }
                })
            }
        } else {
            self.showCaseImg.hidden = true
        }
        
        likeRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
            if let doesNotExist = snapshot.value as? NSNull {
                self.likesImg.image = UIImage(named: "heart-empty")
            } else {
                self.likesImg.image = UIImage(named: "heart-full")
            }
        })
        
        userRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
            if let username = snapshot.value.objectForKey("username") as? String {
                self.usernameLbl.text = username
            }
        })
        
        userRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
            if let profileUrl = snapshot.value.objectForKey("profileImg") as? String {
                Alamofire.request(.GET, profileUrl).validate(contentType: ["image/*"]).response(completionHandler: { (request, Response, data, err) -> Void in
                    if err == nil {
                        let img = UIImage(data: data!)!
                        self.userImage.image = img
                        FeedVC.imageCache.setObject(img, forKey: post.userId)
                    }
                })
            }
        })

    }
    
    func likeTapped(sender: UITapGestureRecognizer) {
        likeRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
            if let doesNotExist = snapshot.value as? NSNull {
                self.likesImg.image = UIImage(named: "heart-full")
                self.post.adjustLikes(true)
                self.likeRef.setValue(true)
            } else {
                self.likesImg.image = UIImage(named: "heart-empty")
                self.post.adjustLikes(false)
                self.likeRef.removeValue()
            }
        })
    }
    
    private func roundingUIView(let aView: UIView!, let cornerRadiusParam: CGFloat!) {
        aView.clipsToBounds = true
        aView.layer.cornerRadius = cornerRadiusParam
    }
    
}
