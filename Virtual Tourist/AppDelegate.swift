//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by scythe on 2/17/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let stack = CoreDataStack(modelName: "Model")!
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
    var unfinishedPins = [Pin]()
    private enum addRemoveObserver{
        case added ,removed
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        instantiateStackOnMapViewController()
        stack.autoSave(60)
        observerForNotification(is: .added)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
//        print("willResign")
//        stack.save()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("DidEnterBackground")
        //TODO: Take the unReturned Pins and make them pin.hasReturned = true
        saveHasReturnedPinsOnExit()
       stack.save()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        
        saveHasNotReturnedPinsOnExit()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("willTerminate")
        saveHasReturnedPinsOnExit()
    }
    
    func instantiateStackOnMapViewController(){
        let nav = window!.rootViewController as! UINavigationController
        let mapVC = nav.viewControllers[0] as! MapViewController
        mapVC.stack = stack
    }
    
    func saveHasReturnedPinsOnExit(){
        
        for pin in unfinishedPins {
            print("saveHasReturnedPinsOnExit in loop")
            stack.context.performAndWait {
                pin.hasReturned = true
                print("Saved On Exit")
                
            }
        }
        self.stack.save()
        
    }
    
    func saveHasNotReturnedPinsOnExit(){
        for pin in unfinishedPins {
            print("saveHasNotReturnedPinsOnExit in loop")
            stack.context.performAndWait {
                pin.hasReturned = false
                print("Saved On Exit")
                
            }
        }
        self.stack.save()
    }
    
    private func observerForNotification(is choose:addRemoveObserver){
        switch choose{
        case .added:
            NotificationCenter.default.addObserver(self, selector: #selector(addUnfinishedPins(notification:)), name: .addUnfinishedPinToAppDelegate, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(removeUnfinishedPins(notification:)), name: .removeUnfinishedPinFromAppDelegate, object: nil)
        case .removed:
            NotificationCenter.default.removeObserver(self, name: .addUnfinishedPinToAppDelegate, object: nil)
            NotificationCenter.default.removeObserver(self, name: .removeUnfinishedPinFromAppDelegate, object: nil)
        }
    }
    
    @objc func addUnfinishedPins(notification:Notification){
        if let unfinishedPin = notification.userInfo?["unfinishedPin"] as? Pin{
            
            unfinishedPins.append(unfinishedPin)
            print("Unfinished Pin Appended")
            print("UNFINISHED PIN ARRAY: \(unfinishedPins)")
        }
    }
    
    @objc func removeUnfinishedPins(notification:Notification){
        if let unfinishedPin = notification.userInfo?["unfinishedPin"] as? Pin{
            for pin in unfinishedPins{
                if pin == unfinishedPin{
                    if let index = unfinishedPins.index(of: pin){
                        unfinishedPins.remove(at: index)
                        print("UNFINISHED PIN ARRAY: \(unfinishedPins)")
                    }
                }
            }
        }
    }
    
    
    


}

