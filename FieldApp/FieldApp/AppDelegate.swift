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
//    var locationManager = CLLocationManager()
    var notificationCenter: UNUserNotificationCenter?
    var myViewController: HomeView?
    var didEnterBackground: Bool?
    let main = OperationQueue.main
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
//        locationManager.allowsBackgroundLocationUpdates = true
//        locationManager = CLLocationManager()
//        locationManager?.delegate = self
//        locationManager?.requestAlwaysAuthorization()
        UserLocation.instance.initialize()
        
//        notificationCenter = UNUserNotificationCenter.current()
//        notificationCenter?.delegate = notificationDelegate
        
        FirebaseApp.configure()
        registerForPushNotif()
        print("app didFinishLaunching w/ options")
        
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){
        Auth.auth().setAPNSToken(deviceToken, type: AuthAPNSTokenType.sandbox)
        
        let tokenChars = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        checkToken(token: tokenChars)
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
        print("app did enter bkgrd, with window")
        didEnterBackground = true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("app did become active")
        if myViewController != nil  && didEnterBackground == true {
            self.myViewController?.employeeInfo = nil
            self.myViewController?.checkForUserInfo()
        }
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
    
//    func handleGeoFenceEvent(forRegion region: CLRegion) {
//        print("region EXIT event triggered \(region)")
//        guard let employeeID = UserDefaults.standard.integer(forKey: "employeeID") as? Int else { print("failed on employeeID"); return }
//        guard let employeeName = UserDefaults.standard.string(forKey: "employeeName") as? String else { print("failed on employeeName"); return }
//        let userInfo = UserData.UserInfo(employeeID: employeeID, userName: employeeName, employeeJobs: [], punchedIn: true)
//        let autoClockOut = true
//        guard let coordinate = UserLocation.instance.currentCoordinate as? CLLocationCoordinate2D else { return }
//        let locationArray = [String(coordinate.latitude), String(coordinate.longitude)]
//
//        APICalls().sendCoordinates(employee: userInfo, location: locationArray, autoClockOut: autoClockOut) { success, currentJob, poNumber, jobLatLong, clockedIn in
//            let content = UNMutableNotificationContent()
//            content.title = "Left Job Site"
//            content.body = "You were clocked out because you left the job site."
//            content.sound = UNNotificationSound.default()
//            let intrvl = TimeInterval(1.01)
//            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intrvl, repeats: false)
//            let request = UNNotificationRequest(identifier: region.identifier, content: content, trigger: trigger)
//
//            self.notificationCenter?.add(request) { (err) in
//                if err != nil { print("error setting up notification request") } else {
//                    print("added notification")
//                }
//            }
//            if clockedIn == false && success == true { UserLocation.instance.stopMonitoring() }
//        }
//    }
    
    func checkToken(token: String) {
        guard let id = UserDefaults.standard.string(forKey: "employeeID") else { return }
        let route = "employee/token/" + id
        var request = APICalls().setupRequest(route: route, method: "POST")
        
        func updateToken() {
            request.addValue(token, forHTTPHeaderField: "token")
            let task = URLSession.shared.dataTask(with: request) {data, response, error in
                if error != nil {
                    print("failed to fetch JSON from database)"); print(error); return
                } else { print("sent device token successfully") }
            }
            task.resume()
        }
        
        if let existingToken = UserDefaults.standard.string(forKey: "token") {
            if existingToken == token { return }
            else { updateToken() }
        } else {
            UserDefaults.standard.set(token, forKey: "token")
            updateToken()
        }
    }
}

//extension AppDelegate: CLLocationManagerDelegate {
//    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) { print("ENTER region event triggered") }
//    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) { UserLocation.instance.handleGeoFenceEvent(forRegion: region) }
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { print("did update locations") }
//}

//extension AppDelegate: UNUserNotificationCenterDelegate {
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        completionHandler(.badge)
//    }
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        print("received user input")
//    }
//}



