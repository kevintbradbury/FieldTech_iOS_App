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
import CoreAudioKit
import CoreAudio
import AVKit
import Starscream


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
    let notificationCenter = UNUserNotificationCenter.current()
    
    var jobAddress = ""
    var jobs: [Job.UserJob] = []
    var todaysJob = Job()
    var foundUser: UserData.UserInfo?
    var location = UserData.init().userLocation
    var firAuthId = UserDefaults.standard.string(forKey: "authVerificationID")
    var hadLunch = false

    override func viewDidLoad() {
        super.viewDidLoad()
        UserLocation.instance.locationManager.startUpdatingLocation()
        activityIndicator.isHidden = true
        activityIndicator.hidesWhenStopped = true
        hideTextfield()
    }
    
    @IBAction func sendIDNumber(_ sender: Any) { clockInClockOut() }
    @IBAction func backToHome(_ sender: Any) { dismiss(animated: true, completion: nil) }
    @IBAction func goClockIn(_ sender: Any) { clockInClockOut() }
    @IBAction func goClockOut(_ sender: Any) { clockInClockOut() }
    @IBAction func lunchBrkPunchOut(_ sender: Any) { chooseBreakLength() }
    
    func isEmployeeIDNum(callback: @escaping (UserData.UserInfo) -> ()) {
        var employeeNumberToInt: Int?
        
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
    
    func clockInClockOut() {
        inProgress()
        
        if foundUser?.employeeID != nil {
            guard let unwrappedUser = foundUser else { return }
            makeAcall(user: unwrappedUser)
            
        } else if employeeID.text != "" {
            isEmployeeIDNum() { foundUser in
                self.makeAcall(user: foundUser)
            }
            
        } else { self.incorrectID(success: true) }
    }
    
    func makeAcall(user: UserData.UserInfo) {
        guard let coordinate = UserLocation.instance.currentCoordinate else { return }
        let locationArray = [String(coordinate.latitude), String(coordinate.longitude)]
        
        APICalls().sendCoordinates(employee: user, location: locationArray, autoClockOut: false) { success, currentJob, poNumber, jobLatLong, clockedIn in
            self.handleSuccess(success: success, currentJob: currentJob, poNumber: poNumber, jobLatLong: jobLatLong, clockedIn: clockedIn)
        }
    }
    
    func handleSuccess(success: Bool, currentJob: String, poNumber: String, jobLatLong: [Double], clockedIn: Bool) {
        if success == true {
            print("punched in / out: \(String(describing: foundUser?.punchedIn))")
            self.todaysJob.jobName = currentJob
            self.todaysJob.poNumber = poNumber
            self.todaysJob.jobLocation = jobLatLong
            self.foundUser?.punchedIn = clockedIn
            self.completedProgress()
            
            if clockedIn == true {
                let fourHours = Double((4 * 60) * 60)
                var title = "Reminder", message = "Message", identifier = "identifier"
                
                func checkLunch() {
                    hadLunch = UserDefaults.standard.bool(forKey: "hadLunch")
                    if hadLunch == true {
                        title = "Clock Out Reminder"; message = "Time to wrap up for the day."; identifier = "clockOut";
                        hadLunch = false; UserDefaults.standard.set(nil, forKey: "hadLunch")
                    } else {
                        title = "Meal Break Reminder"; message = "Time for Lunch."; identifier = "lunchReminder"
                    }
                }
                checkLunch()
                let request = createNotification(intervalInSeconds: fourHours, title: title, message: message, identifier: identifier)
                notificationCenter.add(request) { (error) in
                    if error != nil { print("error setting clock notif: "); print(error) } else { print("added reminder at 4 hour mark") }
                }
            }
        } else { incorrectID(success: success) }
    }
    
    func incorrectID(success: Bool) {
        var actionMsg: String {
            if success == true { return "Unable to find that user." }
            else { return "Your location did not match the job location." }
        }
        
        self.main.addOperation {
            self.activityBckgd.isHidden = true
            self.activityIndicator.hidesWhenStopped = true
            self.activityIndicator.stopAnimating()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        
        showAlert(withTitle: "Alert", message: actionMsg)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! HomeView
        
        UserDefaults.standard.set(foundUser?.employeeID, forKey: "employeeID")
        UserDefaults.standard.set(foundUser?.userName, forKey: "employeeName")
        
        if segue.identifier == "return" {
            vc.employeeInfo?.punchedIn = foundUser?.punchedIn
            vc.todaysJob.jobName = todaysJob.jobName
            vc.todaysJob.poNumber = todaysJob.poNumber
            vc.todaysJob.jobLocation = todaysJob.jobLocation
        }
    }
    
    func fetchEmployee(employeeId: Int, callback: @escaping (UserData.UserInfo) -> ()){
        let route = "employee/" + String(employeeId)
        let request = APICalls().setupRequest(route: route, method: "GET")
        let session = URLSession.shared;
        
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                print("failed to fetch JSON from database \n \(String(describing: response)) \n \(String(describing: error))"); return
            } else {
                guard let verifiedData = data else { print("could not verify data from dataTask"); return }
                guard let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary else { return }
                guard let user = UserData.UserInfo.fromJSON(dictionary: json) else {
                    print("json serialization failed: \(json)")
                    self.main.addOperation {self.incorrectID(success: true)}
                    return
                }
                callback(user)
            }
        }
        task.resume()
    }
}

extension EmployeeIDEntry: WebSocketDelegate {
    func websocketDidConnect(_ socket: WebSocket) { print("web socket was able to connect") }
    func websocketDidDisconnect(_ socket: WebSocket, error: NSError?) { print("web socket DISconnected") }
    func websocketDidReceiveData(_ socket: WebSocket, data: Data) { print("did recieve binary data from server socket") }
    func websocketDidReceiveMessage(_ socket: WebSocket, text: String) { print("web socket received message") }
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
                self.lunchBreakBtn.isHidden = true
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
        print("updated punch in-out is now: \(String(describing: foundUser?.punchedIn))")
        
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
    
    func goOnLunch(breakLength: Double) {
        let timeInSeconds = Double(breakLength * 60)
        let request = createNotification(intervalInSeconds: timeInSeconds, title: "Break Over", message: "Sorry, break time is over.", identifier: "breakOver")
        
        notificationCenter.add(request, withCompletionHandler: { (error) in
            if error != nil { print("there was an error: "); print(error) } else {
                let fiveMinInSec = Double(5 * 60)
                let tenMinBefore = Double((breakLength * 60) - fiveMinInSec)
                let earlyrequest = self.createNotification(intervalInSeconds: tenMinBefore, title: "Break Almost Done", message: "Break is almost over, start wrapping up.", identifier: "breakAlmostOver")
                
                self.notificationCenter.add(earlyrequest, withCompletionHandler: { (error) in
                    if error != nil {
                        print("looks like there was an error: "); print(error)
                    } else {
                        UserDefaults.standard.set(true, forKey: "hadLunch")
                        self.hadLunch = true
                        self.clockInClockOut()
                    }
                })
            }
        })
    }
    
    func chooseBreakLength() {
        let actionsheet = UIAlertController(title: "Lunch Break", message: "Choose your break length", preferredStyle: UIAlertControllerStyle.actionSheet)
        let chooseThirty = UIAlertAction(title: "30 minute Break", style: UIAlertActionStyle.default) { (action) -> Void in self.goOnLunch(breakLength: 30) }
        let chooseSixty = UIAlertAction(title: "60 minute Break", style: UIAlertActionStyle.default) { (action) -> Void in self.goOnLunch(breakLength: 60) }
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive) { (action) -> Void in print("chose Cancel") }
        
        actionsheet.addAction(chooseThirty)
        actionsheet.addAction(chooseSixty)
        actionsheet.addAction(cancel)
        
        self.present(actionsheet, animated: true)
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

extension UIViewController {
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



