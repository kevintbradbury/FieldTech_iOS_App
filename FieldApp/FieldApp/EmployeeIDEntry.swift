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
import FirebaseAuth
import UserNotifications
import UserNotificationsUI
import CoreAudioKit
import CoreAudio
import AVKit
import ImagePicker
import Alamofire
import EventKit
import Macaw


class EmployeeIDEntry: UIViewController {
    
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet var roleSelection: UIPickerView!
    @IBOutlet weak var enterIDText: UILabel!
    @IBOutlet weak var employeeID: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var clockIn: UIButton!
    @IBOutlet weak var clockOut: UIButton!
    @IBOutlet weak var lunchBreakBtn: UIButton!
    @IBOutlet weak var activityBckgd: UIView!
    @IBOutlet var animatedClockView: AnimatedClock!
    @IBOutlet var longHand: LongHandAnimated!
    
    
    let firebaseAuth = Auth.auth()
    let main = OperationQueue.main
    let notificationCenter = UNUserNotificationCenter.current()
    let imgPicker = ImagePickerController()
    let dataSource = ["---", "Field", "Shop", "Drive Time", "Measurements"]
    
    var jobAddress = ""
    var jobs: [Job.UserJob] = []
    var safetyQs: [SafetyQuestion] = []
    var todaysJob = Job()
    var location = UserData.init().userLocation
    var firAuthId = UserDefaults.standard.string(forKey: "authVerificationID")
    var hadLunch = false
    var profileUpload: Bool?
    public static var foundUser: UserData.UserInfo?
    public var role: String?
    var imageAssets: [UIImage] {
        return AssetManager.resolveAssets(imgPicker.stack.assets)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        imgPicker.delegate = self
        roleSelection.delegate = self
        roleSelection.dataSource = self
        longHand.backgroundColor = .clear
        animatedClockView.backgroundColor = .clear
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setRoles()
        checkAppDelANDnotif()
        UserLocation.instance.locationManager.startUpdatingLocation()
        activityIndicator.isHidden = true
        activityIndicator.hidesWhenStopped = true
        hideTextfield()
        
        let btns = [sendButton!, clockIn!, clockOut!, lunchBreakBtn!]
        setShadows(btns: btns)
        
        clockIn.isHidden = true
        clockOut.isHidden = true
    }
    
    @IBAction func sendIDNumber(_ sender: Any) { clockInClockOut() }
    @IBAction func backToHome(_ sender: Any) { dismiss(animated: true, completion: nil) }
    @IBAction func goClockIn(_ sender: Any) { clockInClockOut() }
    @IBAction func goClockOut(_ sender: Any) { wrapUpAlert() }
    @IBAction func lunchBrkPunchOut(_ sender: Any) { chooseBreakLength() }
    @IBAction func animatedClockPress(_ sender: Any) { animateOrWrapUp() }
    
}


extension EmployeeIDEntry {
    
    func animateOrWrapUp() {
        if EmployeeIDEntry.foundUser?.punchedIn == true {
            self.wrapUpAlert()
        } else {
            self.clockInClockOut()
        }
    }
    
    func isEmployeeIDNum(callback: @escaping (UserData.UserInfo) -> ()) {
        var employeeNumberToInt: Int?
        
        if EmployeeIDEntry.foundUser?.employeeID != nil {
            guard let employeeNumber = EmployeeIDEntry.foundUser?.employeeID else { return }
            employeeNumberToInt = Int(employeeNumber)
        } else {
            guard let employeeNumber = employeeID.text else { return }
            employeeNumberToInt = Int(employeeNumber)
        }
        
        fetchEmployee(employeeId: employeeNumberToInt!) { user in
            EmployeeIDEntry.foundUser = user
            callback(EmployeeIDEntry.foundUser!)
        }
    }
    
    public func clockInClockOut() {
        let anmation = longHand.node.placeVar.animation(angle: -5.25, x: 0, y: 0, during: 1, delay: 0)
        anmation.cycle().play()
        
        if role != nil && role != "---" && role != "" {
            
            if EmployeeIDEntry.foundUser?.employeeID != nil {
                guard let unwrappedUser = EmployeeIDEntry.foundUser else { return }
                makePunchCall(user: unwrappedUser)
                
            } else if employeeID.text != "" {
                isEmployeeIDNum() { foundUser in
                    self.makePunchCall(user: foundUser)
                }
            } else {
                incorrectID(success: true)
            }
        } else {
            showAlert(withTitle: "No Role", message: "Please select a role before clocking in or out.")
        }
    }
    
    func makePunchCall(user: UserData.UserInfo) {
        guard let coordinate = UserLocation.instance.currentCoordinate,
            let unwrappedRole = role else { return }
        let locationArray = [String(coordinate.latitude), String(coordinate.longitude)]
        
        APICalls().sendCoordinates(
            employee: user,
            location: locationArray,
            autoClockOut: false,
            role: unwrappedRole,
            po: "",
            override: false
        ) { success, currentJob, poNumber, jobLatLong, clockedIn, err in
            self.handleSuccess(
                success: success, currentJob: currentJob, poNumber: poNumber, jobLatLong: jobLatLong, clockedIn: clockedIn, manualPO: false, err: err
            )
        }
    }
    
    func handleSuccess(success: Bool, currentJob: String, poNumber: String, jobLatLong: [Double], clockedIn: Bool, manualPO: Bool, err: String) {
        if success == true {
            print("punched in / out: \(String(describing: EmployeeIDEntry.foundUser?.punchedIn))")
            self.todaysJob.jobName = currentJob
            self.todaysJob.poNumber = poNumber
            self.todaysJob.jobLocation = jobLatLong
            EmployeeIDEntry.foundUser?.punchedIn = clockedIn
            
            self.setClockInNotifcs(clockedIn: clockedIn)
            
        } else if manualPO == false {
            showPONumEntryWin()
        } else if err != "" {
            showAlert(withTitle: "Error", message: err); finishedLoading()
        } else {
            incorrectID(success: success)
        }
    }
    
    func incorrectID(success: Bool) {
        var actionMsg: String {
            if success == true { return "Unable to find that user." }
            else { return "Your location did not match the job location." }
        }
        
        finishedLoading()
        self.main.addOperation {
            self.showAlert(withTitle: "Alert", message: actionMsg)
        }
    }
    
    func setClockInNotifcs(clockedIn: Bool) {
        
        if clockedIn == true {
            let twoHours = Double((2 * 60) * 60)
            let fourHours = Double((4 * 60) * 60)
            var title = "", message = "", identifier = ""
            hadLunch = UserDefaults.standard.bool(forKey: "hadLunch")
            
            if hadLunch == true {
                hadLunch = false;
                UserDefaults.standard.set(false, forKey: "hadLunch")
                title = "Clock Out Reminder"; message = "Time to wrap up for the day."; identifier = "clockOut";
                self.completedProgress()
                
            } else {
                title = "Meal Break Reminder"; message = "Time for Lunch."; identifier = "lunchReminder"
                APICalls().getSafetyQs() { safetyQuestions in
                    self.safetyQs = safetyQuestions
                    self.completedProgress()
                }
            }
            setBreakNotifcs(twoHrs: twoHours, fourHrs: fourHours, title: title, msg: message, idf: identifier)
            
        } else {
            
            if self.hadLunch == false {
                UserDefaults.standard.set(true, forKey: "hadLunch")
                APICalls().getSafetyQs() { safetyQuestions in
                    self.safetyQs = safetyQuestions
                    self.completedProgress()
                }
            } else {
                self.completedProgress()
            }
        }
    }
    
    func setBreakNotifcs(twoHrs: Double, fourHrs: Double, title: String, msg: String, idf: String) {
        let tenMinBreakRmdr = createNotification(
            intervalInSeconds: twoHrs, title: "10 Minute Break",
            message: "Don't forget to take a short 10 minute break.", identifier: "tenMinBrk"
        )
        let clckOutRmndr = createNotification(
            intervalInSeconds: fourHrs, title: title, message: msg, identifier: idf
        )
        
        notificationCenter.add(tenMinBreakRmdr) { (error) in
            if error != nil {
                print("error setting clock notif: \(String(describing: error))")
            }
        }
        notificationCenter.add(clckOutRmndr) { (error) in
            if error != nil {
                print("error setting clock notif: \(String(describing: error))")
            }
        }
        
        if idf == "clockOut" {
            let thirtyMin = Double(60 * 30)
            let jobUpdate = createNotification(
                intervalInSeconds: thirtyMin, title: "Progress Checkup", message: "Hows the job going?", identifier: "jobCheckup"
            )
            notificationCenter.add(jobUpdate) { error in
                if error != nil {
                    print("error setting clock notif: \(String(describing: error))")
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let id = segue.identifier
        UserDefaults.standard.set(EmployeeIDEntry.foundUser?.employeeID, forKey: "employeeID")
        UserDefaults.standard.set(EmployeeIDEntry.foundUser?.userName, forKey: "employeeName")
        
        if id == "return" {
            HomeView.employeeInfo = EmployeeIDEntry.foundUser
            HomeView.todaysJob.jobName = todaysJob.jobName
            HomeView.todaysJob.poNumber = todaysJob.poNumber
            HomeView.todaysJob.jobLocation = todaysJob.jobLocation
            HomeView.role = role
            HomeView.safetyQs = safetyQs
            
        } else  if id == "clockTOchange" {
            let vc = segue.destination as! ChangeOrdersView
            vc.formTypeVal = "Change Order"
        }
    }
    
    func fetchEmployee(employeeId: Int, callback: @escaping (UserData.UserInfo) -> ()){
        let route = "employee/\(String(employeeId))"
        
        APICalls().setupRequest(route: route, method: "GET") { request  in
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error != nil {
                    print("failed to fetch JSON from database \n \(String(describing: error)) \n \(String(describing: response))"); return
                } else {
                    guard let verifiedData = data else { print("could not verify data from dataTask"); return }
                    guard let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary else { print("failed to parse JSON"); return }
                    guard let user = UserData.UserInfo.fromJSON(dictionary: json) else {
                        print("json to UserInfo failed: \(json)")
                        self.main.addOperation { self.incorrectID(success: true) }
                        return
                    }
                    callback(user)
                }
            }; task.resume()
        }
    }
    
    func showPONumEntryWin() {
        let alert = UIAlertController(
            title: "Manual PO Entry",
            message: "No PO found for this time/date, enter PO number manually?",
            preferredStyle: .alert
        )
        
        let manualPOentry = UIAlertAction(title: "Send", style: .default) { action in
            self.inProgressVw()
            
            guard let coordinate = UserLocation.instance.currentCoordinate,
                let uwrappedUsr = EmployeeIDEntry.foundUser,
                let unwrappedRole = self.role else { return }
            
            let locationArray = [String(coordinate.latitude), String(coordinate.longitude)]
            let poNumber = alert.textFields![0]
            var poToString = "";
            
            if poNumber.text != nil && poNumber.text != "" {
                poToString = poNumber.text!
                
                APICalls().sendCoordinates(
                    employee: uwrappedUsr,
                    location: locationArray,
                    autoClockOut: false,
                    role: unwrappedRole,
                    po: poToString,
                    override: true
                ) { success, currentJob, poNumber, jobLatLong, clockedIn, err in
                    self.handleSuccess(success: success, currentJob: currentJob, poNumber: poNumber, jobLatLong: jobLatLong, clockedIn: clockedIn, manualPO: true, err: err)
                }
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .destructive) { action in    self.finishedLoading() }
        
        alert.addTextField { textFieldPhoneNumber in
            textFieldPhoneNumber.placeholder = "PO number"
            textFieldPhoneNumber.keyboardType = UIKeyboardType.asciiCapableNumberPad
        }
        alert.addAction(manualPOentry)
        alert.addAction(cancel)
        
        self.main.addOperation {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func hideTextfield() {
        if EmployeeIDEntry.foundUser != nil {
            guard let punchedIn = EmployeeIDEntry.foundUser?.punchedIn else { return }
            self.main.addOperation {
                self.employeeID.isHidden = true
                self.sendButton.isHidden = true
                self.enterIDText.isHidden = true
                self.animatedClockView.isHidden = false
                
                if punchedIn == true {
                    self.clockIn.isHidden = true
                    self.lunchBreakBtn.isHidden = false
                } else if punchedIn == false {
                    self.clockOut.isHidden = true
                    self.lunchBreakBtn.isHidden = true
                } else {
                    return
                }
            }
        } else {
            self.main.addOperation {
                self.clockIn.isHidden = true
                self.clockOut.isHidden = true
                self.lunchBreakBtn.isHidden = true
                self.animatedClockView.isHidden = true
            }
        }
    }
    
    func inProgressVw() {
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
    
    func finishedLoading() {
        self.main.addOperation {
            self.activityBckgd.isHidden = true
            self.activityIndicator.hidesWhenStopped = true
            self.activityIndicator.stopAnimating()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
}

extension EmployeeIDEntry {
    
    func goOnLunch(breakLength: Double) {
        
        let tenMinBefore = Double( (breakLength * 60) - Double(5 * 60) )
        let breakTmInSeconds = Double(breakLength * 60)
        let earlyrequest = createNotification(
            intervalInSeconds: tenMinBefore, title: "Break Almost Done",
            message: "Break is almost over, start wrapping up.", identifier: "breakAlmostOver"
        )
        let request = createNotification(
            intervalInSeconds: breakTmInSeconds, title: "Break Over",
            message: "Sorry, break time is over.", identifier: "breakOver"
        )
        
        notificationCenter.add(earlyrequest) { (error) in
            if error != nil {
                print("There was an error: \(error?.localizedDescription))")
            }
        }
        
        notificationCenter.add(request) { (error) in
            if error != nil {
                print("There was an error: \(error?.localizedDescription))")
            } else {
                UserDefaults.standard.set(true, forKey: "hadLunch")
                self.hadLunch = true
                self.clockInClockOut()
            }
        }
    }
    
    func chooseBreakLength() {
        let actionsheet = UIAlertController(title: "Lunch Break", message: "Choose your break length", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (action) -> Void in print("chose Cancel") }
        let chooseThirty = UIAlertAction(title: "30 minute Break", style: UIAlertAction.Style.default) { (action) -> Void in self.goOnLunch(breakLength: 30)
        }
        let chooseSixty = UIAlertAction(title: "60 minute Break", style: UIAlertAction.Style.default) { (action) -> Void in self.goOnLunch(breakLength: 60)
        }
        
        actionsheet.addAction(chooseThirty)
        actionsheet.addAction(chooseSixty)
        actionsheet.addAction(cancel)
        
        self.present(actionsheet, animated: true)
    }
    
    public func wrapUpAlert() {
        let actionsheet = UIAlertController(
            title: "Reminder",
            message: " Is the Job site clean? \n Have you taken photos? \n Have materials been ordered?",
            preferredStyle: .alert
        )
        let clockInNOut = UIAlertAction(title: "OK, Clock Me Out", style: .destructive) { (action) -> Void in
            self.clockInClockOut()
        }
        let reqMaterials = UIAlertAction(title: "WAIT, go request materials", style: .default) { (action) -> Void in
            self.performSegue(withIdentifier: "clockTOchange", sender: nil)
        }
        let takePhotos = UIAlertAction(title: "WAIT, go to camera", style: .default) { (action) -> Void in
            self.present(self.imgPicker, animated: true, completion: nil)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
        }
        
        actionsheet.addAction(clockInNOut)
        actionsheet.addAction(reqMaterials)
        actionsheet.addAction(takePhotos)
        actionsheet.addAction(cancel)
        
        self.main.addOperation {
            self.present(actionsheet, animated: true)
        }
    }
    
    func checkForUserInfo() {
        if HomeView.employeeInfo?.employeeID != nil {
            print("punched in -- \(String(describing: HomeView.employeeInfo!.punchedIn))")
            HomeView().checkPunchStatus()

        } else {
            if let employeeID = UserDefaults.standard.string(forKey: "employeeID") {
                inProgressVw()

                APICalls().fetchEmployee(employeeId: Int(employeeID)!) { user, addressInfo  in
                    HomeView.employeeInfo = user
                    HomeView.addressInfo = addressInfo
                    HomeView().checkPunchStatus()
                }
            } else { completedProgress() }
        }
    }
    
    func checkSuccess(responseType: [String: String]) {
        completedProgress()
        self.handleResponseType(responseType: responseType)
    }
    
    func checkAppDelANDnotif() {
        let appDelegate: AppDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.myEmployeeVC = self
        
        if appDelegate.didEnterBackground == true {
            notificationCenter.getDeliveredNotifications() { notifications in
                for singleNote in notifications {
                    print("request in notif center: \(singleNote.request.identifier)" )
                }
            }
        }
    }
}

extension EmployeeIDEntry: ImagePickerDelegate {
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        print("wrapper did press")
        imagePicker.expandGalleryView()
    }

    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        let imgs = imageAssets
        print("images to upload: \(imgs.count)")

        if let emply =  UserDefaults.standard.string(forKey: "employeeName") {
            if imgs.count < 11 {
                inProgressVw()
                
                if let po = UserDefaults.standard.string(forKey: "todaysJobPO") {
                    uploadJobImages(images: imgs, jobNumber: po, employee: emply) { responseType in
                        self.checkSuccess(responseType: responseType)
                    }
                } else {
                    uploadJobImages(images: imgs, jobNumber: "---", employee: "---") { responseType in
                        self.checkSuccess(responseType: responseType)
                    }
                };  dismiss(animated: true, completion: nil)
            } else {
                imgPicker.showAlert(withTitle: "Max Photos", message: "You can only upload a maximum of 10 photos each time.")
            }
        }
    }

    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
}

extension EmployeeIDEntry: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func setRoles() {
        if let verifiedRole = role as? String {
            if verifiedRole != nil && verifiedRole != "" {
                guard let index = dataSource.firstIndex(where: { (obj) -> Bool in
                    obj == verifiedRole
                }) else  { return }
                
                roleSelection.selectRow(index, inComponent: 0, animated: true)
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSource.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dataSource[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        role = dataSource[row]
    }
    
}



