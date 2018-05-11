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
import EventKit
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
    var alarmStopped = false
    var socket = WebSocket(url: URL(string: "ws://mb-server-app-kbradbury.c9users.io/")!, protocols:["chat"])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
        activityIndicator.hidesWhenStopped = true
        UserLocation.instance.initialize()
        hideTextfield()
    }

//    deinit { socket.disconnect(forceTimeout: 0); socket.delegate = nil }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    func isEmployeeIDNum(callback: @escaping (UserData.UserInfo) -> ()) {
        
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
    func sendData(_ data: Data) { socket.write(data: data) }
    
    @IBAction func sendIDNumber(_ sender: Any) {
        
        activityIndicator.startAnimating()
        if employeeID.text != "" {
            isEmployeeIDNum() { foundUser in
                self.getLocation() { coordinate in
                    let locationArray = [String(coordinate.latitude), String(coordinate.longitude)]
                    APICalls().sendCoordinates(employee: foundUser, location: locationArray) { success, currentJob, poNumber in
                        self.todaysJob.jobName = currentJob
                        self.todaysJob.poNumber = poNumber
                        self.handleSuccess(success: success)
                    }
                }
            }
        } else {
            self.incorrectID(success: true)
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
            self.socket.delegate = self
            self.socket.connect()
        } else {
            self.incorrectID(success: true)
        }
    }
    
    func handleSuccess(success: Bool) {
        if success == true {
            if self.foundUser?.punchedIn == true {
                self.foundUser?.punchedIn = false
                self.completedProgress()
                
            } else if self.foundUser?.punchedIn == false {
                self.foundUser?.punchedIn = true
                self.completedProgress()
            }
        } else {
            print("unsuccessful location punch in")
            //handle unsuccessful location punch in
            incorrectID(success: success)
        }
    }
    
    func incorrectID(success: Bool) {
        var actionMsg: String {
            if success == true {
                return "Unable to find that user"
            } else {
                return "Your location did not match the job location"
            }
        }
        let actionsheet = UIAlertController(title: "Error", message: actionMsg, preferredStyle: UIAlertControllerStyle.alert)
        
        let ok = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) {(action) in
            self.employeeID.text = ""
            actionsheet.dismiss(animated: true, completion: nil)
            self.main.addOperation {
                self.activityBckgd.isHidden = true
                self.activityIndicator.hidesWhenStopped = true
                self.activityIndicator.stopAnimating()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
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
            vc.todaysJob.jobName = todaysJob.jobName
            vc.todaysJob.poNumber = todaysJob.poNumber
            
            print(todaysJob.poNumber)
//            vc.firAuthId = firAuthId
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
                    print(json)
                    //
                    
                    self.main.addOperation {
                        self.incorrectID(success: true)
                    }
                    return
                }
                callback(user)
            }
        }
        task.resume()
    }
    
    
}

extension EmployeeIDEntry: WebSocketDelegate {
    func websocketDidConnect(_ socket: WebSocket) {
        print("web socket was able to connect")
        
        guard let uwrappedUser = foundUser else { return }
        self.getLocation() { coordinate in
            let locationArray = [String(coordinate.latitude), String(coordinate.longitude)]
            let data = APICalls().convertToJSON(employee: uwrappedUser, location: locationArray)
            self.sendData(data)
            
//            APICalls().sendCoordinates(employee: uwrappedUser, location: locationArray) { success, currentJob, poNumber  in
//                self.todaysJob.jobName = currentJob
//                self.todaysJob.poNumber = poNumber
//                print("todays job po name & number: ")
//                print(self.todaysJob.jobName, self.todaysJob.jobName)
//                self.handleSuccess(success: success)
//            }
        }
    }
    func websocketDidDisconnect(_ socket: WebSocket, error: NSError?) {
        print("web socket DISconnected")
    }
    
    func websocketDidReceiveMessage(_ socket: WebSocket, text: String) {
        //        guard let data = text.data(using: .utf16),
    }
    
    func websocketDidReceiveData(_ socket: WebSocket, data: Data) {
        print("did recieve binary data from server socket")
        guard let recievedData = (try? JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>) else { return }
        print(recievedData)
        // Bool string string
        guard let success = recievedData!["success"] as? Int else { return }
        guard let po = recievedData!["poNumber"] as? String else { return }
        guard let jobName = recievedData!["job"] as? String else { return }
        
        if success == 1 { handleSuccess(success: true) } else { handleSuccess(success: false) }
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
        
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let stopAction = UNNotificationAction(identifier: "STOP_ACTION", title: "Stop", options: .destructive)
        let alarmCategory = UNNotificationCategory(identifier: "alarm.category", actions: [stopAction], intentIdentifiers: [], options: [])
        
        let identifier = "EndOFBreak"
        let timeInSeconds = Double(breakLength * 60)
        let content = UNMutableNotificationContent()
        content.title = "Sorry, break time is over"
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = "alarm.category"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInSeconds, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.setNotificationCategories([alarmCategory])
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
        notificationCenter.add(request, withCompletionHandler: { (err) in
            if err != nil {
                print("there was an error")
                print(err)
            } else {
                
                let fiveMinInSec = Double(5 * 60)
                let tenMinBefore = Double((breakLength * 60) - fiveMinInSec)
                let earlyContent = UNMutableNotificationContent()
                let earlyidentifier = "fiveMinReminder"
                earlyContent.title = "Break is almost over"
                earlyContent.sound = UNNotificationSound.default()
                earlyContent.categoryIdentifier = "alarm.category"
                
                let earlytrigger = UNTimeIntervalNotificationTrigger(timeInterval: tenMinBefore, repeats: false)
                let earlyrequest = UNNotificationRequest(identifier: earlyidentifier, content: earlyContent, trigger: earlytrigger)
                
                self.notificationCenter.add(earlyrequest, withCompletionHandler: { (err) in
                    if err != nil {
                        print("looks like there was an error")
                        print(err)
                    } else {
                        self.clockInClockOut()
                    }
                })
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
    
    
    //Doesn't set an alarm but does add an event to calendar, which may be useeful for adding jobs to internal calendar
    func setAnAlarm() {
        var calendar: EKCalendar?
        let eventstore = EKEventStore()
        
        eventstore.requestAccess(to: EKEntityType.event){ (granted, error ) -> Void in
            if granted == true {
                let event = EKEvent(eventStore: eventstore)
                event.startDate = Date()
                event.endDate = event.startDate.addingTimeInterval(TimeInterval(60 * 60))
                event.calendar = eventstore.defaultCalendarForNewEvents
                event.title = "Break is over"
                event.addAlarm(EKAlarm(relativeOffset: TimeInterval(10)))
                
                do {
                    try eventstore.save(event, span: .thisEvent, commit: true)
                } catch { (error)
                    if error != nil {
                        print("looks like we couldn't setup that alarm")
                        print(error)
                    }
                }
                
            }
        }
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
