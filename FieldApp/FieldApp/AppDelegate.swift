//
//  AppDelegate.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import UserNotifications
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var notificationDelegate = UYLNotificationDelegate()
    var notificationCenter = UNUserNotificationCenter.current()
    var myViewController: HomeView?
    var myEmployeeVC: EmployeeIDEntry?
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
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        Auth.auth().setAPNSToken(deviceToken, type: AuthAPNSTokenType.sandbox)
        
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in
                print("user notification center authorized")
                // handle completion here
        })
        let token = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        
        checkToken(token: token)
        print("did register for remote notifications")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("FAILED to register for remote notifications, with error: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification notification: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if Auth.auth().canHandleNotification(notification) {
            print("didReceiveRemoteNotification: FireBase notification")
            completionHandler(.noData);     return
        }
        
        print(notification)
        
        guard let aps = notification[AnyHashable("aps")] as? NSDictionary,
            let alert = aps[AnyHashable("alert")] as? NSDictionary,
            let action = alert[AnyHashable("action")] as? String else {
                print("didReceiveRemoteNotification: failed parsing: aps/alert/action")
                completionHandler(.newData);    return
        }
        
        if action == "gps Update" {
            guard let coordinate = UserLocation.instance.currentCoordinate else { return }
            let locationArray = [String(coordinate.latitude), String(coordinate.longitude)]
            
            APICalls().justCheckCoordinates(location: locationArray) { success in
                if success != true { completionHandler(.failed) }
                else { completionHandler(.newData); print("didReceiveRemoteNotification: coordinate check succeeded") }
            }
        } else {
            print("didReceiveRemoteNotification: action: \(alert)");   completionHandler(.newData)
        }
    }
    
    func application(_ application: UIApplication, open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        if Auth.auth().canHandle(url) {
            return true
        }
        // URL not auth related, developer should handle it.
        
        return false
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
        UserDefaults.standard.set(nil, forKey: "employeeName")
        UserDefaults.standard.set(nil, forKey: "todaysJobName")
        UserDefaults.standard.set(nil, forKey: "todaysJobLatLong")

        print("app will terminate")
    }

    
    func registerForPushNotif() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            
            if granted == true {
                self.notificationCenter.getNotificationSettings { (settings) in
                    
                    if settings.authorizationStatus == .authorized {
                        self.main.addOperation(UIApplication.shared.registerForRemoteNotifications)
                        return
                    }
                }
            } else { fatalError("notification not granted: \(granted), \(error)") }
        }
    }
    
    func checkToken(token: String) {
        guard let id = UserDefaults.standard.string(forKey: "employeeID") else {
            print("no saved id"); return
        }
        let route = "employee/token/\(id)"
        
        if let existingToken = UserDefaults.standard.string(forKey: "token") {
            if existingToken == token {
                print("token matches"); return
            } else { updateToken(token: token, route: route) }
        } else { updateToken(token: token, route: route) }
    }
    
    func updateToken(token: String, route: String) {
        UserDefaults.standard.set(token, forKey: "token");
        
        APICalls().setupRequest(route: route, method: "POST") { req in
            var request = req
            request.addValue(token, forHTTPHeaderField: "token")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil {
                    print("fetch to server failed w/ error: \(error!.localizedDescription)"); return
                } else {
                    print("sent device token successfully")
                }
            }; task.resume()
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print(notification)
        completionHandler(.alert)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            let catg = response.notification.request.content.categoryIdentifier
            let state = UIApplication.shared.applicationState
            
            print("UNUserNotificationCenter didReceive response: \(response.notification.request.content)")
            
            guard let vc = self.myViewController else { return }
            
            switch catg {
            case "vehicleCheckList":
                if state == UIApplicationState.active { vc.performSegue(withIdentifier: "vehicleCkList", sender: nil) }
                else { HomeView.vehicleCkListNotif = true }
            case "scheduleReady":
                if state == UIApplicationState.active { vc.performSegue(withIdentifier: "schedule", sender: nil) }
                else { HomeView.scheduleReadyNotif = true }

            default:
                center.removeAllDeliveredNotifications()
            }
            
            completionHandler()
        }
    }
    
}
