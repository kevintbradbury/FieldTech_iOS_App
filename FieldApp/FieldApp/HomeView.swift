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
import CoreLocation
import UserNotifications
import UserNotificationsUI
import ImagePicker
import Alamofire
//import FirebaseStorage
//import SwiftyJSON

class HomeView: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var photoToUpload: UIImageView!
    @IBOutlet weak var choosePhotoButton: UIButton!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var labelBkgd: UIView!
    @IBOutlet weak var clockInOut: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityBckgd: UIView!
    @IBOutlet weak var calendarButton: UIButton!
    
    let notificationCenter = UNUserNotificationCenter.current()
    let picker = ImagePickerController() // UIImagePickerController()
    let firebaseAuth = Auth.auth()
    
    var firAuthId = UserDefaults.standard.string(forKey: "authVerificationID")
    static var employeeInfo: UserData.UserInfo?
    var main = OperationQueue.main
    var jobs: [Job.UserJob] = []
    var todaysJob = Job()
    public var imageAssets: [UIImage] {
        return AssetManager.resolveAssets(picker.stack.assets)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
        activityIndicator.hidesWhenStopped = true
        
        picker.delegate = self
        
        Auth.auth().addStateDidChangeListener() { (auth, user) in
            if user == nil { self.dismiss(animated: true) }
        }
        setUpNotifications()
        checkAppDelANDnotif()
        NotificationCenter.default.addObserver(self, selector: #selector(checkForUserInfo), name: .info, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        checkForUserInfo()
    }
    
    @IBAction func logoutPressed(_ sender: Any) { logOut() }
    @IBAction func chooseUploadMethod(_ sender: Any) { present(picker, animated: true, completion: nil) } //showUploadMethods()
    @IBAction func goClockInOut(_ sender: Any) { performSegue(withIdentifier: "clock_in", sender: self) }
    @IBAction func goToSchedule(_ sender: Any) { performSegue(withIdentifier: "schedule", sender: self) }
    
}

extension HomeView: ImagePickerDelegate {
    
    func checkAppDelANDnotif() {
        let appDelegate: AppDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.myViewController = self
        
        // Do something to handle notifications
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
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        print("wrapper did press")
        imagePicker.expandGalleryView()
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        let images = imageAssets
        print("images to upload: \(images.count)")
        
        if images.count < 11 {
            
            if let po = todaysJob.poNumber,
                let emply = HomeView.employeeInfo?.userName {
                upload(images: images, jobNumber: po, employee: emply)
            }
            else {
                upload(images: images, jobNumber: "---", employee: "---")
            }
            
            dismiss(animated: true, completion: nil)
        } else {
            picker.showAlert(withTitle: "Max Photos", message: "You can only upload a maximum of 10 photos each time.")
        }
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
    }

    func setMonitoringForJobLoc() {
        if todaysJob.jobName != nil && todaysJob.jobLocation?[0] != nil && todaysJob.jobLocation?[1] != nil && todaysJob.jobLocation?.count == 2 {
            guard let lat = todaysJob.jobLocation?[0] as? CLLocationDegrees else { return }
            guard let lng = todaysJob.jobLocation?[1] as? CLLocationDegrees else { return }
            guard let coordindates = CLLocationCoordinate2D(latitude: lat, longitude: lng) as? CLLocationCoordinate2D else {
                print("failed to set job coordinates for monitoring"); return
            }
            UserLocation.instance.startMonitoring(location: coordindates)
            
            UserDefaults.standard.set(todaysJob.poNumber, forKey: "todaysJobPO")
            UserDefaults.standard.set(todaysJob.jobLocation, forKey: "todaysJobLatLong")
            
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
    
    func checkForUserInfo() {
        
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
            self.todaysJob.poNumber = UserDefaults.standard.string(forKey: "todaysJobPO")
            self.completedProgress()
        }
    }
    
    func showUploadMethods() {
        
        let actionsheet = UIAlertController(title: "Choose Upload method", message: "You can upload by Camera or from your Photos", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let choosePhotos = UIAlertAction(title: "Photos", style: UIAlertActionStyle.default) { (action) -> Void in
            self.present(self.picker, animated: true, completion: nil)
        }
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive) { (action) -> Void in
            print("chose Cancel")
        }
        actionsheet.addAction(choosePhotos)
        actionsheet.addAction(cancel)
        
        self.present(actionsheet, animated: true)
    }
    
    func uploadPhoto(photo: UIImage, poNumber: String){
        self.main.addOperation { self.inProgress() }
        guard let imageData = UIImageJPEGRepresentation(photo, 0.25) else {
        print("Couldn't get JPEG representation"); return
    }
        
        APICalls().sendPhoto(imageData: imageData, poNumber: poNumber) { responseObj in
            self.main.addOperation {
                self.completedProgress()
            }
        }
    }
    
    func upload(images: [UIImage], jobNumber: String, employee: String) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.inProgress()
        
        let url = "https://mb-server-app-kbradbury.c9users.io/job/" + jobNumber + "/upload"
        let headers: HTTPHeaders = [
            "Content-type" : "multipart/form-data",
            "employee": employee
        ]
        
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                var i = 0
                for img in images {
                    
                    guard let imageData = UIImageJPEGRepresentation(img, 0.25) else { return }
                    multipartFormData.append(imageData,
                                             withName: "\(jobNumber)_\(i)",
                        fileName: "\(jobNumber)_\(i).jpg",
                        mimeType: "image/jpeg")
                    i += 1
                }
        },
            usingThreshold: UInt64.init(),
            to: url,
            method: .post,
            headers: headers,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                    
                case .success(let upload, _, _):
                    upload.uploadProgress { progress in
                        //progressCompletion(Float(progress.fractionCompleted))
                    }
                    upload.validate()
                    upload.responseString { response in
                        guard response.result.isSuccess else {
                            print("error while uploading file: \(response.result.error)")
                            self.failedUpload()
                            return
                        }
                        //
                        self.completedProgress()
                        let completeNotif = self.createNotification(intervalInSeconds: 1, title: "Upload Complete", message: "Photos uploaded successfully.", identifier: "uploadSuccess")
                        
                        self.notificationCenter.add(completeNotif, withCompletionHandler: { (error) in
                            if error != nil { return } else {}
                        })
                    }
                    
                case .failure(let encodingError):
                    print(encodingError)
                }
        }
        )
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
 
}

extension HomeView {
    func failedUpload() {
        let actionsheet = UIAlertController(title: "Upload Failed", message: "Photo failed to upload.", preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) {(action) in
            actionsheet.dismiss(animated: true, completion: nil)
        }
        actionsheet.addAction(ok)
        self.present(actionsheet, animated: true)
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
        if segue.identifier == "schedule" {
            let vc = segue.destination as! ScheduleView
            vc.employee = HomeView.employeeInfo
        } else if segue.identifier == "clock_in" {
            let vc = segue.destination as! EmployeeIDEntry
            vc.foundUser = HomeView.employeeInfo
        }
    }
    
    func incorrectID() {
        let actionsheet = UIAlertController(title: "Error", message: "Unable to find that user", preferredStyle: UIAlertControllerStyle.alert)
        
        let ok = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) {(action) in
            actionsheet.dismiss(animated: true, completion: nil)
        }
        actionsheet.addAction(ok)
        self.present(actionsheet, animated: true, completion: nil)
    }
    
    func checkPunchStatus() {
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
}

extension UIViewController {
    func showAlert(withTitle title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        
        let main = OperationQueue.main
        main.addOperation { self.present(alert, animated: true, completion: nil) }
    }
}

extension Notification.Name {
    static let info = Notification.Name("employeeInfo")
}

