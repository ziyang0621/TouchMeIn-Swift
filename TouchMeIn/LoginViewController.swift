/*
* Copyright (c) 2014 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import CoreData
import LocalAuthentication
import Security

class LoginViewController: UIViewController {
  
  var managedObjectContext: NSManagedObjectContext? = nil
    let MyKeychainWrapper = KeychainWrapper()
    let createLoginButtonTag = 0
    let loginButtonTag = 1
    var error: NSError?
    var context = LAContext()
    let MyOnePassword = OnePasswordExtension()
    var has1PasswordLogin: Bool = false
    
    @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var usernameTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var createInfoLabel: UILabel!  
    @IBOutlet var touchIDButton: UIButton!
    @IBOutlet var onepasswordSigninButton: UIButton!

  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let hasLogin = NSUserDefaults.standardUserDefaults().boolForKey("hasLoginKey")
    
    if hasLogin {
        loginButton.setTitle("Login", forState: .Normal)
        loginButton.tag = loginButtonTag
        createInfoLabel.hidden = true
        onepasswordSigninButton.enabled = true
    } else {
        loginButton.setTitle("Create", forState: .Normal)
        loginButton.tag = createLoginButtonTag
        createInfoLabel.hidden = false
        onepasswordSigninButton.enabled = false
    }
    
    let storedUsername: NSString? = NSUserDefaults.standardUserDefaults().valueForKey("username") as? NSString
    usernameTextField.text = storedUsername
    
    touchIDButton.hidden = true
    if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
        touchIDButton.hidden = false
    }
    
    onepasswordSigninButton.hidden = true
    var has1Password = NSUserDefaults.standardUserDefaults().boolForKey("has1PassLogin")
    
    if MyOnePassword.isAppExtensionAvailable() {
        onepasswordSigninButton.hidden = false
        if has1Password {
            onepasswordSigninButton.setImage(UIImage(named: "onepassword-button"), forState: .Normal)
        } else {
            onepasswordSigninButton.setImage(UIImage(named: "onepassword-button-green"), forState: .Normal)
        }
    }
    
  }
  
  // MARK: - Action for checking username/password
  @IBAction func loginAction(sender: AnyObject) {
    
    if (usernameTextField.text == "" || passwordTextField.text == "") {
        var alert = UIAlertView()
        alert.title = "You must enter both a username and password"
        alert.addButtonWithTitle("Oops!")
        alert.show()
        return;
    }
    
    usernameTextField.resignFirstResponder()
    passwordTextField.resignFirstResponder()
    
    if sender.tag == createLoginButtonTag {
        let hasLoginKey = NSUserDefaults.standardUserDefaults().boolForKey("hasLoginKey")
        if hasLoginKey == false {
            NSUserDefaults.standardUserDefaults().setValue(self.usernameTextField.text, forKey: "username")
        }
        
        MyKeychainWrapper.mySetObject(passwordTextField.text, forKey: kSecValueData)
        MyKeychainWrapper.writeToKeychain()
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasLoginKey")
        NSUserDefaults.standardUserDefaults().synchronize()
        loginButton.tag = loginButtonTag
        
        performSegueWithIdentifier("dismissLogin", sender: self)
    } else if sender.tag == loginButtonTag {
        if checkLogin(usernameTextField.text, password: passwordTextField.text) {
            performSegueWithIdentifier("dismissLogin", sender: self)
        } else {
            var alert = UIAlertView()
            alert.title = "Login Problem"
            alert.message = "Wrong username or password."
            alert.addButtonWithTitle("Foiled Again!")
            alert.show()
        }
    }
  }
  
    @IBAction func touchIDLoginAction(sender: AnyObject) {
      
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: "Logging in with Touch ID",
                reply: { (success: Bool, error: NSError!) -> Void in
                
                    dispatch_async(dispatch_get_main_queue(), {
                        if success {
                            self.performSegueWithIdentifier("dismissLogin", sender: self)
                        }
                        
                        if error != nil {
                            var message: NSString
                            var showAlert: Bool
                            
                            switch(error.code) {
                            case LAError.AuthenticationFailed.rawValue:
                                message = "there was a problem verifying your identity."
                                showAlert = true
                            case LAError.UserCancel.rawValue:
                                message = "You pressed cancel."
                                showAlert = true
                            case LAError.UserFallback.rawValue:
                                message = "You pressed password."
                                showAlert = true
                            default:
                                showAlert = true
                                message = "TOuch ID may not be configured"
                            }
                            
                            var alert = UIAlertView()
                            alert.title = "Error"
                            alert.message = message
                            alert.addButtonWithTitle("Darn!")
                            if showAlert {
                                alert.show()
                            }
                        }
                    })
            })
        } else {
            var alert = UIAlertView()
            alert.title = "Error"
            alert.message = "Touch ID not available"
            alert.show()
        }
    }
    
    @IBAction func canUser1Password(sender: AnyObject) {
        if NSUserDefaults.standardUserDefaults().objectForKey("has1PassLogin") != nil {
            self.findLoginFrom1Password(self)
        } else {
            self.saveLoginTo1Password(self)
        }
    }
    
    @IBAction func findLoginFrom1Password(sender: AnyObject) {
        MyOnePassword.findLoginForURLString("TouchMeIn.Login", forViewController: self, sender: sender) {
            (loginDict: [NSObject: AnyObject]!, error: NSError!) -> Void in
            if loginDict == nil {
                if (Int32)(error.code) != AppExtensionErrorCodeCancelledByUser {
                    println("Error invoking 1Password App Extension for find login: \(error)")
                }
                return
            }
            
            if NSUserDefaults.standardUserDefaults().objectForKey("username") == nil {
                NSUserDefaults.standardUserDefaults().setValue(loginDict[AppExtensionUsernameKey], forKey: "username")
                NSUserDefaults.standardUserDefaults().synchronize()
            }
            
            var foundUsername = loginDict["username"] as String
            var foundPassword = loginDict["password"] as String
            
            if self.checkLogin(foundUsername, password: foundPassword) {
                self.performSegueWithIdentifier("dismissLogin", sender: self)
            } else {
                var alert = UIAlertView()
                alert.title = "Error"
                alert.message = "The info in 1Password is incorrect"
                alert.addButtonWithTitle("Darn!")
                alert.show()
            }
        }
    }
    
    func checkLogin(username: String, password: String) -> Bool {
        if password == MyKeychainWrapper.myObjectForKey("v_Data") as NSString &&
            username == NSUserDefaults.standardUserDefaults().valueForKey("username") as? NSString {
                return true
        } else {
            return false
        }
    }
    
    func saveLoginTo1Password(sender: AnyObject) {
        var newLoginDetails: NSDictionary = [
            AppExtensionTitleKey: "Touch Me In",
            AppExtensionUsernameKey: usernameTextField.text,
            AppExtensionPasswordKey: passwordTextField.text,
            AppExtensionNotesKey: "Saved with the TouchMeIn app",
            AppExtensionSectionTitleKey: "Touch Me In App",
        ]
        
        var passwordGenerationOptions: NSDictionary = [
            AppExtensionGeneratedPasswordMinLengthKey: 6,
            AppExtensionGeneratedPasswordMaxLengthKey: 10
        ]
        
        MyOnePassword.storeLoginForURLString("TouchMeIn:Login", loginDetails: newLoginDetails, passwordGenerationOptions: passwordGenerationOptions, forViewController: self, sender: sender) {
            (loginDict: [NSObject: AnyObject]!, error: NSError!) -> Void in
            
            if loginDict == nil {
                if ((Int32)(error.code) != AppExtensionErrorCodeCancelledByUser) {
                    println("Error invoking 1Password App Extension for login: \(error)")
                }
                return
            }
            
            var foundUsername = loginDict["username"] as String
            var foundPassword = loginDict["password"] as String
            
            if self.checkLogin(foundUsername, password: foundPassword) {
                self.performSegueWithIdentifier("dismissLogin", sender: self)
            } else {
                var alert = UIAlertView()
                alert.title = "Error"
                alert.message = "The info in 1Password is incorrect"
                alert.addButtonWithTitle("Darn!")
                alert.show()
            }
            
            if NSUserDefaults.standardUserDefaults().objectForKey("username") != nil {
                NSUserDefaults.standardUserDefaults().setValue(self.usernameTextField.text, forKey: "username")
            }
            
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "has1PassLogin")
            NSUserDefaults.standardUserDefaults().synchronize()

        }
    }
  
  
}
