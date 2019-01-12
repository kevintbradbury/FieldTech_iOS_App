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
import EPSignature
import MapKit


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
    
    func presentSignature(vc: UIViewController, subTitle: String, title: String) {
        guard let delegate = vc as? EPSignatureDelegate else { return }
        let signatureVC = EPSignatureViewController(signatureDelegate: delegate, showsDate: true)
        
        signatureVC.subtitleText = subTitle
        signatureVC.title = title
        
        let nav = UINavigationController(rootViewController: signatureVC)
        OperationQueue.main.addOperation {
            vc.present(nav, animated: true, completion: nil)
        }
    }
    
    @objc func keyboardWillChange(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        if notification.name == Notification.Name.UIKeyboardWillShow || notification.name ==
            Notification.Name.UIKeyboardWillChangeFrame {
            
            OperationQueue.main.addOperation {
                self.view.frame.origin.y = -(keyboardRect.height - (keyboardRect.height / 2))   //   75)
            }
        } else {
            OperationQueue.main.addOperation {
                self.view.frame.origin.y = 0
            }
        }
    }
    
    func setDismissableKeyboard(vc: UIViewController) {
        OperationQueue.main.addOperation {
            vc.view.frame.origin.y = 0
            
            vc.view.addGestureRecognizer(
                UITapGestureRecognizer(target: vc.view, action: #selector(UIView.endEditing(_:)))
            )
            NotificationCenter.default.addObserver(
                vc, selector: #selector(vc.keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil
            )
            NotificationCenter.default.addObserver(
                vc, selector: #selector(vc.keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil
            )
            NotificationCenter.default.addObserver(
                vc, selector: #selector(vc.keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil
            )
        }
    }
    
    func openMapsWithDirections(to coordinate: CLLocationCoordinate2D, destination name: String) {
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: options)
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
