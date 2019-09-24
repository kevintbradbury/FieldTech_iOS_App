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
import EPSignature


class HomeView: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet var userLabel: UILabel!
    @IBOutlet var profileBtn: UIButton!
    @IBOutlet var bkgdView: HomeBkgd!
    @IBOutlet var homeFanMenu: UIView!
    @IBOutlet var jobCheckUpView: UIView!
    @IBOutlet var returnTomorrowSwitch: UISwitch!
    @IBOutlet var workersToReturnLbl: UILabel!
    @IBOutlet var workersStepper: UIStepper!
    @IBOutlet var requiredAddedMaterialsSwitch: UISwitch!
    @IBOutlet var incorrectAnswerVw: UIView!
    @IBOutlet var incrtAnswerLabel: UILabel!
    @IBOutlet var incrtOKbtn: UIButton!
    @IBOutlet var correctAnswerVw: UIView!
    @IBOutlet var crtAnswerLabel: UILabel!
    @IBOutlet var crtOKbtn: UIButton!
    //    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    //    @IBOutlet var activityBckgd: UIView!
    
    let notificationCenter = UNUserNotificationCenter.current()
    let picker = ImagePickerController()
    let firebaseAuth =  Auth.auth()
    let colors: [Color] = [
        Color.green, Color.blue, Color.teal, Color.red, Color.fuchsia,
        Color.purple, Color.yellow, Color(val: 0xFF9742)
    ]
    let icons = [
        "time_off", "tools", "materials", "form", "vacation",
        "camera", "clock_blue", "schedule"
    ]

    var employeesToReturn = 0
    var firAuthId = UserDefaults.standard.string(forKey: "authVerificationID")
    var jobs: [Job.UserJob] = []
    var main = OperationQueue.main
    var menuOpen = false
    var mealWaiverSIgnature: UIImage?
    var profileUpload: Bool?
    var questionAlerts: [UIAlertController] = []
    var indexVal = 0
    var correctAnswerVal = true
    var incorrectAnswer = -1
    
    public static var addressInfo: UserData.AddressInfo?,
    employeeInfo: UserData.UserInfo?,
    jobCheckup: Bool?,
    leftJobSite: Bool?,
    role: String?,
    safetyQs: [SafetyQuestion] = [],
    scheduleReadyNotif: Bool?,
    todaysJob = Job(),
    todaysPO: String?,
    vehicleCkListNotif: Bool?,
    toolRenewal: String?,
    toolCount: Int?,
    presentWaiverAlrt: Bool?
    
    var imageAssets: [UIImage] {
        return AssetManager.resolveAssets(picker.stack.assets)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //
        APICalls().sendErrorLog(errMsg: "TEST ERROR MSG")
        
        Auth.auth().addStateDidChangeListener() { (auth, user) in
            if user == nil { self.dismiss(animated: true) }
        }
        UserLocation.instance.initialize()
        setUpNotifications()
        checkAppDelANDnotif()
        setUpHomeBtn()
        loadProfilePic()

        picker.delegate = self
        setIdentifiers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        checkForUserInfo()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        checkForSafetyQs()
        checkForToolRentals()
    }

    @IBAction func pressdProfBtn(_ sender: Any) { profilePress() }
    @IBAction func sendJobCheckup(_ sender: Any) { getJobCheckupInfo() }
    @IBAction func hideCorrectAnswVw(_ sender: Any) { showQuestions(i: indexVal) }
    @IBAction func hideIncorrectAnswVw(_ sender: Any) { showQuestions(i: indexVal) }
    @IBAction func stepperValChangd(_ sender: UIStepper) {
        workersToReturnLbl.text = "\(Int(sender.value))"; employeesToReturn = Int(sender.value)
    }
    
}


extension HomeView {
    
    func setIdentifiers() {
        view.accessibilityIdentifier = "Home View"
        bkgdView.accessibilityIdentifier = "Home_bkgdView"
        homeFanMenu.accessibilityIdentifier = "Home_homeFanMenu"
        userLabel.accessibilityIdentifier = "Home_userLabel"
        profileBtn.accessibilityIdentifier = "Home_profileBtn"
    }
    
    func getJobCheckupInfo() {
        let returnTwr = returnTomorrowSwitch.isOn,
         addedMaterial = self.requiredAddedMaterialsSwitch.isOn
        guard let po = HomeView.todaysJob.poNumber ?? UserDefaults.standard.string(forKey: DefaultKeys.todaysJobPO) else {
            showAlert(withTitle: "Incomplete Form", message: "Couldn't find PO information.")
            return
        }
        let checkupInfo = Job.JobCheckupInfo(
            returnTomorrow: returnTwr, numberOfWorkers: employeesToReturn, addedMaterial: addedMaterial, poNumber: po
        )
        
        if addedMaterial == true {
            SuppliesRequestView.jobCheckupInfo = checkupInfo
            ChangeOrdersView.jobCheckupInfo = checkupInfo
            HomeView.jobCheckup = nil
            
            main.addOperation {
                self.jobCheckUpView.isHidden = true
                self.performSegue(withIdentifier: "suppliesReq", sender: nil)
            }
            
        } else {
            let jsonEncoder = JSONEncoder()
            var body = Data()
            
            do {
                body = try jsonEncoder.encode(checkupInfo)
            } catch {
                print("error: \(error)")
                showAlert(withTitle: "Encoding Error", message: "Error encoding data for server. \(error.localizedDescription)"); return
            }
            inProgress(showProgress: false)
            
            APICalls().sendJobCheckup(po: po, body: body) {
                HomeView.jobCheckup = nil
                self.completedProgress()
            }
        }
    }
    
    func checkForToolRentals() {
        guard let toolsRented = HomeView.toolCount else { return }
        if toolsRented > 0 {
            var toolicons = ""
            
            for _ in 0...toolsRented {
                toolicons += " 🔧 "
            }
            guard let currentTxt = userLabel.text else { return }
            userLabel.text = "\(currentTxt) \n\(toolicons)"
            userLabel.accessibilityValue = "\(currentTxt) \n\(toolicons)"
        }
    }
    
    func checkForSafetyQs() {
        if HomeView.safetyQs.count <= 0 { return }
        
        for (index, value) in HomeView.safetyQs.enumerated() {
            let questionPopup = UIAlertController(title: "Safety Question", message: value.question, preferredStyle: UIAlertController.Style.alert)
            
            let a = UIAlertAction(title: "A. \(value.options.A)", style: UIAlertAction.Style.default) { action in
                questionPopup.dismiss(animated: true, completion: nil)
                self.handleSafetyQuesAnswer(selected: "A", answer: value.answer, options: value.options, i: (index + 1) )
            };
            let b = UIAlertAction(title: "B. \(value.options.B)", style: UIAlertAction.Style.default) { action in
                questionPopup.dismiss(animated: true, completion: nil)
                self.handleSafetyQuesAnswer(selected: "B", answer: value.answer, options: value.options, i: (index + 1))
            };
            let c = UIAlertAction(title: "C. \(value.options.C)", style: UIAlertAction.Style.default) { action in
                questionPopup.dismiss(animated: true, completion: nil)
                self.handleSafetyQuesAnswer(selected: "C", answer: value.answer, options: value.options, i: (index + 1))
            };
            let d = UIAlertAction(title: "D. \(value.options.D)", style: UIAlertAction.Style.default) { action in
                questionPopup.dismiss(animated: true, completion: nil)
                self.handleSafetyQuesAnswer(selected: "D", answer: value.answer, options: value.options, i: (index + 1))
            };
            
            questionPopup.addAction(a)
            questionPopup.addAction(b)
            questionPopup.addAction(c)
            questionPopup.addAction(d)
            
            questionAlerts.append(questionPopup)
        }
        
        main.addOperation {
            self.present(self.questionAlerts[0], animated: false, completion: nil)
        }
    }
    
    func showQuestions(i: Int) {
        incorrectAnswerVw.isHidden = true
        correctAnswerVw.isHidden = true
        
        if i >= self.questionAlerts.count && incorrectAnswer > -1 {
            for alr in questionAlerts { alr.dismiss(animated: false, completion: nil) }
            
            if questionAlerts.count > 0 && questionAlerts[0] != nil {
                self.present(questionAlerts[0], animated: true, completion: nil)
            }
            incorrectAnswer = -1
            indexVal = 1
            
        } else if i >= self.questionAlerts.count {
            HomeView.safetyQs = []
            questionAlerts = []
            
        } else {
            if i < questionAlerts.count && i >= 0 {
                self.present(self.questionAlerts[i], animated: true, completion: nil)
            }
            indexVal += 1
        }
    }
    
    func handleSafetyQuesAnswer(selected: String, answer: String, options: SafetyQuestion.answerOptions, i: Int) {
        var fullAnswer = ""
        indexVal = i
        print("index = \(i)")

        switch answer {
        case "A":
            fullAnswer = options.A;
        case "B":
            fullAnswer = options.B;
        case "C":
            fullAnswer = options.C;
        case "D":
            fullAnswer = options.D;

        default: return;
        }

        if selected == answer {
            correctAnswerVal = true
            makeAlert(correct: "CORRECT", msg: "Answer: \(answer) \(fullAnswer)")
         
            guard let user = HomeView.employeeInfo?.username as? String else { return }
            APICalls().addPoints(employee: user, pts: 2)
        } else {
            incorrectAnswer = i - 1
            correctAnswerVal = false
            makeAlert(correct: "INCORRECT", msg: "Answer: \(answer) \(fullAnswer)")
            guard let user = HomeView.employeeInfo?.username as? String else { return }
            APICalls().addWrongPoints(employee: user, pts: 2)
        }
    }
    
    func makeAlert(correct: String, msg: String) {
        let r = CGFloat(integerLiteral: 20)
        
        if correctAnswerVal == false {
            incrtAnswerLabel.text = msg
            incorrectAnswerVw.layer.cornerRadius = r
            incorrectAnswerVw.isHidden = false
            roundCorners(corners: [.bottomLeft, .bottomRight], radius: r, vw: incrtOKbtn)
            
        } else {
            crtAnswerLabel.text = msg
            correctAnswerVw.layer.cornerRadius = r
            correctAnswerVw.isHidden = false
            roundCorners(corners: [.bottomLeft, .bottomRight], radius: r, vw: crtOKbtn)
        }
    }

    func profilePress() {
        profileUpload = true

            let msg = "Would you like to add/update your profile photo? "
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.alignment = NSTextAlignment.left
            let messageText = NSMutableAttributedString(string: msg, attributes: [
                NSAttributedString.Key.paragraphStyle : paraStyle,
                NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .body),
                NSAttributedString.Key.foregroundColor: UIColor.black
                ])

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

        menuView.menuBackground = Color.rgba(r: 255, g: 255, b: 255, a: 0.25)
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
        menuView.accessibilityIdentifier = "Home_menuView"
        
        homeFanMenu.addSubview(menuView)
        for subVw in homeFanMenu.subviews {
            subVw.backgroundColor = .clear
        }
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
        case "clock_blue":
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
            // Under construction
        case "time_off":
            performSegue(withIdentifier: "time_card", sender: nil)

        default:
            showAlert(
                withTitle: "Under Contruction", message: "Sorry this part is still under construction."
            )
        }
    }

    func checkAppDelANDnotif() {
        let appDelegate: AppDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.homeViewActive = self
        UserLocation.homeViewActive = self

        if appDelegate.didEnterBackground == true {
            notificationCenter.getDeliveredNotifications() { notifications in
                print("request(s) in notif center: \(notifications.count)")
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
                self.inProgress(showProgress: false)

                fetchEmployee(employeeId: Int(employeeID)!) { user in
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
            self.userLabel.text = "Hello \n" + (HomeView.employeeInfo?.username)!
            self.userLabel.accessibilityValue = "Hello \n" + (HomeView.employeeInfo?.username)!
            HomeView.todaysJob.poNumber = UserDefaults.standard.string(forKey: "todaysJobPO")
            self.completedProgress()
        }
    }
}

extension HomeView {

    func fetchEmployee(employeeId: Int, callback: @escaping (UserData.UserInfo) -> ()){
        let route = "employee/" + String(employeeId)
        
        APICalls().setupRequest(route: route, method: "GET") { request in
            APICalls().startSession(request: request, route: route) { json in
                
                guard let user = UserData.UserInfo.fromJSON(dictionary: json)
                    else {
                        print("failed to parse UserData from json\(json)");
                        self.completedProgress()
                        
                        guard let resMsg = json as? [String:String] else { return }
                        self.handleResponseType(responseType: resMsg, formType: "fetchEmployee")
                        return
                }
                callback(user)
            }
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
        main.addOperation { self.jobCheckUpView.isHidden = true }
        completeProgress()
        checkForPushNotifUpdates()
    }

    func checkForPushNotifUpdates() {
        if let checklistForVehicle = HomeView.vehicleCkListNotif {
            if checklistForVehicle == true {
                self.performSegue(withIdentifier: "vehicleCkList", sender: nil)
            }
            
        } else if let readySchedule = HomeView.scheduleReadyNotif {
            if readySchedule == true {
                self.performSegue(withIdentifier: "schedule", sender: nil)
            }
        } else if let jobCheck = HomeView.jobCheckup {
            if jobCheck == true {
                main.addOperation { self.jobCheckUpView.isHidden = false }
            }
        } else if let showWaiver = HomeView.presentWaiverAlrt {
            if showWaiver == true {
                show2ndMealWaiverAlert()
            }
        }
        //        else if HomeView.toolRenewal != nil { extendToolRental() }
    }
    
    public  func show2ndMealWaiverAlert() {
        let alert = UIAlertController(title: "Waive Meal?", message: "Would you like to waive your 2nd meal break?", preferredStyle: .alert)
        let no = UIAlertAction(title: "NO", style: .cancel)
        let yes = UIAlertAction(title: "YES", style: .default) { action in
            self.main.addOperation { self.presentSignature(vc: self, subTitle: "This is to waive your 2nd meal.", title: "Sign Here") }
        }
        
        alert.addAction(no)
        alert.addAction(yes)
        main.addOperation { self.present(alert, animated: true, completion: nil) }
    }
    
    func clockedInUI() {
        guard let info = HomeView.employeeInfo else { return }
        main.addOperation {
            self.userLabel.text = "\(info.username) \nID#: \(info.employeeID) \nClocked IN"
            self.completedProgress()
        }
    }
    func clockedOutUI() {
        guard let info = HomeView.employeeInfo else { return }
        main.addOperation {
            self.userLabel.text = "\(info.username) \nID#: \(info.employeeID) \nClocked OUT"
            self.completedProgress()
        }
    }
}

extension HomeView {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        switch segue.identifier {
        case "schedule":
            let vc = segue.destination as! ScheduleView
            vc.employee = HomeView.employeeInfo
        case "clock_in":
            let vc = segue.destination as! EmployeeIDEntry
            EmployeeIDEntry.foundUser = HomeView.employeeInfo
            guard let unwrap = HomeView.role else { return }
            vc.role = unwrap
        case "changeOrder":
            let vc = segue.destination as! ChangeOrdersView
            let jbName = HomeView.todaysJob.jobName
            vc.todaysJob = jbName
            vc.formTypeVal = "Change Order"
        case "suppliesReq":
            let vc = segue.destination as! SuppliesRequestView
            vc.todaysJob = HomeView.todaysJob
            vc.employeeInfo = HomeView.employeeInfo
        case "toolRental":
            let vc = segue.destination as! ChangeOrdersView
            let jbName = HomeView.todaysJob.jobName
            vc.todaysJob = jbName
            vc.formTypeVal = "Tool Rental"
        case "toolReturn":
            let vc = segue.destination as! ToolReturnView
            guard let id = HomeView.employeeInfo?.employeeID else { return }
            vc.employeeID = id
        case "map":
            let vc = segue.destination as! StoresMapView
            let jbName = HomeView.todaysJob.jobName
            vc.todaysJob = jbName
        case "timeOff":
            let vc = segue.destination as! TimeOffRequestView
            guard let emplyInformation = HomeView.employeeInfo else { return }
            vc.employeeInfo = emplyInformation
        case "time_card":
            guard let emplyInformation = HomeView.employeeInfo else { return }
            TimeCardView.employeeInfo = emplyInformation

        default:
            showAlert(withTitle: "Sorry", message: "That's not a shortcut we recognize.")
        }
    }

    func incorrectID() {
        showAlert(withTitle: "Error", message: "Unable to find that user")
    }

    public func checkPunchStatus() {
        if HomeView.employeeInfo?.username != nil {
            UserDefaults.standard.set(HomeView.employeeInfo?.username, forKey: "employeeName")

            if HomeView.employeeInfo?.punchedIn == true {
                UserLocation.instance.locationManager.startUpdatingLocation()

                setMonitoringForJobLoc()
                clockedInUI()

            } else if HomeView.employeeInfo?.punchedIn == false {
                UserLocation.instance.stopMonitoring()
                clockedOutUI()

            } else { main.addOperation(setFetchedEmployeeUI) }
        } else {
            guard let employeeID = UserDefaults.standard.string(forKey: "employeeID"),
            let id = Int(employeeID) else { return }
            
            fetchEmployee(employeeId: id) { userInfo in
                HomeView.employeeInfo = userInfo
                self.checkPunchStatus()
            }
        }
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
        completedProgress()
        if responseType["success"] == "true" { return }
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
    
    func extendToolRental() {
        let alert = UIAlertController(title: "Extend Tool Rental", message: "How long would you like to extend the rental?", preferredStyle: .alert)
        let no = UIAlertAction(title: "NO", style: .cancel)
        let yes = UIAlertAction(title: "YES", style: .default) { action in
            
            guard let txtFields = alert.textFields,
                let duration = txtFields[0].text,
                let userBrandTool = HomeView.toolRenewal else { return }
            
            self.handleRentalExtension(userBrandTool: userBrandTool, duration: duration)
        }
        
        alert.addTextField() { txtField in
            txtField.placeholder = "Number of days"
            txtField.keyboardType = .numberPad
        }
        
        alert.addAction(yes)
        alert.addAction(no)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleRentalExtension(userBrandTool: String, duration: String) {
        let split = userBrandTool.components(separatedBy: ", ")
        let info = FieldActions.ToolRentalExtension(requestedBy: split[0], toolType: split[2], brand: split[1], duration: duration)
        
        APICalls().extendRental(toolData: info) { json in
            HomeView.toolRenewal = nil
            guard let success = json["success"] as? Bool else { return }
            if success == true {
                self.showAlert(withTitle: "Success!", message: "Tool Rental Extension was uploaded successfully.")
            } else {
                guard let responseDict = json as? [String: String] else { return }
                self.handleResponseType(responseType: responseDict, formType: "Tool Rental Extension")
            }
        }
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
                self.inProgress(showProgress: true)
                
                guard let emply = HomeView.employeeInfo?.username,
                    let idNum = UserDefaults.standard.string(forKey: "employeeID") else { return }
                
                let route = "employee/\(idNum)/profileUpload",
                headers = ["employee", emply],
                info = UserData.AddressInfo(address: "", city: "", state: ""),
                jsonEncoder = JSONEncoder()
                var formBody = Data()
                
                do { formBody = try jsonEncoder.encode(info) }
                catch { print("error converting addressInfo to DATA", error); return };

                self.alamoUpload(route: route, headers: headers, formBody: formBody, images: images, uploadType: "profilePhoto") { responseType in
                    self.saveLocalPhoto(image: images[0])
                    self.loadProfilePic()
                    self.checkSuccess(responseType: responseType)
                    self.profileUpload = nil
                }
            }
        } else if imageAssets.count < 11 {
            picker.dismiss(animated: true) {

                if let po = UserDefaults.standard.string(forKey: "todaysJobPO"),
                    let emply =  UserDefaults.standard.string(forKey: "employeeName") {
                    self.inProgress(showProgress: true)
                    
                    self.uploadJobImages(images: self.imageAssets, jobNumber: po, employee: emply) { responseType in
                        self.checkSuccess(responseType: responseType)
                    }
                } else if let emply =  UserDefaults.standard.string(forKey: "employeeName") {
                    self.promptForPOnum(employee: emply)
                } else {
                    self.promptForPOnum(employee: nil)
                }
            }
        } else {
            picker.showAlert(withTitle: "Max Photos", message: "You can only upload a maximum of 10 photos each time.")
        }
    }
    
    func promptForPOnum(employee: String?) {
        let alert = UIAlertController(title: "Enter PO", message: "No PO number found", preferredStyle: .alert)
        let action = UIAlertAction(title: "Submit", style: .default) { action in
            
            if let txtFields = alert.textFields,
                let poNumber = txtFields[0].text {
                var empl = ""
                
                if let safeEmployee = employee {
                    empl = safeEmployee
                } else if let safeEmployee = txtFields[1].text {
                    empl = safeEmployee
                }
                
                self.inProgress(showProgress: true)
                
                self.uploadJobImages(images: self.imageAssets, jobNumber: poNumber, employee: empl) { responseType in
                    self.checkSuccess(responseType: responseType)
                }
                
            } else {
                self.showAlert(withTitle: "No PO", message: "No PO entered.")
                self.main.addOperation { self.picker.dismiss(animated: true, completion: nil) }
                return
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addTextField() { textField in textField.placeholder = "PO Number" }
        if employee == nil {
            alert.addTextField() { textField in textField.placeholder = "Employee Name" }
        }
        
        alert.addAction(action)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }

    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
}

extension Notification.Name {
    static let info = Notification.Name("employeeInfo")
}


extension HomeView: EPSignatureDelegate {
    
    func convertSomeInfo(cb: @escaping(String, Data)->()) {
        let jsonEncoder = JSONEncoder()
        var data = Data()
        
        guard let employee = HomeView.employeeInfo,
            let poNum = HomeView.todaysPO ?? UserDefaults.standard.string(forKey: DefaultKeys.todaysJobPO) else {
            return
        }
        
        do {
            let codableInfo = UserData.UserInfoCodeable(
                username: employee.username, employeeID: "\(employee.employeeID)", coordinateLat: "", coordinateLong: "", currentRole: "", po: poNum
            )
            data = try jsonEncoder.encode(codableInfo)
            
        } catch { print("Error: \(error)") }
        
        cb(employee.username, data)
    }
    
    func epSignature(_: EPSignatureViewController, didSign signatureImage: UIImage, boundingRect: CGRect) {
        mealWaiverSIgnature = signatureImage
        HomeView.presentWaiverAlrt = nil
        
        convertSomeInfo() { emply, body in
            let route = "mealWaiverSigned/"
            
            self.inProgress(showProgress: true)
            
            self.alamoUpload(route: route, headers: ["employee", emply], formBody: body, images: [signatureImage], uploadType: "mealWaiver") { dict in
                self.completeProgress()
            }
        }
    }
    
    func epSignature(_: EPSignatureViewController, didCancel error: NSError) {
        HomeView.presentWaiverAlrt = nil
    }
}
