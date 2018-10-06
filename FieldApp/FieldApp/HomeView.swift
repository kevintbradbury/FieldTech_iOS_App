//
//  HomeView.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/26/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import CoreLocation
import UserNotifications
import UserNotificationsUI
import ImagePicker
import Alamofire
import Macaw
//import FirebaseStorage
//import SwiftyJSON

class HomeView: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var labelBkgd: UIView!
    @IBOutlet weak var clockInOut: UIButton!
    @IBOutlet weak var choosePhotoButton: UIButton!
    @IBOutlet weak var toolsRentButton: UIButton!
    @IBOutlet weak var hotelResButton: UIButton!
    @IBOutlet weak var timeOffButton: UIButton!
    @IBOutlet weak var calendarButton: UIButton!
    @IBOutlet weak var changOrderButton: UIButton!
    @IBOutlet weak var materialReqButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityBckgd: UIView!
    @IBOutlet var logoView: UIView!
    @IBOutlet var logoImage: UIImageView!
    
    let notificationCenter = UNUserNotificationCenter.current()
    let picker = ImagePickerController()
    let firebaseAuth =  Auth.auth()
    
    var firAuthId = UserDefaults.standard.string(forKey: "authVerificationID")
    var main = OperationQueue.main
    var jobs: [Job.UserJob] = []
    public static var employeeInfo: UserData.UserInfo?
    public static var todaysJob = Job()
    public static var role: String?
    public var imageAssets: [UIImage] {
        return AssetManager.resolveAssets(picker.stack.assets)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserLocation.instance.initialize()
        
        activityIndicator.isHidden = true
        activityIndicator.hidesWhenStopped = true
        picker.delegate = self
        
        Auth.auth().addStateDidChangeListener() { (auth, user) in
            if user == nil { self.dismiss(animated: true) }
        }
        setUpNotifications()
        checkAppDelANDnotif()
        NotificationCenter.default.addObserver(self, selector: #selector(checkForUserInfo), name: .info, object: nil)
        
        let btns = [
            clockInOut!, choosePhotoButton!, toolsRentButton!, hotelResButton!, timeOffButton!, calendarButton!, changOrderButton!, materialReqButton!
        ]
        setShadows(btns: btns)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        checkForUserInfo()
    }
    
    @IBAction func logoutPressed(_ sender: Any) { logOut() }
    @IBAction func goClockInOut(_ sender: Any) { performSegue(withIdentifier: "clock_in", sender: self) }
    @IBAction func rentalOrReturn(_ sender: Any) { showRentOrReturnWin() }
    @IBAction func goToSchedule(_ sender: Any) { performSegue(withIdentifier: "schedule", sender: self) }
    @IBAction func chooseUploadMethod(_ sender: Any) {
        present(picker, animated: true, completion: nil)
        picker.showAlert(withTitle: "Reminder", message: "Make sure to clear area of tools, cables, debris, or other materials, before taking a photo. ")
    }
    
}

extension HomeView {
    
    func checkAppDelANDnotif() {
        let appDelegate: AppDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.myViewController = self
        
        if appDelegate.didEnterBackground == true {
            notificationCenter.getDeliveredNotifications() { notifications in
                if notifications != nil {
                    for singleNote in notifications { print("request in notif center: ", singleNote.request.identifier) }
                }
            }
        }
    }
    
    func logOut() {
        do { try firebaseAuth.signOut() }
        catch let signOutError as NSError {
            showAlert(withTitle: "Error signing out: %@", message:  "\(signOutError)")
            print("Error signing out: %@", signOutError); return }
    }
    
    func setMonitoringForJobLoc() {
        if HomeView.role == "Driver" || HomeView.role == "Measurements" {
            UserDefaults.standard.set(HomeView.todaysJob.poNumber, forKey: "todaysJobPO")
            UserDefaults.standard.set(HomeView.todaysJob.jobName, forKey: "todaysJobName")
            
        } else if HomeView.todaysJob.jobName != nil && HomeView.todaysJob.jobLocation?[0] != nil && HomeView.todaysJob.jobLocation?[1] != nil && HomeView.todaysJob.jobLocation?.count == 2 {
            guard let lat = HomeView.todaysJob.jobLocation?[0] as? CLLocationDegrees else { return }
            guard let lng = HomeView.todaysJob.jobLocation?[1] as? CLLocationDegrees else { return }
            guard let coordindates = CLLocationCoordinate2D(latitude: lat, longitude: lng) as? CLLocationCoordinate2D else {
                print("failed to set job coordinates for monitoring"); return
            }
            UserLocation.instance.startMonitoring(location: coordindates)
            
            UserDefaults.standard.set(HomeView.todaysJob.poNumber, forKey: "todaysJobPO")
            UserDefaults.standard.set(HomeView.todaysJob.jobName, forKey: "todaysJobName")
            UserDefaults.standard.set(HomeView.todaysJob.jobLocation, forKey: "todaysJobLatLong")
            
        } else if let latLong = UserDefaults.standard.array(forKey: "todaysJobLatLong") {
            guard let lat = latLong[0] as? CLLocationDegrees else { return }
            guard let lng = latLong[1] as? CLLocationDegrees else { return }
            guard let coordindates = CLLocationCoordinate2D(latitude: lat, longitude: lng) as? CLLocationCoordinate2D else {
                print("failed to set job coordinates for monitoring"); return
            }
            UserLocation.instance.startMonitoring(location: coordindates)
            
        } else { //No job loc available
            guard let coordinates = UserLocation.instance.currentCoordinate as? CLLocationCoordinate2D else {
                print("job coordinates failed AND user coordinates failed for monitoring"); return
            }
            UserLocation.instance.startMonitoring(location: coordinates)
        }
    }
    
    @objc func checkForUserInfo() {
        
        if HomeView.employeeInfo?.employeeID != nil {
            print("punched in -- \(HomeView.employeeInfo!.punchedIn)")
            checkPunchStatus()
            
        } else {
            if let employeeID = UserDefaults.standard.string(forKey: "employeeID") {
                inProgress()
                
                APICalls().fetchEmployee(employeeId: Int(employeeID)!) { user in
                    HomeView.employeeInfo = user
                    self.checkPunchStatus()
                }
            } else { completedProgress() }
        }
    }
    
    func setFetchedEmployeeUI() {
        self.main.addOperation {
            self.userLabel.textColor = UIColor.white
            self.userLabel.backgroundColor = UIColor.blue
            self.userLabel.text = "Hello \n" + (HomeView.employeeInfo?.userName)!
            HomeView.todaysJob.poNumber = UserDefaults.standard.string(forKey: "todaysJobPO")
            self.completedProgress()
        }
    }
}

extension HomeView {
    
    func failedUpload() {
        OperationQueue.main.addOperation {
            if (UIApplication.shared.applicationState == .active && self.isViewLoaded && (self.view.window != nil)) {
                self.showAlert(withTitle: "Upload Failed", message: "Photo failed to upload.")
                
            } else {
                let failedNotif = self.createNotification(intervalInSeconds: 0, title: "FAILED", message: "Photo(s) failed to upload to server.", identifier: "uploadFail")
                self.notificationCenter.add(failedNotif, withCompletionHandler: { (error) in
                    if error != nil { return }
                })
            }
        }
    }
    
    func checkJobProximity() {
        guard let coordinate = UserLocation.instance.currentCoordinate else { return }
        let jobLocation = jobs[0].jobLocation
        let distance = GeoCoding.getDistance(userLocation: coordinate, jobLocation: jobLocation)
        
        if distance > 1.0 { print("NO <-- User is not in proximity to Job location \n") }
        else { print("YES <-- User is in proximity to Job location \n") }
    }
    
    func inProgress() {
        main.addOperation {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.activityBckgd.isHidden = false
            self.activityIndicator.startAnimating()
        }
    }
    
    func completedProgress() {
        main.addOperation {
            self.activityBckgd.isHidden = true
            self.activityIndicator.hidesWhenStopped = true
            self.activityIndicator.stopAnimating()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func clockedInUI() {
        main.addOperation {
            self.userLabel.backgroundColor = UIColor.green
            self.userLabel.textColor = UIColor.black
            self.userLabel.text = "Clocked In"
            self.completedProgress()
        }
    }
    func clockedOutUI() {
        main.addOperation {
            self.userLabel.backgroundColor = UIColor.red
            self.userLabel.textColor = UIColor.black
            self.userLabel.text = "Clocked Out"
            self.completedProgress()
        }
    }
}

extension HomeView {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let idtn = segue.identifier
        
        if idtn == "schedule" {
            let vc = segue.destination as! ScheduleView
            vc.employee = HomeView.employeeInfo
            
        } else if idtn == "clock_in" {
            let vc = segue.destination as! EmployeeIDEntry
            vc.foundUser = HomeView.employeeInfo
            guard let unwrap = HomeView.role else { return }
            vc.role = unwrap
            
        } else if idtn == "changeOrder" {
            let vc = segue.destination as! ChangeOrdersView
            let jbName = HomeView.todaysJob.jobName
            vc.todaysJob = jbName ?? ""
            vc.formTypeVal = "Change Order"
            
        } else if idtn == "toolRental" {
            let vc = segue.destination as! ChangeOrdersView
            let jbName = HomeView.todaysJob.jobName
            vc.todaysJob = jbName ?? ""
            vc.formTypeVal = "Tool Rental"
            
        } else if idtn == "toolReturn" {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            let vc = segue.destination as! ToolReturnView
            guard let id = HomeView.employeeInfo?.employeeID as? Int else { return }
            vc.employeeID = id
            
        } else if idtn == "map" {
            let vc = segue.destination as! StoresMapView
            let jbName = HomeView.todaysJob.jobName
            vc.todaysJob = jbName ?? ""
        }
    }
    
    func incorrectID() {
        showAlert(withTitle: "Error", message: "Unable to find that user")
    }
    
    public func checkPunchStatus() {
        if HomeView.employeeInfo?.userName != nil {
            UserDefaults.standard.set(HomeView.employeeInfo?.userName, forKey: "employeeName")
            
            if HomeView.employeeInfo?.punchedIn == true {
                UserLocation.instance.locationManager.startUpdatingLocation()
                
                setMonitoringForJobLoc()
                clockedInUI()
                
            } else if HomeView.employeeInfo?.punchedIn == false {
                UserLocation.instance.stopMonitoring()
                clockedOutUI()
                
            } else { main.addOperation(setFetchedEmployeeUI) }
        } else { completedProgress(); return }
    }
    
    func setUpNotifications() {
        let stopAction = UNNotificationAction(identifier: "STOP_ACTION", title: "Stop", options: [.destructive, .foreground])
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let alarmCategory = UNNotificationCategory(identifier: "alarm.category", actions: [stopAction], intentIdentifiers: [], options: [])
        notificationCenter.setNotificationCategories([alarmCategory])
        notificationCenter.requestAuthorization(options: options) { (granted, error) in
            if !granted { print("there was an error or the user did not authorize alerts: ", error) }
        }
        notificationCenter.getNotificationSettings { (settings) in if settings.authorizationStatus != .authorized { print("user did not authorize alerts") } }
    }
    
    func checkSuccess(success: Bool) {
        if success == true { completedProgress() }
        else { failedUpload() }
    }
    
    func showRentOrReturnWin() {
        
        let alert = UIAlertController(title: "Rent or Return", message: "Are you renting or returning a tool?", preferredStyle: .alert)
        let rental = UIAlertAction(title: "Rental", style: .default) { action in    self.performSegue(withIdentifier: "toolRental", sender: nil) }
        let returnTool = UIAlertAction(title: "Return", style: .destructive) { action in    self.performSegue(withIdentifier: "toolReturn", sender: nil) }
        
        alert.addAction(rental)
        alert.addAction(returnTool)
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension HomeView: ImagePickerDelegate {
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        print("wrapper did press")
        imagePicker.expandGalleryView()
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        print("images to upload: \(imageAssets.count)")
        
        if imageAssets.count < 11 {
            if let po = UserDefaults.standard.string(forKey: "todaysJobPO"),
                let emply =  UserDefaults.standard.string(forKey: "employeeName") {
                inProgress()
                APICalls().uploadJobImages(images: imageAssets, jobNumber: po, employee: emply) { success in
                    self.checkSuccess(success: success)
                }
            } else {
                inProgress()
                APICalls().uploadJobImages(images: imageAssets, jobNumber: "---", employee: "---") { success in
                    self.checkSuccess(success: success)
                }
            }
            
            dismiss(animated: true, completion: nil)
        } else {
            picker.showAlert(withTitle: "Max Photos", message: "You can only upload a maximum of 10 photos each time.")
        }
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
    }
}

extension Notification.Name {
    static let info = Notification.Name("employeeInfo")
}


