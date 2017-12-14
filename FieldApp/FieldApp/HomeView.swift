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

class HomeView: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var photoToUpload: UIImageView!
    @IBOutlet weak var choosePhotoButton: UIButton!
    @IBOutlet weak var userLabel: UILabel!
    
    let firebaseAuth = Auth.auth()
    let picker = UIImagePickerController()
    var jobs: [Job.UserJob] = []
    let main = OperationQueue.main
    var location = UserData.init().userLocation
    var jobAddress = ""
    var firAuthId = UserDefaults.standard.string(forKey: "authVerificationID")
    var employeeInfo: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Auth.auth().addStateDidChangeListener() { (auth, user) in
            if user == nil {
                self.dismiss(animated: true)
            }
        }
        APICalls().isEmployeePhone(view: self) { foundUser in
            self.main.addOperation {
                self.userLabel.text = foundUser.userName
                self.getLocation() { coordinate in
                    APICalls().convertToJSON()
                }
            }
        }
    }

    @IBAction func logoutPressed(_ sender: Any) {
        
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            return
        }
    }

    @IBAction func chooseUploadMethod(_ sender: Any) {
        showUploadMethods()
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let selectedPhoto = info[UIImagePickerControllerOriginalImage] as! UIImage
        //let imagePath = info[UIImagePickerControllerReferenceURL]
        
        photoToUpload.contentMode = .scaleAspectFit
        photoToUpload.image = selectedPhoto
        
        self.uploadPhoto(photo: selectedPhoto)
        
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension HomeView {
    
    func showUploadMethods() {
        
        var actionsheet = UIAlertController(title: "Choose Upload method", message: "You can upload by Camera or from your Photos", preferredStyle: UIAlertControllerStyle.actionSheet)
        
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
            //Removes photo from upload
            print("chose Cancel")
        }
        actionsheet.addAction(chooseCamera)
        actionsheet.addAction(choosePhotos)
        actionsheet.addAction(cancel)
        
        self.present(actionsheet, animated: true)
    }
    
    func uploadPhoto(photo: UIImage) {
        
        guard let imageData = UIImageJPEGRepresentation(photo, 0.5) else {
            print("Could not get JPEG representation of UIImage")
            return
        }
        
        let storage = Storage.storage()
        let data = imageData
        let storageRef = storage.reference()
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        let result = formatter.string(from: date)
        print("\n imageName will be: image\(result)\(jobs[1].storeName)_PO_\(jobs[1].poNumber).jpg")

        let imageStorageRef = storageRef.child("image\(result)\(jobs[0].storeName)_PO_\(jobs[0].poNumber).jpg")
        
        let uploadTask = imageStorageRef.putData(data, metadata: nil) { (metadata, error) in
            
            guard let metadata = metadata else {
                print("uploadtask error \(error)")
                return
            }
            if error == nil {
                let downloadURL = metadata.downloadURL()
                self.confirmUpload()
            }
        }
        uploadTask.enqueue()
    }
    
}

extension HomeView {
    //([Job.UserJob]) -> ()
    //            jobs in
    //            self.jobs = jobsr
    //            callback(jobs)

    func getEmployeeInfo(callback: @escaping (UserData.UserInfo) -> ()) {
        
        APICalls().fetchEmployee(employeeId: 1234) { user in
            callback(user)
            self.main.addOperation {
            }
        }
    }
    
    func getLocation(completition: @escaping (CLLocationCoordinate2D) -> Void) {
        
        UserLocation.instance.requestLocation(){ coordinate in
            self.location = coordinate
            print("User location is --> \(coordinate) \n")
            completition(coordinate)
        }
    }
    
    func checkJobProximity() {
        
        self.getLocation() { completition in
            
            self.jobAddress = "\(self.jobs[0].jobAddress), \(self.jobs[0].jobCity), \(self.jobs[0].jobState)"
            GeoCoding.locationForAddressCode(address: self.jobAddress) { location in
                let distance = GeoCoding.getDistance(userLocation: self.location!, jobLocation: location!)
                print("Miles from job location is --> \(distance) \n")
                
                if distance > 1.0 {
                    print("NO <-- User is not in proximity to Job location \n")
                } else {
                    print("YES <-- User is in proximity to Job location \n")
                }
            }
        }
        
    }
    
    func confirmUpload() {
        var actionsheet = UIAlertController(title: "Successful", message: "Photo was uploaded successfully", preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) {(action) in
            actionsheet.dismiss(animated: true, completion: nil)
        }

        actionsheet.addAction(ok)
        self.present(actionsheet, animated: true)
    }
}
