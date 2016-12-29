//
//  AppDelegate.swift
//  Pixel Party
//
//  Created by Ryan Laughlin on 12/28/16.
//  Copyright © 2016 Ryan Laughlin. All rights reserved.
//

import UIKit
import GoogleCast

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var secondaryWindow: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Chromecast support
        GCKLogger.sharedInstance().delegate = self
        let castOptions = GCKCastOptions(receiverApplicationID: ENV("ChromecastAppID") as! String)
        GCKCastContext.setSharedInstanceWith(castOptions)
        GCKCastContext.sharedInstance().sessionManager.add(self)
        
        // AirPlay support
        NotificationCenter.default.addObserver(self, selector:(#selector(AppDelegate.screenConnectionStatusChanged)), name:NSNotification.Name.UIScreenDidConnect, object:nil)
        NotificationCenter.default.addObserver(self, selector:(#selector(AppDelegate.screenConnectionStatusChanged)), name:NSNotification.Name.UIScreenDidDisconnect, object:nil)
        
        //Initial check on how many screens are connected to the device on launch of the application.
        if (UIScreen.screens.count > 1) {
            self.screenConnectionStatusChanged()
        }
        
        return true
    }
    
    func screenConnectionStatusChanged(){
        if (UIScreen.screens.count == 1) {
            secondaryWindow = nil
        } else {
            let airplayScreen = UIScreen.screens.last!
            
            let newWindow = UIWindow(frame: airplayScreen.bounds)
            newWindow.screen = airplayScreen
            newWindow.isHidden = false
            secondaryWindow = newWindow // Must be set before AirplayViewController is initialized
            newWindow.rootViewController = AirplayViewController()
            newWindow.makeKeyAndVisible()
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension AppDelegate: GCKLoggerDelegate {
    func logFromFunction(function: UnsafePointer<Int8>, message: String!) {
        let functionName = String.init(cString: function)
        print("\(functionName): \(message)")
    }
}

extension AppDelegate: GCKSessionManagerListener {
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        session.add(DataChannel.sharedInstance)
        
        // TODO: once we've connected to establish the IP address, can we disconnect?
    }
}
