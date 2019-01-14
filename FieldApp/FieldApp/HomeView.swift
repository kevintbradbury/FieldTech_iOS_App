//
//  HomeView.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/26/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import CoreLocation
import UserNotifications
import UserNotificationsUI
import ImagePicker
import Macaw
import FanMenu
//import Alamofire
//import FirebaseStorage
//import SwiftyJSON

class HomeView: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityBckgd: UIView!
    @IBOutlet var logoView: FanMenu!
    @IBOutlet var bkgdView: MacawView!
    @IBOutlet var profileBtn: UIButton!
    
    let notificationCenter = UNUserNotificationCenter.current()
    let picker = ImagePickerController()
    let firebaseAuth =  Auth.auth()
    let colors: [Int] = [
        Color.green.val, Color.blue.val, Color.teal.val, Color.red.val,Color.fuchsia.val,
        Color.navy.val, Color.purple.val, Color.yellow.val, 0xFF9742
    ]
    let icons = [
        "hotel_req", "tools", "materials", "form", "vacation",
        "safety", "camera", "clock", "schedule"
    ]
    
    var firAuthId = UserDefaults.standard.string(forKey: "authVerificationID")
    var main = OperationQueue.main
    var jobs: [Job.UserJob] = []
    var profileUpload: Bool?
    var vehicleCkListNotif: Bool?
    var scheduleReadyNotif: Bool?
    public static var employeeInfo: UserData.UserInfo?
    public static var addressInfo: UserData.AddressInfo?
    public static var todaysJob = Job()
    public static var role: String?
    public var imageAssets: [UIImage] {
        return AssetManager.resolveAssets(picker.stack.assets)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Auth.auth().addStateDidChangeListener() { (auth, user) in
            if user == nil { self.dismiss(animated: true) }
        }
        UserLocation.instance.initialize()
        setUpNotifications()
        checkAppDelANDnotif()
        setUpHomeBtn()
        loadProfilePic()
        
        picker.delegate = self
        activityIndicator.isHidden = true
        activityIndicator.hidesWhenStopped = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        checkForUserInfo()
        logoView.close()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        logoView.close()
    }
    
    @IBAction func pressedProfile(_ sender: Any) {
        profilePress()
    }
    
}

extension HomeView {
    
    func profilePress() {
        profileUpload = true
        
        if HomeView.employeeInfo != nil && HomeView.addressInfo != nil {
            guard let name = HomeView.employeeInfo?.userName,
                let address = HomeView.addressInfo?.address,
                let city = HomeView.addressInfo?.city,
                let state = HomeView.addressInfo?.state else { return }
            let msg = "\n\(name)\n\(address)\n\(city), \(state) \n \nWould you like to add/update your profile photo? "
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.alignment = NSTextAlignment.left
            let messageText = NSMutableAttributedString(string: msg, attributes: [
                NSAttributedStringKey.paragraphStyle : paraStyle,
                NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: .body),
                NSAttributedStringKey.foregroundColor: UIColor.black
                ])
            // Include phone number in future
            
            let alert = UIAlertController(title: "Employee Info", message: msg, preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let confirm = UIAlertAction(title: "Yes", style: .default) { action in
                self.present(self.picker, animated: true, completion: nil)
            }
            
            alert.setValue(messageText, forKey: "attributedMessage")
            alert.addAction(confirm)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func setUpHomeBtn() {
        let btnRadius = 35.0
        logoView.menuRadius = Double(4 * btnRadius)     //  100.0
        logoView.duration = 0.1
        logoView.interval = (0, 2 * Double.pi)
        logoView.radius = btnRadius
        logoView.menuBackground = Color.clear
        
        logoView.button = FanMenuButton(
            id: "main", image: "MB_logo", color: Color.white
        )
        
        logoView.items = colors.enumerated().map { (index, item) in
            FanMenuButton(
                id: String(index),
                image: String(icons[index]),
                color: Color(val: item)
            )
        }
        
        logoView.onItemWillClick = { button in
            print("button: ", button.id, button.image)
            self.hideShowProfile()
            
            if button.id != "main" { self.chooseSegue(image: button.image) }
        }
        
        let node = Group()
        let shp = Shape(
            form: Rect(
                x: 0.0, y: 0.0,
                w: Double(self.view.frame.width), h: Double(self.view.frame.height / 2)
            ),
            fill: LinearGradient(degree: 90, from: Color.black, to: Color.white),
            stroke: Stroke(fill: Color.clear, width: 0.0)
        )
        node.contents.append(shp)
        
        let shpTwo = Shape(
            form: Rect(
                x: 0.0, y: Double(self.view.frame.height / 2),
                w: Double(self.view.frame.width), h: Double(self.view.frame.height / 2)
            ),
            fill: LinearGradient(degree: 90, from: Color.white, to: Color.black),
            stroke: Stroke(fill: Color.clear, width: 0.0)
        )
        
        node.contents.append(shpTwo)
        bkgdView.node = node
    }
    
    func hideShowProfile() {
        if self.logoView.isOpen {
            self.profileBtn.isHidden = true
            self.userLabel.isHidden = true
        } else {
            self.profileBtn.isHidden = false
            self.userLabel.isHidden = false
        }
    }
    
    func chooseSegue(image: String) {
        switch image {
        case "clock":
            performSegue(withIdentifier: "clock_in", sender: nil)
        case "schedule":
            performSegue(withIdentifier: "schedule", sender: nil)
        case "materials":
            showSRFormOrMap()
        case "form":
            performSegue(withIdentifier: "changeOrder", sender: nil)
        case "vacation":
            performSegue(withIdentifier: "timeOff", sender: nil)
        case "tools":
            showRentOrReturnWin()
        case "camera":
            present(picker, animated: true, completion: nil)
            picker.showAlert(
                withTitle: "Reminder",
                message: "Make sure to clear area of tools, cables, debris, or other materials, before taking a photo. "
            )
            //        case "time_off":
            //        case "safety":
            //        case "hotel_req":
            
        default:
            showAlert(
                withTitle: "Under Contruction", message: "Sorry this part is still under construction."
            )
        }
    }
    
    func checkAppDelANDnotif() {
        let appDelegate: AppDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.myViewController = self
        
        if appDelegate.didEnterBackground == true {
            notificationCenter.getDeliveredNotifications() { notifications in
                if notifications != nil {
                    for singleNote in notifications { print("request in notif center: ", singleNote.request) }
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(checkForUserInfo), name: .info, object: nil
        )
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
            
        } else if HomeView.todaysJob.jobName != nil && HomeView.todaysJob.jobLocation?.count == 2 {
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
                
                APICalls().fetchEmployee(employeeId: Int(employeeID)!) { user, addressInfo in
                    HomeView.employeeInfo = user
                    HomeView.addressInfo = addressInfo
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
        let msg = "Photo(s) failed to upload to server."
        
        main.addOperation {
            if (UIApplication.shared.applicationState == .active && self.isViewLoaded && (self.view.window != nil)) {
                self.showAlert(withTitle: "Upload Failed", message: msg)
            } else {
                APICalls.failedUpload(msg: msg)
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
            self.userLabel.text = "Clocked In"
            self.completedProgress()
        }
    }
    func clockedOutUI() {
        main.addOperation {
            self.userLabel.text = "Clocked Out"
            self.completedProgress()
        }
    }
}

extension HomeView {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        logoView.close()
        let idtn = segue.identifier
        
        switch idtn {
        case "schedule":
            let vc = segue.destination as! ScheduleView
            vc.employee = HomeView.employeeInfo
        case "clock_in":
            let vc = segue.destination as! EmployeeIDEntry
            vc.foundUser = HomeView.employeeInfo
            guard let unwrap = HomeView.role else { return }
            vc.role = unwrap
        case "changeOrder":
            let vc = segue.destination as! ChangeOrdersView
            let jbName = HomeView.todaysJob.jobName
            vc.todaysJob = jbName ?? ""
            vc.formTypeVal = "Change Order"
        case "suppliesReq":
            let vc = segue.destination as! SuppliesRequestView
            vc.todaysJob = HomeView.todaysJob
            vc.employeeInfo = HomeView.employeeInfo
        case "toolRental":
            let vc = segue.destination as! ChangeOrdersView
            let jbName = HomeView.todaysJob.jobName
            vc.todaysJob = jbName ?? ""
            vc.formTypeVal = "Tool Rental"
        case "toolReturn":
            let vc = segue.destination as! ToolReturnView
            guard let id = HomeView.employeeInfo?.employeeID as? Int else { return }
            vc.employeeID = id
        case "map":
            let vc = segue.destination as! StoresMapView
            let jbName = HomeView.todaysJob.jobName
            vc.todaysJob = jbName ?? ""
        case "timeOff":
            let vc = segue.destination as! TimeOffRequestView
            guard let emplyInformation = HomeView.employeeInfo else { return }
            vc.employeeInfo = emplyInformation
            
        default:
            showAlert(withTitle: "Sorry", message: "That's not a shortcut we recognize.")
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
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized { print("user did not authorize alerts") }
        }
        
        if vehicleCkListNotif == true { performSegue(withIdentifier: "vehicleCkList", sender: nil) }
        else if scheduleReadyNotif == true { performSegue(withIdentifier: "schedule", sender: nil) }
    }
    
    func checkSuccess(success: Bool) {
        if success == true { completedProgress() }
        else { failedUpload() }
    }
    
    func showRentOrReturnWin() {
        
        let alert = UIAlertController(title: "Rent or Return", message: "Are you renting or returning a tool?", preferredStyle: .alert)
        let rental = UIAlertAction(title: "Rental", style: .default) { action in
            self.performSegue(withIdentifier: "toolRental", sender: nil)
        }
        let returnTool = UIAlertAction(title: "Return", style: .default) { action in
            self.performSegue(withIdentifier: "toolReturn", sender: nil)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(rental)
        alert.addAction(returnTool)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveLocalPhoto(image: UIImage) {
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/profilePic.jpg"
        let imageUrl: URL = URL(fileURLWithPath: imagePath)
        guard let imageData = UIImageJPEGRepresentation(image, 1) else { return }
        
        do {
            try imageData.write(to: imageUrl)
            print("saved photo @ URL: \(imageUrl)")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func loadProfilePic() {
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/profilePic.jpg"
        let imageUrl: URL = URL(fileURLWithPath: imagePath)
        
        if FileManager.default.fileExists(atPath: imagePath) {
            guard let imageData = try? Data(contentsOf: imageUrl),
                var image = UIImage(data: imageData, scale: UIScreen.main.scale) else {
                    print("Couldnt convert url to data obj"); return
            }
            
            //            profileBtn.contentMode = .scaleAspectFit
            profileBtn.layer.cornerRadius = 15  //  27.5
            profileBtn.layer.borderWidth = 1
            profileBtn.layer.borderColor = UIColor.white.cgColor
            profileBtn.setImage(image, for: .normal)
            
        } else {
            print("File not found: \(imagePath)"); return
        }
    }
    
    func showSRFormOrMap() {
        let alert = UIAlertController(title: "Field Supplies", message: "Where to get your supplies?", preferredStyle: .alert)
        let shopReq = UIAlertAction(title: "Request from Shop", style: .default) { action in
            self.performSegue(withIdentifier: "suppliesReq", sender: nil)
        }
        let goToMap = UIAlertAction(title: "Pick up from Store", style: .default) { action in
            self.performSegue(withIdentifier: "map", sender: nil)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(shopReq)
        alert.addAction(goToMap)
        alert.addAction(cancel)
        
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
        
        if profileUpload == true && imageAssets.count == 1 {
            
            picker.dismiss(animated: true) {
                self.inProgress()
                guard let emply = HomeView.employeeInfo?.userName,
                    let idNum = UserDefaults.standard.string(forKey: "employeeID") as? String else { return }
                let route = "employee/\(idNum)/profileUpload"
                let headers = ["employee", emply]
                let info = UserData.AddressInfo(address: "121 main st", city: "Cerritos", state: "CA")
                let formBody = APICalls().generateAddressData(addressInfo: info)
                
                APICalls().alamoUpload(route: route, headers: headers, formBody: formBody, images: images, uploadType: "profilePhoto") { success in
                    self.saveLocalPhoto(image: images[0])
                    self.loadProfilePic()
                    self.hideShowProfile()
                    self.checkSuccess(success: success)
                }
                
            }
        } else if profileUpload != true && imageAssets.count < 11 {
            picker.dismiss(animated: true) {
                self.inProgress()
                
                if let po = UserDefaults.standard.string(forKey: "todaysJobPO"),
                    let emply =  UserDefaults.standard.string(forKey: "employeeName") {
                    APICalls().uploadJobImages(images: self.imageAssets, jobNumber: po, employee: emply) { success in
                        self.checkSuccess(success: success)
                    }
                } else {
                    APICalls().uploadJobImages(images: self.imageAssets, jobNumber: "---", employee: "---") { success in
                        self.checkSuccess(success: success)
                    }
                }
            }
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


