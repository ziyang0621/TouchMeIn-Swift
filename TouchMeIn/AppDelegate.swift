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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
    
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

    let NavigationController = self.window!.rootViewController as UINavigationController
    let Controller = NavigationController.topViewController as MasterViewController
    Controller.managedObjectContext = self.managedObjectContext
    
    self.prepareNavigationBarAppearance()

    return true
  }
  
  func prepareNavigationBarAppearance() {
    
    let BarColor = UIColor(red:43.0/255.0, green:43.0/255.0,blue:43.0/255.0,alpha:1.0)
    
    UINavigationBar.appearance().barTintColor = BarColor
    UINavigationBar.appearance().tintColor = UIColor.whiteColor()
    
    let font = UIFont(name: "Avenir-Black", size: 30)!
    let regularVertical = UITraitCollection(verticalSizeClass:.Regular)
    let titleDict : Dictionary = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: font]
    
    UINavigationBar.appearanceForTraitCollection(regularVertical).titleTextAttributes = titleDict
    
    UIToolbar.appearance().barTintColor = BarColor
    UIToolbar.appearance().tintColor = UIColor.whiteColor()
    
    UIStatusBarStyle.LightContent
    
    
  }
  
  
  func applicationWillResignActive(application: UIApplication) {
    
    UIApplication.sharedApplication().ignoreSnapshotOnNextApplicationLaunch()
  }
  
  
  func applicationWillTerminate(application: UIApplication) {

    self.saveContext()
  }
  
  // MARK: - Core Data stack
  
  lazy var applicationDocumentsDirectory: NSURL = {

    let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
    return urls[urls.count-1] as NSURL
    }()
  
  lazy var managedObjectModel: NSManagedObjectModel = {

    let modelURL = NSBundle.mainBundle().URLForResource("TouchMeIn", withExtension: "momd")!
    return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
  
  lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {

    var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
    let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("TouchMeIn.sqlite")
    var error: NSError? = nil
    var failureReason = "There was an error creating or loading the application's saved data."
    if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
      coordinator = nil

      let dict = NSMutableDictionary()
      dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
      dict[NSLocalizedFailureReasonErrorKey] = failureReason
      dict[NSUnderlyingErrorKey] = error
      error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)

      NSLog("Unresolved error \(error), \(error!.userInfo)")
      abort()
    }
    
    return coordinator
    }()
  
  lazy var managedObjectContext: NSManagedObjectContext? = {

    let coordinator = self.persistentStoreCoordinator
    if coordinator == nil {
      return nil
    }
    var managedObjectContext = NSManagedObjectContext()
    managedObjectContext.persistentStoreCoordinator = coordinator
    return managedObjectContext
    }()
  
  // MARK: - Core Data Saving support
  
  func saveContext () {
    if let moc = self.managedObjectContext {
      var error: NSError? = nil
      if moc.hasChanges && !moc.save(&error) {

        NSLog("Unresolved error \(error), \(error!.userInfo)")
        abort()
      }
    }
  }
  
}

