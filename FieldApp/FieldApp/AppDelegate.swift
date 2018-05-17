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
    var locationManager: CLLocationManager?
    var notificationCenter: UNUserNotificationCenter?
    var myViewController: UIViewController?
    let main = OperationQueue.main
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        
        notificationCenter = UNUserNotificationCenter.current()
        notificationCenter?.delegate = notificationDelegate
        
        FirebaseApp.configure()
        registerForPushNotif()
        print("app didFinishLaunching w/ optons")
        
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){
        // Forward token to provider, using custom method.
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
        print("application will resign active")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("app did enter bkgrd, with window")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("app will enter foregrnd")
        if myViewController != nil {
            
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("app did become active")
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        UserDefaults.standard.set(nil, forKey: "todaysJobPO")
        UserDefaults.standard.set(nil, forKey: "employeeName")
        print("app will terminate")
    }
    
    func registerForPushNotif() {
        notificationCenter?.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            guard granted else { return }
            print("Notification permission granted")
            self.notificationCenter?.getNotificationSettings { (settings) in
                guard settings.authorizationStatus == .authorized else { return }
                self.main.addOperation { UIApplication.shared.registerForRemoteNotifications() }
            }
        }
    }
    
    func handleGeoFenceEvent(forRegion region: CLRegion) {
        guard let employeeID = UserDefaults.standard.integer(forKey: "employeeID") as? Int else { print("failed on employeeID"); return }
        guard let employeeName = UserDefaults.standard.string(forKey: "employeeName") else { print("failed on employeeName"); return }
        guard let jobLoc = UserDefaults.standard.array(forKey: "todaysJobLatLong") as? [Double] else { print("failed on job location"); return }
        let userInfo = UserData.UserInfo(employeeID: employeeID, employeeJobs: [], userName: employeeName, punchedIn: true)
        let locationArray = [String(jobLoc[0]), String(jobLoc[1])]
        
        // This is an auto clock-out, we want to use the job site coordinates otherwise we may not be able to clock out
        APICalls().sendCoordinates(employee: userInfo, location: locationArray) { success, currentJob, poNumber, jobLatLong in
            
            let content = UNMutableNotificationContent()
            content.title = "Left Job Site"
            content.body = "You were clocked out because you left the job site."
            content.sound = UNNotificationSound.default()
            let interval = TimeInterval(5.01)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: region.identifier, content: content, trigger: trigger)
            
            self.notificationCenter?.add(request, withCompletionHandler: { (err) in
                if err != nil { print("error setting up notification request") }
            })
            
            if success == true {
                UserLocation.instance.stopMonitoring()
                HomeView().employeeInfo?.punchedIn = false
            }
        }
        self.locationManager?.startUpdatingLocation()
    }
    
}

extension AppDelegate: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) { print("ENTER region event triggered") }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("region EXIT event triggered \(region)")
        handleGeoFenceEvent(forRegion: region)
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { }
    //        guard let location: CLLocation = locations.first else { print("Failed to Update Location"); return }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.badge)
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("received user input")
    }
}



