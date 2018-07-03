//
//  AppDelegate.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var notificationDelegate = UYLNotificationDelegate()
    var notificationCenter: UNUserNotificationCenter?
    var myViewController: HomeView?
    var didEnterBackground: Bool?
    let main = OperationQueue.main

    override init() {
        super.init()
        FirebaseApp.configure()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UserLocation.instance.initialize()
        registerForPushNotif()
        
        didEnterBackground = false
        print("app didFinishLaunching w/ options")
        
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){
        print("did register for remote notifications")
        
        Auth.auth().setAPNSToken(deviceToken, type: AuthAPNSTokenType.sandbox)
        
        let tokenChars = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        checkToken(token: tokenChars)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification notification: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("received notification \n \(notification)")
        
        if Auth.auth().canHandleNotification(notification) { completionHandler(UIBackgroundFetchResult.noData); return }
        // IF this notification is not auth related, developer should handle it.
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("app did enter bkgrd, with window");
        didEnterBackground = true;
        
//        myViewController?.employeeInfo = nil;
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("app did become active")
        if myViewController != nil  && didEnterBackground == true {
            HomeView.employeeInfo = nil
            self.myViewController?.checkForUserInfo()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        UserDefaults.standard.set(nil, forKey: "todaysJobPO"); UserDefaults.standard.set(nil, forKey: "employeeName"); print("app will terminate")
    }
    
    func registerForPushNotif() {
        notificationCenter?.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            guard granted else { print("Notification permission NOT granted"); return };
            
            self.notificationCenter?.getNotificationSettings { (settings) in
                guard settings.authorizationStatus == .authorized else { print("notification settings not authorized"); return }
                self.main.addOperation(UIApplication.shared.registerForRemoteNotifications)
            }
        }
    }
    
    func checkToken(token: String) {
        guard let id = UserDefaults.standard.string(forKey: "employeeID"),
        let route = "employee/token/" + id as? String else { return }
        
        func updateToken() {
            var request = APICalls().setupRequest(route: route, method: "POST")
            request.addValue(token, forHTTPHeaderField: "token")
            
            let task = URLSession.shared.dataTask(with: request) {data, response, error in
                if error != nil {
                    print("failed to fetch JSON from database w/ error: \(error)");
                    return
                } else { print("sent device token successfully") }
            }
            task.resume()
        }
        
        if let existingToken = UserDefaults.standard.string(forKey: "token") {
            if existingToken == token { return }
            else {
                UserDefaults.standard.set(token, forKey: "token");
                updateToken()
            }
        } else {
            UserDefaults.standard.set(token, forKey: "token");
            updateToken()
        }
    }
}


