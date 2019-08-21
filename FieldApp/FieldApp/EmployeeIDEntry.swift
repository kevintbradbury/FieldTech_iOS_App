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
import MLPAutoCompleteTextField


class EmployeeIDEntry: UIViewController, UITextFieldDelegate, MLPAutoCompleteTextFieldDelegate, MLPAutoCompleteTextFieldDataSource {
    
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet var roleSelection: UIPickerView!
    @IBOutlet weak var enterIDText: UILabel!
    @IBOutlet weak var employeeID: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var clockIn: UIButton!
    @IBOutlet weak var clockOut: UIButton!
    @IBOutlet weak var lunchBreakBtn: UIButton!
    @IBOutlet var animatedClockView: AnimatedClock!
    @IBOutlet var longHand: LongHandAnimated!
    @IBOutlet var manualPOentryVw: UIView!
    @IBOutlet var poNumberField: MLPAutoCompleteTextField!
    @IBOutlet var sendManualPOBtn: UIButton!
    @IBOutlet var cancelManualBtn: UIButton!
    
    
    let firebaseAuth = Auth.auth()
    let main = OperationQueue.main
    let notificationCenter = UNUserNotificationCenter.current()
    let imgPicker = ImagePickerController()
    let dataSource = ["Field", "Shop", "Drive Time", "Measurements"]
    var autoCompleteDtSrc: MLPAutoCompleteTextFieldDataSource?
    
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
        checkForNotifUpdates()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "EmployeeIDentry View"
        
        print("current loc: \(location)")
        
        setRoles()
        checkAppDelANDnotif()
        UserLocation.instance.locationManager.startUpdatingLocation()
        hideTextfield()
        
        let btns = [sendButton!, clockIn!, clockOut!, lunchBreakBtn!]
        setShadows(btns: btns)
        setThisDismissableKeyboard()
    }
    
    @IBAction func sendIDNumber(_ sender: Any) { clockInClockOut() }
    @IBAction func backToHome(_ sender: Any) { dismiss(animated: true, completion: nil) }
    @IBAction func goClockIn(_ sender: Any) { clockInClockOut() }
    @IBAction func goClockOut(_ sender: Any) { wrapUpAlert() }
    @IBAction func lunchBrkPunchOut(_ sender: Any) { chooseBreakLength() }
    @IBAction func animatedClockPress(_ sender: Any) { animateOrWrapUp() }
    @IBAction func sendManualPOentry(_ sender: Any) { sendManualEntry() }
    @IBAction func hideManualPOview(_ sender: Any) { manualPOentryVw.isHidden = true }
    
    
}

extension EmployeeIDEntry {
    
    func setThisDismissableKeyboard() {
        OperationQueue.main.addOperation {
            self.view.frame.origin.y = 0
            self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
            
            NotificationCenter.default.addObserver(
                self, selector: #selector(self.thisKeyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil
            )
            NotificationCenter.default.addObserver(
                self, selector: #selector(self.thisKeyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil
            )
            NotificationCenter.default.addObserver(
                self, selector: #selector(self.thisKeyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil
            )
        }
    }
    
    @objc func thisKeyboardWillChange(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
            
            if self.poNumberField.isFirstResponder == true {
                OperationQueue.main.addOperation {
                    self.view.frame.origin.y = -(keyboardRect.height - (keyboardRect.height / 4))
                }
            }
        } else {
            OperationQueue.main.addOperation {
                self.view.frame.origin.y = 0
            }
        }
    }
    
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
        guard let coordinates = UserLocation.instance.currentCoordinate,
            let unwrappedRole = role else { return }
        
        inProgress(showProgress: false)
        
        if let validPO = UserDefaults.standard.string(forKey: DefaultKeys.todaysJobPO) {
            
            APICalls().sendCoordinates(
                employee: user, location: coordinates, autoClockOut: false, role: unwrappedRole, po: validPO, override: false
            ) { success, currentJob, poNumber, jobLatLong, clockedIn, err in
                
                self.handleSuccess(
                    success: success, currentJob: currentJob, poNumber: poNumber, jobLatLong: jobLatLong, clockedIn: clockedIn, manualPO: true, err: err
                )
            }
        } else {
            showPONumEntryWin()
        }
    }
    
    func handleSuccess(success: Bool, currentJob: String, poNumber: String, jobLatLong: [Double], clockedIn: Bool, manualPO: Bool, err: String?) {
        completeProgress()
        
        if success == true {
            UserDefaults.standard.set(poNumber, forKey: "todaysJobPO")
            
            print("punched in / out: \(String(describing: EmployeeIDEntry.foundUser?.punchedIn))")
            self.todaysJob.jobName = currentJob
            self.todaysJob.poNumber = poNumber
            self.todaysJob.jobLocation = jobLatLong
            EmployeeIDEntry.foundUser?.punchedIn = clockedIn
            
            self.setClockInNotifcs(clockedIn: clockedIn)
            
        } else if manualPO == true {
            showPONumEntryWin()
        } else if err != nil {
            guard let error = err else {
                showAlert(withTitle: "Error", message: "Unable to fetch info from Server.")
                completeProgress()
                return
            }
            showAlert(withTitle: "Error", message: error)
            completeProgress()
        } else {
            incorrectID(success: success)
        }
    }
    
    func incorrectID(success: Bool) {
        var actionMsg: String {
            if success == true { return "Unable to find that user." }
            else { return "Your location did not match the job location." }
        }
        
        completeProgress()
        self.main.addOperation { self.showAlert(withTitle: "Alert", message: actionMsg) }
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
                self.completedIDcheckProgress()
                
            } else {
                title = "Meal Break Reminder"; message = "Time for Lunch."; identifier = "lunchReminder"
                APICalls().getSafetyQs() { safetyQuestions in
                    self.safetyQs = safetyQuestions
                    self.completedIDcheckProgress()
                }
            }
            setBreakNotifcs(twoHrs: twoHours, fourHrs: fourHours, title: title, msg: message, identifier: identifier)
            
        } else {
            
            if hadLunch == false {
                UserDefaults.standard.set(true, forKey: "hadLunch")
                
                APICalls().getSafetyQs() { safetyQuestions in
                    self.safetyQs = safetyQuestions
                    self.completedIDcheckProgress()
                }
            } else {
                self.completedIDcheckProgress()
            }
        }
    }
    
    func setBreakNotifcs(twoHrs: Double, fourHrs: Double, title: String, msg: String, identifier: String) {
        let tenMinBreakRmdr = createNotification(
            intervalInSeconds: twoHrs, title: "10 Minute Break",
            message: "Don't forget to take a short 10 minute break.", identifier: "tenMinBrk"
        )
        let clckOutRmndr = createNotification(
            intervalInSeconds: fourHrs, title: title, message: msg, identifier: identifier
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
        
        if identifier == "clockOut" {
            let twoHours = Double(60 * 60 * 1.9)
            let jobUpdate = createNotification(
                intervalInSeconds: twoHours, title: "Progress Checkup", message: "Hows the job going?", identifier: "jobCheckup"
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
        UserDefaults.standard.set(EmployeeIDEntry.foundUser?.employeeID, forKey: DefaultKeys.employeeID)
        UserDefaults.standard.set(EmployeeIDEntry.foundUser?.username, forKey: DefaultKeys.employeeName)
        
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
    
    func fetchEmployee(employeeId: Int, callback: @escaping (UserData.UserInfo) -> () ) {
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
    
    func sendManualEntry() {
        
        guard let coordinates = UserLocation.instance.currentCoordinate,
            let uwrappedUsr = EmployeeIDEntry.foundUser,
            let unwrappedRole = self.role,
            let po = poNumberField.text else {
                print("no coordinates, user, role, or PO found")
                return
        }
        inProgress(showProgress: false)
        
        APICalls().sendCoordinates(
            employee: uwrappedUsr, location: coordinates, autoClockOut: false, role: unwrappedRole, po: po, override: true
        ) { success, currentJob, poNumber, jobLatLong, clockedIn, err in
            self.handleSuccess(
                success: success, currentJob: currentJob, poNumber: poNumber, jobLatLong: jobLatLong, clockedIn: clockedIn, manualPO: false, err: err
            )
        }
    }
    
    func showPONumEntryWin() {
        poNumberField.autoCompleteDelegate = self
        
        main.addOperation {
            self.manualPOentryVw.isHidden = false
            self.manualPOentryVw.layer.cornerRadius = 10
            
            self.poNumberField.delegate = self
            self.poNumberField.autoCompleteTableAppearsAsKeyboardAccessory = true
            
            self.roundCorners(corners: [.bottomLeft], radius: 10, vw: self.sendManualPOBtn)
            self.roundCorners(corners: [.bottomRight], radius: 10, vw: self.cancelManualBtn)
        }
        
        inProgress(showProgress: false)
        
        APICalls().getJobNames() { err, jobs in
            self.completeProgress()
            
            if err != nil {
                guard let safeErr = err else { return }
                self.showAlert(withTitle: "Error", message: safeErr)
            } else if let theseJobs = jobs {
                self.autoCompleteDtSrc = AutoCompleteDataSrc().initialize(pos: theseJobs)
                self.poNumberField.autoCompleteDataSource = self.autoCompleteDtSrc
            }
        }
    }
    
    func hideTextfield() {
        view.accessibilityIdentifier = "EmployeeIDentry View"
        
        roleSelection.accessibilityIdentifier = "IDentry_roleSelection"
        enterIDText.accessibilityIdentifier = "IDentry_enterIDText"
        employeeID.accessibilityIdentifier = "IDentry_employeeID"
        sendButton.accessibilityIdentifier = "IDentry_sendButton"
        clockIn.accessibilityIdentifier = "IDentry_clockIn"
        clockOut.accessibilityIdentifier = "IDentry_clockOut"
        lunchBreakBtn.accessibilityIdentifier = "IDentry_lunchBreakBtn"
        animatedClockView.accessibilityIdentifier = "IDentry_animatedClockView"
        longHand.accessibilityIdentifier = "IDentry_longHand"
        manualPOentryVw.accessibilityIdentifier = "IDentry_manualPOentryVw"
        poNumberField.accessibilityIdentifier = "IDentry_poNumberField"
        sendManualPOBtn.accessibilityIdentifier = "IDentry_sendManualPOBtn"
        cancelManualBtn.accessibilityIdentifier = "IDentry_cancelManualBtn"
        //        activityIndicator.accessibilityIdentifier = "IDentry_activityIndicator"
        //        activityBckgd.accessibilityIdentifier = "IDentry_activityBckgd"
        
        main.addOperation {
            self.manualPOentryVw.isHidden = true
//            self.activityIndicator.isHidden = true
//            self.activityIndicator.hidesWhenStopped = true
            self.clockIn.isHidden = true
            self.clockOut.isHidden = true
        }
        
        if EmployeeIDEntry.foundUser != nil {
            guard let punchedIn = EmployeeIDEntry.foundUser?.punchedIn else { return }
            self.main.addOperation {
                self.employeeID.isHidden = true
                self.sendButton.isHidden = true
                self.enterIDText.isHidden = true
                self.animatedClockView.isHidden = false
                self.longHand.isHidden = false
                
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
                self.longHand.isHidden = true
            }
        }
    }
    
    func completedIDcheckProgress() {
        completeProgress()
        
        if self.hadLunch == true {
            let breakPopup = UIAlertController(title: "Clocked Out", message: "You clocked out for a meal break.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default) { action in
                self.performSegue(withIdentifier: "return", sender: self)
            }
            
            breakPopup.addAction(ok)
            
            self.main.addOperation { self.present(breakPopup, animated: true, completion: nil) }
        } else {
            self.main.addOperation { self.performSegue(withIdentifier: "return", sender: self) }
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
        let chooseThirty = UIAlertAction(title: "30 Minute Break", style: UIAlertAction.Style.default) { (action) -> Void in
            self.goOnLunch(breakLength: 30)
        }
        let chooseSixty = UIAlertAction(title: "60 Minute Break", style: UIAlertAction.Style.default) { (action) -> Void in
            self.goOnLunch(breakLength: 60)
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
        let reqMaterials = UIAlertAction(title: "WAIT, Go request materials", style: .default) { (action) -> Void in
            self.performSegue(withIdentifier: "clockTOchange", sender: nil)
        }
        let takePhotos = UIAlertAction(title: "WAIT, Go to camera", style: .default) { (action) -> Void in
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
                inProgress(showProgress: false)
                
                APICalls().fetchEmployee(employeeId: Int(employeeID)!) { user, addressInfo  in
                    if let validUser = user as? UserData.UserInfo,
                        let validAddress = addressInfo as? UserData.AddressInfo {                        
                        HomeView.employeeInfo = user
                        HomeView.addressInfo = addressInfo
                    }
                    HomeView().checkPunchStatus()
                }
            } else { completedIDcheckProgress() }
        }
    }
    
    func checkSuccess(responseType: [String: String]) {
        completedIDcheckProgress()
        self.handleResponseType(responseType: responseType, formType: "Image(s) Upload")
    }
    
    func checkAppDelANDnotif() {
        let appDelegate: AppDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.myEmployeeVC = self
        
        if appDelegate.didEnterBackground == true {
            notificationCenter.getDeliveredNotifications() { notifications in
                print("request(s) in notif center: \(notifications.count)" )
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
                inProgress(showProgress: false)
                
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
        role = dataSource[0]
        
        if let verifiedRole = role as? String {
            if verifiedRole != nil && verifiedRole != "" {
                guard let index = dataSource.firstIndex(where: { (obj) -> Bool in
                    obj == verifiedRole
                }) else  { return }
                
                roleSelection.selectRow(index, inComponent: 0, animated: true)
                role = dataSource[index]
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSource.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dataSource[row]
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        roleSelection.accessibilityIdentifier = "IDentry_roleSelection"

        pickerLabel.font = UIFont(name: "Helvetica", size: 28)
        pickerLabel.textAlignment = .center
        pickerLabel.text = dataSource[row]
        
        return pickerLabel
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        role = dataSource[row]
    }
    
}


extension EmployeeIDEntry {    // MLPAutoCompleteTextFieldDelegate
    
    func autoCompleteTextField(_ textField: MLPAutoCompleteTextField!, willShowAutoComplete autoCompleteTableView: UITableView!) {
        print("autoCompleteTextField: willShowAutoComplete")
    }
    func autoCompleteTextField(_ textField: MLPAutoCompleteTextField!, shouldConfigureCell cell: UITableViewCell!, withAutoComplete autocompleteString: String!, with boldedString: NSAttributedString!, forAutoComplete autocompleteObject: MLPAutoCompletionObject!, forRowAt indexPath: IndexPath!) -> Bool {
        return true
    }
    func autoCompleteTextField(_ textField: MLPAutoCompleteTextField!, shouldStyleAutoComplete autoCompleteTableView: UITableView!, for borderStyle: UITextField.BorderStyle) -> Bool {
        return true
    }
    func autoCompleteTextField(_ textField: MLPAutoCompleteTextField!, didSelectAutoComplete selectedString: String!, withAutoComplete selectedObject: MLPAutoCompletionObject!, forRowAt indexPath: IndexPath!) {
        print("didSelectAutoComplete")
        let split = selectedString.components(separatedBy: " - ")
        textField.text = split[0]
    }
}
