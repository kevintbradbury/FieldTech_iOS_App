//
//  ViewExtensions.swift
//  FieldApp
//
//  Created by MB Mac 3 on 8/30/18.
//  Copyright © 2018 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import UserNotificationsUI

extension UIViewController {
    func setShadows(btns: [UIButton]) {
        for button in btns {
            button.layer.shadowColor = UIColor.darkGray.cgColor
            button.layer.shadowOffset = CGSize(width: 1, height: 2)
            button.layer.shadowRadius = 2
            button.layer.shadowOpacity = 0.80
        }
    }
    
    func showAlert(withTitle title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        let main = OperationQueue.main
        
        alert.addAction(action)
        main.addOperation { self.present(alert, animated: true, completion: nil) }
    }
    
    func createNotification(intervalInSeconds interval: Double, title: String, message: String, identifier: String) -> UNNotificationRequest {
        let timeInterval = TimeInterval(interval)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        return request
    }
}

class UYLNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            print("Dismiss Action")
        case UNNotificationDefaultActionIdentifier:
            print("Default")
        case "STOP_ACTION":
            print("stop alarm")
        case "SNOOZE":
            print("Snooze action")
            
        default:
            print("unknown action")
        }
        completionHandler()
    }
}
