//
//  ViewController.swift
//  Showcase-app
//
//  Created by Aris Doxakis on 1/29/16.
//  Copyright © 2016 DASoftware. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil {
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        }
    }

    @IBAction func emailBtnPressed(sender: UIButton) {
        if let email = emailField.text where email != "" {
            if let pwd = passwordField.text where pwd != "" {
                
                DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: { (error, authData) -> Void in
                    if error != nil {
                        if error.code == STATUS_ACCOUNT_NONEXIST {
                            // Create new user.
                            DataService.ds.REF_BASE.createUser(email, password: pwd, withValueCompletionBlock: { (error, result) -> Void in
                                if error != nil {
                                    self.showErrorAlert("Could not create account", msg: "Problem creating account. Try something else.")
                                } else {
                                    NSUserDefaults.standardUserDefaults().setValue(result[KEY_UID], forKey: KEY_UID)
                                    
                                    DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: {err, authData in
                                        let user = ["provider": authData.provider!, "blah": "emailTest"]
                                        DataService.ds.createFirebaseUser(authData.uid, user: user)
                                    })
                                    
                                    
                                    self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                                }
                            })
                        } else {
                            self.showErrorAlert("Could not log in.", msg: "Please check your username or password.")
                        }
                    } else {
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    }
                })
                
            }
        } else {
            showErrorAlert("Email and Password required", msg: "You must enter an email an password!")
        }
    }
    
    @IBAction func fbBtnPressed(sender: UIButton) {
        let ref = DataService.ds.REF_BASE
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logInWithReadPermissions(["email"]) { (facebookResult, facebookError) -> Void in
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
            } else if facebookResult.isCancelled {
                print("Facebook login was cancelled.")
            } else {
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                ref.authWithOAuthProvider("facebook", token: accessToken,
                    withCompletionBlock: { error, authData in
                        if error != nil {
                            print("Login failed. \(error)")
                        } else {
                            print("Logged in! \(authData)")
                            
                            let user = ["provider": authData.provider!, "blah": "test"]
                            DataService.ds.createFirebaseUser(authData.uid, user: user)
                            
                            NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                            
                            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                        }
                })
            }
        }
    }
    
    func showErrorAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
        
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
}

