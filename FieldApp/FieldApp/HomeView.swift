//
//  HomeView.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/26/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.

import Foundation
import UIKit
import CoreLocation
import UserNotifications
import UserNotificationsUI
import Firebase
import FirebaseAuth
import ImagePicker
import Macaw
//import FanMenu
//import SwiftyJSON


class HomeBkgd: MacawView {
    required init?(coder aDecoder: NSCoder) {
        let h = UIScreen.main.bounds.height,
            w = UIScreen.main.bounds.width,
            node = Group(),
            shp = Shape(
                form: Rect(x: 0.0, y: 0.0, w: Double(w), h: Double(h / 2)),
                fill: LinearGradient(degree: 90, from: Color.black, to: Color.white),
                stroke: Stroke(fill: Color.clear, width: 0.0)
            ),
            shpTwo = Shape(
                form: Rect(x: 0.0, y: Double(h / 2), w: Double(w), h: Double(h / 2)),
                fill: LinearGradient(degree: 90, from: Color.white, to: Color.black),
                stroke: Stroke(fill: Color.clear, width: 0.0)
            )
        
        node.contents.append(shp)
        node.contents.append(shpTwo)
        super.init(node: node, coder: aDecoder)
    }
}

class HomeView: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet var userLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var activityBckgd: UIView!
    @IBOutlet var profileBtn: UIButton!
    @IBOutlet var bkgdView: HomeBkgd!
    @IBOutlet var homeFanMenu: UIView!
    //    @IBOutlet var logoView: HomeFan!

    let notificationCenter = UNUserNotificationCenter.current()
    let picker = ImagePickerController()
    let firebaseAuth =  Auth.auth()
    let colors: [Color] = [
        Color.green, Color.blue, Color.teal, Color.red, Color.fuchsia,
        Color.navy, Color.purple, Color.yellow, Color(val: 0xFF9742)
    ]
    let icons = [
        "hotel_req", "tools", "materials", "form", "vacation",
        "safety", "camera", "clock", "schedule"
    ]

    var firAuthId = UserDefaults.standard.string(forKey: "authVerificationID")
    var main = OperationQueue.main
    var jobs: [Job.UserJob] = []
    var profileUpload: Bool?
    var questsAlerts: [UIAlertController] = []
    var menuOpen = false
    public static var vehicleCkListNotif: Bool?
    public static var scheduleReadyNotif: Bool?
    public static var employeeInfo: UserData.UserInfo?
    public static var addressInfo: UserData.AddressInfo?
    public static var todaysJob = Job()
    public static var role: String?
    public static var safetyQs: [SafetyQuestion] = []
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
//        logoView.close()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        checkForSafetyQs()
//        logoView.close()
    }

    @IBAction func pressdProfBtn(_ sender: Any) {
        profilePress()
    }

}


extension HomeView {
    
    func checkForSafetyQs() {
        if HomeView.safetyQs.count > 0 {

            for (index, value) in HomeView.safetyQs.enumerated() {
                let questionPopup = UIAlertController(title: "Safety Question", message: value.question, preferredStyle: UIAlertController.Style.alert)

                let a = UIAlertAction(title: value.options.a, style: UIAlertAction.Style.default) { action in
                    questionPopup.dismiss(animated: true, completion: nil)
                    self.handleSafetyQuesAnswer(selected: "a", answer: value.answer, options: value.options, i: (index + 1) )
                };
                let b = UIAlertAction(title: value.options.b, style: UIAlertAction.Style.default) { action in
                    questionPopup.dismiss(animated: true, completion: nil)
                    self.handleSafetyQuesAnswer(selected: "b", answer: value.answer, options: value.options, i: (index + 1))
                };
                let c = UIAlertAction(title: value.options.c, style: UIAlertAction.Style.default) { action in
                    questionPopup.dismiss(animated: true, completion: nil)
                    self.handleSafetyQuesAnswer(selected: "c", answer: value.answer, options: value.options, i: (index + 1))
                };
                let d = UIAlertAction(title: value.options.d, style: UIAlertAction.Style.default) { action in
                    questionPopup.dismiss(animated: true, completion: nil)
                    self.handleSafetyQuesAnswer(selected: "d", answer: value.answer, options: value.options, i: (index + 1))
                };

                questionPopup.addAction(a)
                questionPopup.addAction(b)
                questionPopup.addAction(c)
                questionPopup.addAction(d)

                questsAlerts.append(questionPopup)
            }

            main.addOperation {
                self.present(self.questsAlerts[0], animated: true, completion: nil)
            }
        }
    }

    func handleSafetyQuesAnswer(selected: String, answer: String, options: SafetyQuestion.answerOptions, i: Int) {

        func makeAlert(correct: String, msg: String) {
            let alert = UIAlertController(title: correct, message: msg, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .cancel) { action in
                if i >= self.questsAlerts.count {
                    HomeView.safetyQs = []
                    return
                } else if self.questsAlerts[i] != nil {
                    self.present(self.questsAlerts[i], animated: true, completion: nil)
                }
            }

            alert.addAction(action)
            main.addOperation { self.present(alert, animated: true, completion: nil) }
        }

        var fullAnswer = ""

        switch answer {
        case "a":
            fullAnswer = options.a;
        case "b":
            fullAnswer = options.b;
        case "c":
            fullAnswer = options.c;
        case "d":
            fullAnswer = options.d;

        default: return;
        }

        if selected == answer {
            makeAlert(correct: "Correct", msg: "Answer: \(answer) \(fullAnswer)")
            // add pts here
            guard let user = HomeView.employeeInfo?.userName else { return }
            APICalls().addPoints(employee: user, pts: 2)
        } else {
            makeAlert(correct: "Incorrect", msg: "Answer: \(answer) \(fullAnswer)")
        }
    }


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
                NSAttributedString.Key.paragraphStyle : paraStyle,
                NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .body),
                NSAttributedString.Key.foregroundColor: UIColor.black
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
        let w = UIScreen.main.bounds.width,
        h = UIScreen.main.bounds.height,
        btnRadius = 35.0,
        menuRadius = Double(4 * btnRadius),
        dbPi = 2 * Double.pi,
        rect = CGRect(
            x: (0), y: (0), width: (w), height: (h)
        )
        let menuView = FanMenu(frame: rect)

        menuView.menuBackground = Color.clear
        menuView.menuRadius = menuRadius
        menuView.radius = btnRadius
        menuView.interval = (0, dbPi)
        menuView.duration = 0.1
        menuView.button = FanMenuButton(
            id: "main", image: "MB_logo", color: Color.clear
        )
        menuView.items = colors.enumerated().map { (index, item) in
            FanMenuButton(
                id: String(index), image: String(icons[index]), color: item
            )
        }
        menuView.onItemWillClick = { button in
            print("button: ", button.id, button.image)
            self.hideShowProfile()

            if button.id != "main" { self.chooseSegue(image: button.image) }
        }
        
        homeFanMenu.addSubview(menuView)
    }

    func hideShowProfile() {
        
        if menuOpen == true {
            menuOpen = false
            profileBtn.isHidden = true
            userLabel.isHidden = true
        } else {
            menuOpen = true
            profileBtn.isHidden = false
            userLabel.isHidden = false
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
                for singleNote in notifications { print("request in notif center: ", singleNote.request) }
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
            guard let lat = HomeView.todaysJob.jobLocation?[0],
                let lng = HomeView.todaysJob.jobLocation?[1] else {
                    print("failed to set job coordinates for monitoring"); return
            }
            let coordindates = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            UserLocation.instance.startMonitoring(location: coordindates)

            UserDefaults.standard.set(HomeView.todaysJob.poNumber, forKey: "todaysJobPO")
            UserDefaults.standard.set(HomeView.todaysJob.jobName, forKey: "todaysJobName")
            UserDefaults.standard.set(HomeView.todaysJob.jobLocation, forKey: "todaysJobLatLong")

        } else if let latLong = UserDefaults.standard.array(forKey: "todaysJobLatLong") {
            guard let lat = latLong[0] as? CLLocationDegrees,
                let lng = latLong[1] as? CLLocationDegrees else {
                print("failed to set job coordinates for monitoring"); return
            }
            let coordindates = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            UserLocation.instance.startMonitoring(location: coordindates)

        } else { //No job loc available
            guard let coordinates = UserLocation.instance.currentCoordinate else {
                print("job coordinates failed AND user coordinates failed for monitoring"); return
            }
            UserLocation.instance.startMonitoring(location: coordinates)
        }
    }

    @objc func checkForUserInfo() {

        if HomeView.employeeInfo?.employeeID != nil {
            print("punched in -- \(String(describing: HomeView.employeeInfo!.punchedIn))")
            checkPunchStatus()

        } else {
            if let employeeID = UserDefaults.standard.string(forKey: "employeeID") {
                self.inProgress(activityBckgd: activityBckgd, activityIndicator: activityIndicator)

                fetchEmployee(employeeId: Int(employeeID)!) { user, addressInfo in
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

    func fetchEmployee(employeeId: Int, callback: @escaping (UserData.UserInfo, UserData.AddressInfo) -> ()){
        let route = "employee/" + String(employeeId)

        APICalls().setupRequest(route: route, method: "GET") { request in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in

                if error != nil { print(error as Any); return }
                else {
                    guard let verifiedData = data else {
                        print("couldn't verify data from server"); return
                    }
                    guard let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary else {
                        print("json serialization failed"); return
                    }
                    guard let user = UserData.UserInfo.fromJSON(dictionary: json),
                        let dictionary = json["addressInfo"] as? NSDictionary,
                        let addressInfo = UserData.AddressInfo.fromJSON(dictionary: dictionary) else {
                            print("failed to parse UserData from json\(json)");
                            self.completedProgress()

                            guard let resMsg = json as? [String:String] else { return }
                            self.handleResponseType(responseType: resMsg)
                            return
                    }
                    callback(user, addressInfo)
                }
            }; task.resume()
        }
    }

    func failedUpload(error: String) {
        let msg = "Photo(s) failed to upload to server with error: \n\(error)"

        main.addOperation {
            if (UIApplication.shared.applicationState == .active && self.isViewLoaded && (self.view.window != nil)) {
                self.showAlert(withTitle: "Upload Failed", message: msg)
            } else {
                APICalls.succeedOrFailUpload(msg: msg, uploadType: "photoUpload", success: false)
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

    func completedProgress() {
        completeProgress(activityBckgd: activityBckgd, activityIndicator: activityIndicator)

        if HomeView.vehicleCkListNotif == true { self.performSegue(withIdentifier: "vehicleCkList", sender: nil) }
        else if HomeView.scheduleReadyNotif == true {
            self.performSegue(withIdentifier: "schedule", sender: nil)
        }
    }

    func clockedInUI() {
        guard let info = HomeView.employeeInfo else { return }
        main.addOperation {
            self.userLabel.text = "\(info.userName) \nID#: \(info.employeeID) \nClocked IN"
            self.completedProgress()
        }
    }
    func clockedOutUI() {
        guard let info = HomeView.employeeInfo else { return }
        main.addOperation {
            self.userLabel.text = "\(info.userName) \nID#: \(info.employeeID) \nClocked OUT"
            self.completedProgress()
        }
    }
}

extension HomeView {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        logoView.close()

        switch segue.identifier {
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
            guard let id = HomeView.employeeInfo?.employeeID else { return }
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
            if !granted { print("there was an error or the user did not authorize alerts: ", error ?? "notificationCenter: err") }
        }
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized { print("user did not authorize alerts") }
        }
    }

    func checkSuccess(responseType: [String: String]) {
        if responseType["success"] == "true" { completedProgress() }
        else if let msg = responseType["msg"] { showAlert(withTitle: "Error", message: msg) }
        else if let error = responseType["error"] { failedUpload(error: error) }
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
        guard let imageData = image.jpegData(compressionQuality: 1) else { return }

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
                let image = UIImage(data: imageData, scale: UIScreen.main.scale) else {
                    print("Couldnt convert url to data obj"); return
            }

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
                self.inProgress(activityBckgd: self.activityBckgd, activityIndicator: self.activityIndicator)
                guard let emply = HomeView.employeeInfo?.userName,
                    let idNum = UserDefaults.standard.string(forKey: "employeeID") else { return }
                let route = "employee/\(idNum)/profileUpload"
                let headers = ["employee", emply]
                let info = UserData.AddressInfo(address: "121 main st", city: "Cerritos", state: "CA")
                let formBody = APICalls().generateAddressData(addressInfo: info)

                APICalls().alamoUpload(route: route, headers: headers, formBody: formBody, images: images, uploadType: "profilePhoto") { responseType in
                    self.saveLocalPhoto(image: images[0])
                    self.loadProfilePic()
                    self.checkSuccess(responseType: responseType)
//                    HomeView.hideShowProfile()
                    self.profileUpload = nil
                }
            }
        } else if imageAssets.count < 11 {
            picker.dismiss(animated: true) {
                self.inProgress(activityBckgd: self.activityBckgd, activityIndicator: self.activityIndicator)


                if let po = UserDefaults.standard.string(forKey: "todaysJobPO"),
                    let emply =  UserDefaults.standard.string(forKey: "employeeName") {
                    APICalls().uploadJobImages(images: self.imageAssets, jobNumber: po, employee: emply) { responseType in
                        self.checkSuccess(responseType: responseType)
                    }
                } else {
                    APICalls().uploadJobImages(images: self.imageAssets, jobNumber: "---", employee: "---") { responseType in
                        self.checkSuccess(responseType: responseType)
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


