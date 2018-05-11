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
    let notificationDelegate = UYLNotificationDelegate()
    let locationManager = CLLocationManager()
    let notificationCenter = UNUserNotificationCenter.current()
    let main = OperationQueue.main

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        registerForPushNotif()
        UNUserNotificationCenter.current().delegate = notificationDelegate
        locationManager.delegate = self as? CLLocationManagerDelegate
        locationManager.requestAlwaysAuthorization()
        
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){
        // Forward the token to your provider, using a custom method.
        
        Auth.auth().setAPNSToken(deviceToken, type: AuthAPNSTokenType.sandbox)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification notification: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(UIBackgroundFetchResult.noData)
            return
        }
        // This notification is not auth related, developer should handle it.
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
    
    func registerForPushNotif() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            print("Notification permission granted")
            guard granted else { return }
            self.notificationCenter.getNotificationSettings { (settings) in
                guard settings.authorizationStatus == .authorized else { return }
                self.main.addOperation { UIApplication.shared.registerForRemoteNotifications() }
            }
        }
    }
    
    func handleGeoFenceEvent(forRegion region: CLRegion) {
        //send info to server or crack open location manger to begin actively monitoring the user location
        let employeeID = UserDefaults.standard.string(forKey: "employeeID")
        let userINfo = UserData.UserInfo(employeeID: Int(employeeID!)!, employeeJobs: [], userName: "", punchedIn: true)
        let locationArray = ["33.877105400870263", "-118.03514083418783"]
        
        APICalls().sendCoordinates(employee: userINfo, location: locationArray) { success, currentJob, poNumber  in
        
        }
        
//        if UIApplication.shared.applicationState == .active {
//            //do smth while app is open
//            window?.rootViewController?.showAlert(withTitle: nil, message: "looks like you moved out of the job range")
//        } else {
//            //do smth if app is closed or in background
//
//            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
//            let stopAction = UNNotificationAction(identifier: "STOP_ACTION", title: "Stop", options: .destructive)
//            let alarmCategory = UNNotificationCategory(identifier: "alarm.category", actions: [stopAction], intentIdentifiers: [], options: [])
//
//            let identifier = "outOfRange"
//            let content = UNMutableNotificationContent()
//            content.title = "Looks like you've left the job site"
//            content.sound = UNNotificationSound.default()
//            content.categoryIdentifier = "alarm.category"
//
//            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0, repeats: false)
//            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
//
//            notificationCenter.setNotificationCategories([alarmCategory])
//            notificationCenter.requestAuthorization(options: options) { (granted, error) in
//                if !granted {print("there was an error or the user did not authorize alerts"); print(error)}
//            }
//            notificationCenter.getNotificationSettings { (settings) in
//                if settings.authorizationStatus != .authorized {print("user did not authorize alerts")}
//            }
//            notificationCenter.add(request, withCompletionHandler: { (err) in
//                if err != nil { print("there was an error"); print(err)
//                } else {
//
//                    let laterContent = UNMutableNotificationContent()
//                    let lateridentifier = "anotherReminder"
//                    laterContent.title = "Another location reminder"
//                    laterContent.sound = UNNotificationSound.default()
//                    laterContent.categoryIdentifier = "alarm.category"
//
//                    let latertrigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
//                    let laterrequest = UNNotificationRequest(identifier: lateridentifier, content: laterContent, trigger: latertrigger)
//
//                    self.notificationCenter.add(laterrequest, withCompletionHandler: { (err) in
//                        if err != nil { print("looks like there was an error"); print(err)
//                        } else {  }
//                    })
//                }
//            })
//        }
    }

}

extension AppDelegate: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion { /* handle region entered */ }
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // receives CLRegion obj
        
        handleGeoFenceEvent(forRegion: region)
    }
}


