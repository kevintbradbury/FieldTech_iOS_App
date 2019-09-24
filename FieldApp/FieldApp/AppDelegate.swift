//
//  AppDelegate.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import UserNotifications
import CoreLocation
import AVFoundation
import AVKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var homeViewActive: HomeView?
    var myEmployeeVC: EmployeeIDEntry?
    var didEnterBackground: Bool?
    let main = OperationQueue.main

    override init() {
        super.init()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        UserLocation.instance.initialize()
        registerForPushNotif()
        didEnterBackground = false
        APICalls.getHostFromPList()
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        print("app didFinishLaunching w/ options")
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        Auth.auth().setAPNSToken(deviceToken, type: AuthAPNSTokenType.sandbox)
        
        UNUserNotificationCenter.current().delegate = self
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
        print("AppDelegate > notification: \(notification)")
        
        guard let aps = notification[AnyHashable("aps")] as? NSDictionary,
            let alert = aps[AnyHashable("alert")] as? NSDictionary,
            let action = alert[AnyHashable("action")] as? String else {
                print("didReceiveRemoteNotification: failed parsing: aps/alert/action")
                completionHandler(.newData)
                return
        }
        
        if action == "gps Update" {
            guard let coordinates = UserLocation.instance.currentCoordinate else { return }
            
            APICalls().justCheckCoordinates(location: coordinates) { success in
                if success != true { completionHandler(.failed) }
                else { completionHandler(.newData); print("didReceiveRemoteNotification: coordinate check succeeded") }
            }
        } else {
            print("didReceiveRemoteNotification: action: \(alert)")
            completionHandler(.newData)
        }
    }
    
    func application(_ application: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
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
        removeAutoClockNotif(center: UNUserNotificationCenter.current())
        
        if homeViewActive != nil  && didEnterBackground == true {
            HomeView.employeeInfo = nil
            OperationQueue.main.addOperation {
                self.homeViewActive?.checkForUserInfo()
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        UserDefaults.standard.set(nil, forKey: "employeeName")
        UserDefaults.standard.set(nil, forKey: "todaysJobLatLong")

        print("app will terminate")
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        
    }
    
    func registerForPushNotif() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            
            if granted == true {
                UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                    
                    if settings.authorizationStatus == .authorized {
                        self.main.addOperation(UIApplication.shared.registerForRemoteNotifications)
                        return
                    }
                }
            } else { fatalError("notification not granted: \(granted), \(String(describing: error))") }
        }
    }
    
    func checkToken(token: String) {
        guard let id = UserDefaults.standard.string(forKey: "employeeID") else {
            print("no saved employeeID"); return
        }
        let route = "employee/token/\(id)"
        APICalls().updateToken(token: token, route: route)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // If App is currently open
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("notifCtr willPresent category: \(notification.request.identifier), \(notification.request.content.categoryIdentifier)")
        var category = ""
        
        if notification.request.content.categoryIdentifier != nil && notification.request.content.categoryIdentifier != "" {
            category = notification.request.content.categoryIdentifier
        } else {
            category = notification.request.identifier
        }
        
        handleNotif(category: category, center: center, notifBody: notification.request.content.body)
        playSound()
        completionHandler([.alert, .sound])
    }
    
    // If App is currently in background or phone is locked
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            var category = ""
            let categoryID = response.notification.request.content.categoryIdentifier
            
            if categoryID != nil  && categoryID != "" {
                category = categoryID
            } else {
                category = response.notification.request.identifier
            }
            print("notifCtr didReceive category: \(response.notification.request.identifier), \(categoryID)")
            
            handleNotif(category: category, center: center, notifBody: response.notification.request.content.body)
            completionHandler()
        }
    }
    
    func handleNotif(category: String, center: UNUserNotificationCenter, notifBody: String?) {
        let state = UIApplication.shared.applicationState
        guard let vc = self.homeViewActive else { return }
        
        switch category {
            
        case "vehicleCheckList":
            HomeView.vehicleCkListNotif = true
            if state == UIApplication.State.active { vc.performSegue(withIdentifier: "vehicleCkList", sender: nil) }
            
        case "scheduleReady":
            ScheduleView.scheduleRdy = true
            HomeView.scheduleReadyNotif = true
            if state == UIApplication.State.active { vc.performSegue(withIdentifier: "schedule", sender: nil) }
            
        case "jobCheckup":
            HomeView.jobCheckup = true
            if state == UIApplication.State.active {
                OperationQueue.main.addOperation { vc.jobCheckUpView.isHidden = false }
            }

        case "extendRental":
            guard let userBrandToolDate = notifBody else { return }
            HomeView.toolRenewal = userBrandToolDate
            if state == UIApplication.State.active {
                OperationQueue.main.addOperation {  vc.extendToolRental() }
            }
            
        case "leftJobSite":
            removeAutoClockNotif(center: center)
            
        case "toolsReminder":
            if let unwrappedNotifContent = notifBody {
                print("get tool count \(notifBody!)")
                let split = unwrappedNotifContent.components(separatedBy: " -")
                guard let toolCount = Int(split[0]) else { return }
                HomeView.toolCount = toolCount
            }
            
        case "mealWaiver":
            HomeView.presentWaiverAlrt = true
            if state == UIApplication.State.active {
                OperationQueue.main.addOperation { vc.show2ndMealWaiverAlert() }
            }
            
        default:
            print("Received notification w/ category: \(category)")
        }
    }
    
    func playSound() {
        let _ = "/System/Library/Audio/UISounds/ReceivedMessage.caf"
        let soundUrl = URL(
            fileURLWithPath: Bundle.main.path(forResource: "ringerremix", ofType: "mp3") ?? "", isDirectory: true
        )
        var player: AVAudioPlayer?
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            
            player = try AVAudioPlayer(contentsOf: soundUrl)
            player?.delegate = self
            player?.prepareToPlay()
            
        } catch {
            print("Audio session err: \(error)")
        }
        
        if let validPlayer = player {
            validPlayer.setVolume(1.0, fadeDuration: 0.0)
            
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { (timer) in
                validPlayer.numberOfLoops = 1
                validPlayer.play()
            }
        }
    }
    
    func removeAutoClockNotif(center: UNUserNotificationCenter) {
        HomeView.leftJobSite = true
        
        for i in 1...6 {
            let category = "leftJobSite\(i)"
            center.removeDeliveredNotifications(withIdentifiers: [category])
            center.removePendingNotificationRequests(withIdentifiers: [category])
        }
    }
}

extension AppDelegate: AVAudioPlayerDelegate {
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
    }
}





