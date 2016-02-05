//
//  ProfileVC.swift
//  Showcase-app
//
//  Created by Aris Doxakis on 2/3/16.
//  Copyright © 2016 DASoftware. All rights reserved.
//

import UIKit
import Firebase
import Alamofire

class ProfileVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var usernameLbl: MaterialTextField!
    @IBOutlet weak var userImage: UIImageView!
    
    var imagePicker: UIImagePickerController!
    var userRef: Firebase!
    
    var imageSelected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        userRef = DataService.ds.REF_USER_CURRENT.childByAppendingPath("username")
        
        userRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
            if let exists = snapshot.value as? String {
                self.usernameLbl.text = "\(exists)"
            }
        })
        
        DataService.ds.REF_USER_CURRENT.childByAppendingPath("profileImg").observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
            if let imgUrl = snapshot.value as? String {
                let request = Alamofire.request(.GET, imgUrl).validate(contentType: ["image/*"]).response(completionHandler: { (request, Response, data, err) -> Void in
                    if err == nil {
                        let img = UIImage(data: data!)!
                        self.userImage.image = img
                        self.roundingUIView(self.userImage, cornerRadiusParam: 20.0)
                    }
                })
            }
        })
    }
    
    @IBAction func selectImage(sender: UITapGestureRecognizer) {
        presentViewController(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        userImage.image = image
        imageSelected = true
    }
    
    @IBAction func saveProfile(sender: AnyObject) {
        userRef.setValue(usernameLbl.text)
        
        if let img = userImage.image where imageSelected == true {
            
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
                                        DataService.ds.REF_USER_CURRENT.childByAppendingPath("profileImg").setValue(imgLink)
                                        
                                        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
                                    }
                                }
                            }
                        })
                    case .Failure(let err):
                        print(err)
                    }
            }
        }
    }
    
    private func roundingUIView(let aView: UIView!, let cornerRadiusParam: CGFloat!) {
        aView.clipsToBounds = true
        aView.layer.cornerRadius = cornerRadiusParam
    }
    
}
