//
//  EmployeeIDEntry.swift
//  FieldApp
//
//  Created by MB Mac 3 on 12/20/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import Firebase
import UserNotifications
import UserNotificationsUI

class EmployeeIDEntry: UIViewController {
    
    @IBOutlet weak var employeeID: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var enterIDText: UILabel!
    @IBOutlet weak var clockIn: UIButton!
    @IBOutlet weak var clockOut: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var activityBckgd: UIView!
    @IBOutlet weak var lunchBreakBtn: UIButton!
    
    let firebaseAuth = Auth.auth()
    let main = OperationQueue.main
    var jobAddress = ""
    var jobs: [Job.UserJob] = []
    var foundUser: UserData.UserInfo?
    var location = UserData.init().userLocation
    var firAuthId = UserDefaults.standard.string(forKey: "authVerificationID")
    var timer = Timer()
    var counter = 0
    let notificationCenter = UNUserNotificationCenter.current()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
        activityIndicator.hidesWhenStopped = true
        UserLocation.instance.initialize()
        hideTextfield()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    func isEmployeePhone(callback: @escaping (UserData.UserInfo) -> ()) {
        
        var employeeNumberToInt: Int?;
        if foundUser?.employeeID != nil {
            guard let employeeNumber = foundUser?.employeeID else { return }
            employeeNumberToInt = Int(employeeNumber)
        } else {
            guard let employeeNumber = employeeID.text else { return }
            employeeNumberToInt = Int(employeeNumber)
        }
        
        fetchEmployee(employeeId: employeeNumberToInt!) { user in
            self.foundUser = user
            callback(self.foundUser!)
        }
    }
    
    @IBAction func sendIDNumber(_ sender: Any) {
        
        activityIndicator.startAnimating()
        if employeeID.text != "" {
            isEmployeePhone() { foundUser in
                self.getLocation() { coordinate in
                    let locationArray = [String(coordinate.latitude), String(coordinate.longitude)]
                    APICalls().sendCoordinates(employee: foundUser, location: locationArray) { user in
                        self.foundUser = user
                        self.main.addOperation {
                            self.activityIndicator.isHidden = true
                            self.performSegue(withIdentifier: "return", sender: self)
                        }
                    }
                }
            }
        } else {
            self.incorrectID()
        }
    }
    
    @IBAction func backToHome(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goClockIn(_ sender: Any) {
        clockInClockOut()
    }
    
    @IBAction func goClockOut(_ sender: Any) {
        clockInClockOut()
    }
    
    @IBAction func lunchBrkPunchOut(_ sender: Any) {
        chooseBreakLength()
    }
    
    
    func clockInClockOut() {
        inProgress()
        if foundUser?.employeeID != nil {
            guard let uwrappedUser = foundUser else { return }
            self.getLocation() { coordinate in
                let locationArray = [String(coordinate.latitude), String(coordinate.longitude)]
                APICalls().sendCoordinates(employee: uwrappedUser, location: locationArray) { user in
                    self.foundUser = user
                    self.completedProgress()
                }
            }
            
        } else {
            self.incorrectID()
        }
    }
    func incorrectID() {
        let actionsheet = UIAlertController(title: "Error", message: "Unable to find that user", preferredStyle: UIAlertControllerStyle.alert)

        let ok = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) {(action) in
            self.employeeID.text = ""
            actionsheet.dismiss(animated: true, completion: nil)
            self.main.addOperation {
                self.activityIndicator.stopAnimating()
            }
        }
        actionsheet.addAction(ok)
        self.main.addOperation {
            self.present(actionsheet, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! HomeView
        
        UserDefaults.standard.set(foundUser?.employeeID, forKey: "employeeID")
        
        if segue.identifier == "return" {
            vc.employeeInfo = foundUser
            vc.firAuthId = firAuthId
        }
    }
    
    func getLocation(callback: @escaping (CLLocationCoordinate2D) -> ()) {
        
        UserLocation.instance.requestLocation(){ coordinate in
            self.location = coordinate
            if self.location != nil {
                callback(self.location!)
            }
        }
    }
    
    func fetchEmployee(employeeId: Int, callback: @escaping (UserData.UserInfo) -> ()){
        
        let route = "employee/" + String(employeeId)
        let request = APICalls().setupRequest(route: route, method: "GET")
        let session = URLSession.shared;
        
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                print("failed to fetch JSON from database \n \(String(describing: response)) \n \(String(describing: error))")
                return
            } else {
                guard let verifiedData = data else {
                    print("could not verify data from dataTask")
                    return
                }
                
                guard let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary else { return }
                guard let user = UserData.UserInfo.fromJSON(dictionary: json) else {
                    print("json serialization failed")
                    self.main.addOperation {
                        self.incorrectID()
                    }
                    return
                }
                callback(user)
            }
        }
        task.resume()
    }
    
    
}

extension EmployeeIDEntry {
    
    func hideTextfield() {
        if foundUser != nil {
            guard let punchedIn = self.foundUser?.punchedIn else { return }
            self.main.addOperation {
                self.employeeID.isHidden = true
                self.sendButton.isHidden = true
                
                if punchedIn == true {
                    self.clockIn.isHidden = true
                    self.lunchBreakBtn.isHidden = false
                    self.enterIDText.text = "Clock Out"
                } else if punchedIn == false {
                    self.clockOut.isHidden = true
                    self.lunchBreakBtn.isHidden = true
                    self.enterIDText.text = "Clock In"
                } else {
                    return
                }
            }
        } else {
            self.main.addOperation {
                self.clockIn.isHidden = true
                self.clockOut.isHidden = true
            }
        }
    }
    
    func inProgress() {
        self.main.addOperation {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.activityBckgd.isHidden = false
            self.activityIndicator.startAnimating()
        }
    }
    
    func completedProgress() {
        self.main.addOperation {
            self.activityBckgd.isHidden = true
            self.activityIndicator.hidesWhenStopped = true
            self.activityIndicator.stopAnimating()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.performSegue(withIdentifier: "return", sender: self)
        }
    }
}

extension EmployeeIDEntry {
    
    func goOnLunch(breakLength: Int) {
        let options: UNAuthorizationOptions = [.alert, .sound]
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE", title: "Snooze", options: UNNotificationActionOptions(rawValue: 0))
        let stopAction = UNNotificationAction(identifier: "STOP_ACTION", title: "Stop", options: .foreground)
        let deleteAction = UNNotificationAction(identifier: "UYLDeleteAction", title: "Selete", options: [.destructive])
        let category = UNNotificationCategory(identifier: "UYLReminderCategory", actions: [snoozeAction, stopAction, deleteAction], intentIdentifiers: [], options: [])
        
        notificationCenter.setNotificationCategories([category])
        notificationCenter.requestAuthorization(options: options) { (granted, error) in
            if !granted {
                print("there was an error or the user did not authorize alerts")
                print(error)
            }
        }
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                print("user did not authorize alerts")
            }
        }
        
        let content = UNMutableNotificationContent()
        let timeInSeconds = Double(breakLength / 3)  //  * 60)
        //currently using 3 as Divisor to check if corrent value is passed
        content.title = "Sorry, break time is over"
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = "UYLReminderCategory"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInSeconds, repeats: false)
        let identifier = "UYLocalNotification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request, withCompletionHandler: { (error) in
            if error != nil {
                print("there was an error")
                print(error)
            }
        })
        
        
    
    }
    
    func chooseBreakLength() {
        
        let actionsheet = UIAlertController(title: "Lunch Break", message: "Choose your break length", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let chooseThirty = UIAlertAction(title: "30 minute Break", style: UIAlertActionStyle.default) { (action) -> Void in
            self.goOnLunch(breakLength: 30)
        }
        let chooseSixty = UIAlertAction(title: "60 minute Break", style: UIAlertActionStyle.default) { (action) -> Void in
            self.goOnLunch(breakLength: 60)
        }
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive) { (action) -> Void in
            print("chose Cancel")
        }
        actionsheet.addAction(chooseThirty)
        actionsheet.addAction(chooseSixty)
        actionsheet.addAction(cancel)
        
        self.present(actionsheet, animated: true)
    }
}



class UYLNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            print("Dismiss Action")
        case UNNotificationDefaultActionIdentifier:
            print("Default")
        default:
            print("unknown action")
        }
        completionHandler()
    }
    
    
    
}
