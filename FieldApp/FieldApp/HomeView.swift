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
import FirebaseStorage
import CoreLocation
//import Alamofire
//import SwiftyJSON

class HomeView: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var photoToUpload: UIImageView!
    @IBOutlet weak var choosePhotoButton: UIButton!
    @IBOutlet weak var userLabel: UILabel!
    
    @IBOutlet weak var clockInOut: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityBckgd: UIView!
    @IBOutlet weak var calendarButton: UIButton!
    
    let firebaseAuth = Auth.auth()
    var firAuthId = UserDefaults.standard.string(forKey: "authVerificationID")
    let main = OperationQueue.main
    let picker = UIImagePickerController()
    let keyPathToObserve = "employeeInfo"

    var employeeInfo: UserData.UserInfo?
    var jobs: [Job.UserJob] = []
    var jobAddress = ""
    var todaysJob = Job()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
        activityIndicator.hidesWhenStopped = true
        
        picker.delegate = self
        UserLocation.instance.initialize()
        self.addObserver(self, forKeyPath: keyPathToObserve, options: .new, context: nil)
        
        Auth.auth().addStateDidChangeListener() { (auth, user) in
            if user == nil { self.dismiss(animated: true) }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        checkForUserInfo()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == keyPathToObserve {
            checkForUserInfo()
            print("employee info was changed \(String(describing: change))")
        }
    }
    
    @IBAction func logoutPressed(_ sender: Any) { logOut() }
    @IBAction func chooseUploadMethod(_ sender: Any) { showUploadMethods() }
    @IBAction func goClockInOut(_ sender: Any) { performSegue(withIdentifier: "clock_in", sender: self) }
    @IBAction func goToSchedule(_ sender: Any) { performSegue(withIdentifier: "schedule", sender: self) }
    
    func logOut() {
        do { try firebaseAuth.signOut() }
        catch let signOutError as NSError { print("Error signing out: %@", signOutError); return }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let selectedPhoto = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        photoToUpload.contentMode = .scaleAspectFit
        photoToUpload.image = selectedPhoto
        
        dismiss(animated: true)
        guard let po = todaysJob.poNumber else {
            print("todays job po number: ")
            print(todaysJob.poNumber)
            return
        }
        uploadPhoto(photo: selectedPhoto, poNumber: po)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { dismiss(animated: true, completion: nil) }
}

extension HomeView {
    
    func setMonitoringForJobLoc() {
        var coordindates: CLLocationCoordinate2D?
        let latLong = UserDefaults.standard.array(forKey: "todaysJobLatLong")

        if todaysJob.jobName != nil && todaysJob.jobLocation?[0] != nil && todaysJob.jobLocation?[1] != nil {
            coordindates = CLLocationCoordinate2D(latitude: todaysJob.jobLocation![0], longitude: todaysJob.jobLocation![1])
            UserLocation.instance.startMonitoring(location: coordindates!)
            
            UserDefaults.standard.set(todaysJob.poNumber, forKey: "todaysJobPO")
            UserDefaults.standard.set(todaysJob.jobLocation, forKey: "todaysJobLatLong")
        
        } else if latLong?[0] != nil && latLong?[1] != nil{
            guard let locAsDoubles = latLong as? [Double] else  { return }
            coordindates = CLLocationCoordinate2D(latitude: locAsDoubles[0], longitude: locAsDoubles[1])
            UserLocation.instance.startMonitoring(location: coordindates!)
        
        } else { //No job loc available
            UserLocation.instance.requestLocation() { userLoc in
                UserLocation.instance.startMonitoring(location: userLoc)
            }
        }
    }
    
    func checkForUserInfo() {
        if employeeInfo?.employeeID != nil {
            print("punched in -- \(employeeInfo!.punchedIn)")

            if employeeInfo!.punchedIn == true {
                self.main.addOperation { self.clockedInUI() }
                setMonitoringForJobLoc()

            } else if employeeInfo!.punchedIn == false {
                self.main.addOperation { self.clockedOutUI() }
                UserLocation.instance.stopMonitoring()
                UserDefaults.standard.set(nil, forKey: "todaysJobPO")
            } else { return }
            
        } else {
            if let employeeID = UserDefaults.standard.string(forKey: "employeeID") {
                inProgress()
                
                APICalls().fetchEmployee(employeeId: Int(employeeID)!) { user in
                    self.employeeInfo = user
                    
                    if self.employeeInfo?.userName != nil {
                        self.setFetchedEmployeeUI()
                        UserDefaults.standard.set(self.employeeInfo?.userName, forKey: "employeeName")
                        if self.employeeInfo?.punchedIn == true { self.setMonitoringForJobLoc() }
                    }
                }
            } else { completedProgress() }
        }
    }
    
    func setFetchedEmployeeUI() {
        self.main.addOperation {
            self.completedProgress()
            self.userLabel.textColor = UIColor.white
            self.userLabel.backgroundColor = UIColor.blue
            self.userLabel.text = "Hello \n" + (self.employeeInfo?.userName)!
            self.todaysJob.poNumber = UserDefaults.standard.string(forKey: "todaysJobPO")
        }
    }
    
    func showUploadMethods() {
        
        let actionsheet = UIAlertController(title: "Choose Upload method", message: "You can upload by Camera or from your Photos", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let chooseCamera = UIAlertAction(title: "Camera", style: UIAlertActionStyle.default) { (action) -> Void in
            //present Camera
            self.picker.allowsEditing = false
            self.picker.sourceType = .camera
            self.picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera)!
            self.present(self.picker, animated: true, completion: nil)
        }
        let choosePhotos = UIAlertAction(title: "Photos", style: UIAlertActionStyle.default) { (action) -> Void in
            //present Photos
            self.picker.allowsEditing = false
            self.picker.sourceType = .photoLibrary
            self.picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
            self.present(self.picker, animated: true, completion: nil)
        }
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive) { (action) -> Void in
            print("chose Cancel")
        }
        actionsheet.addAction(chooseCamera)
        actionsheet.addAction(choosePhotos)
        actionsheet.addAction(cancel)
        
        self.present(actionsheet, animated: true)
    }
    
    func uploadPhoto(photo: UIImage, poNumber: String){
        self.main.addOperation { self.inProgress() }
        guard let imageData = UIImageJPEGRepresentation(photo, 0.25) else { print("Couldn't get JPEG representation"); return }
        guard let poNum = todaysJob.poNumber else { print("couldnt find todays po number"); return }
        
        APICalls().sendPhoto(imageData: imageData, poNumber: poNum) { responseObj in
            self.main.addOperation {
                self.completedProgress()
                self.confirmUpload()
            }
        }
    }
    
//    func upload(image: UIImage,
//                progressCompletion: @escaping (_ percent: Float) -> Void) {
//
//        let address = "https://mb-server-app-kbradbury.c9users.io/job/"
//        let jobNumber = String(1234) // PO - Grand and Foothill
//        let url = address + jobNumber + "/upload"
//        let fileNmStrg = String(photoName + ".jpg")
//        guard let photoName = employeeInfo?.employeeJobs[0] else { return }
//        let fileName = fileNmStrg
//        guard let imageData = UIImageJPEGRepresentation(image, 0.5) else { return }
//
//        Alamofire.upload(
//            multipartFormData: { multipartFormData in
//
//                multipartFormData.append(imageData,
//                                         withName: fileName,
//                                         mimeType: "image/jpeg")
//                print(imageData)
//        },
//            to: url,
//            encodingCompletion: { encodingResult in
//                switch encodingResult {
//
//                case .success(let upload, _, _):
//                    upload.uploadProgress { progress in
//                        progressCompletion(Float(progress.fractionCompleted))
//                    }
//                    //                    upload.validate()
//                    upload.responseJSON { response in
//                        guard response.result.isSuccess else {
//                            print("error while uploading file: \(String(describing: response.result.error))")
//                            return
//                        }
//                    }
//
//                case .failure(let encodingError):
//                    print(encodingError)
//                }
//        }
//        )
//    }
    
}

extension HomeView {
    
    func confirmUpload() {
        let actionsheet = UIAlertController(title: "Successful", message: "Photo was uploaded successfully", preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) {(action) in
            actionsheet.dismiss(animated: true, completion: nil)
        }
        actionsheet.addAction(ok)
        self.present(actionsheet, animated: true)
    }
    
    func checkJobProximity() {
        UserLocation.instance.requestLocation(){ coordinate in
            let jobLocation = self.jobs[0].jobLocation
            let distance = GeoCoding.getDistance(userLocation: coordinate, jobLocation: jobLocation)
            print("Miles from job location is --> \(distance) \n")
            if distance > 1.0 { print("NO <-- User is not in proximity to Job location \n") }
            else { print("YES <-- User is in proximity to Job location \n") }
        }
    }
    
    func inProgress() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        activityBckgd.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func completedProgress() {
        activityBckgd.isHidden = true
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func clockedInUI() {
        userLabel.backgroundColor = UIColor.green
        userLabel.textColor = UIColor.white
        self.userLabel.text = "Clocked In"
    }
    func clockedOutUI() {
        userLabel.backgroundColor = UIColor.red
        userLabel.textColor = UIColor.black
        self.userLabel.text = "Clocked Out"
    }
}

extension HomeView {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "schedule" {
            let vc = segue.destination as! ScheduleView
            vc.employee = employeeInfo
        } else if segue.identifier == "clock_in" {
            let vc = segue.destination as! EmployeeIDEntry
            vc.foundUser = employeeInfo
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
    
}

extension UIViewController {
    func showAlert(withTitle title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}



