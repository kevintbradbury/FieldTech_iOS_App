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
import Alamofire
import SwiftyJSON

class HomeView: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var photoToUpload: UIImageView!
    @IBOutlet weak var choosePhotoButton: UIButton!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var uploadBar: UIProgressView!
    
    let firebaseAuth = Auth.auth()
    let picker = UIImagePickerController()
    var jobs: [Job.UserJob] = []
    let main = OperationQueue.main
    var location = UserData.init().userLocation
    var jobAddress = ""
    var firAuthId = UserDefaults.standard.string(forKey: "authVerificationID")
    var employeeInfo: UserData.UserInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        UserLocation.instance.initialize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        uploadBar.isHidden = true
        uploadBar.progress = 0.0
        
        Auth.auth().addStateDidChangeListener() { (auth, user) in
            if user == nil {
                self.dismiss(animated: true)
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
        guard let imageData = UIImageJPEGRepresentation(selectedPhoto, 0.5) else {
            print("Couldn't get JPEG representation")
            return
        }
        photoToUpload.contentMode = .scaleAspectFit
        photoToUpload.image = selectedPhoto
        
        uploadBar.isHidden = false
        uploadBar.progress = 0.0
        
        dismiss(animated: true)
        uploadPhoto(photoData: imageData, poNumber: (employeeInfo?.employeeJobs[0])!)
//        upload(image: (selectedPhoto),
//               progressCompletion: {[unowned self] percent in
//                self.uploadBar.setProgress(percent, animated: true)
//        })
        //        self.uploadToFirebase(photo: selectedPhoto)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension HomeView {
    
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
    
    func uploadPhoto(photoData: Data, poNumber: String){
        
        let jsonString = "https://mb-server-app-kbradbury.c9users.io/"
        let route = "job/1234/upload"
        let url = URL(string: jsonString + route)!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0 * 5000)
        request.httpMethod = "POST"
        request.addValue("image/jpeg", forHTTPHeaderField: "mimeType")
        request.httpBody = photoData
        print("request body is -- \(request.httpBody)")
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
                
            }
        }
        task.resume()
    }
    
    func upload(image: UIImage,
                progressCompletion: @escaping (_ percent: Float) -> Void) {
        
        let address = "https://mb-server-app-kbradbury.c9users.io/job/"
        let jobNumber = String(1234) // PO - Grand and Foothill
        let url = address + jobNumber + "/upload"
        guard let photoName = employeeInfo?.employeeJobs[0] else {return}
        let fileName = photoName + ".jpg"
        guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
            print("Couldn't get JPEG representation")
            return
        }
        
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(imageData,
                                         withName: fileName,
                                         mimeType: "image/jpg")
                print(imageData)
        },
            to: url,
            //            headers: ["Content-Type":"image/jpeg"],
            encodingCompletion: { encodingResult in
                switch encodingResult {
                    
                case .success(let upload, _, _):
                    upload.uploadProgress { progress in
                        progressCompletion(Float(progress.fractionCompleted))
                    }
                    //                    upload.validate()
                    upload.responseJSON { response in
                        guard response.result.isSuccess else {
                            print("error while uploading file: \(response.result.error)")
                            return
                        }
                        self.main.addOperation {
                            self.uploadBar.isHidden = true
                            self.confirmUpload()
                        }
                    }
                    
                case .failure(let encodingError):
                    print(encodingError)
                }
        }
        )
    }
    
    func uploadToFirebase(photo: UIImage) {
        
        var address = "https://mb-server-app-kbradbury.c9users.io/"
        
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
                print("uploadtask error \(String(describing: error))")
                return
            }
            if error == nil {
                _ = metadata.downloadURL()
                self.confirmUpload()
            }
        }
        uploadTask.enqueue()
    }
    
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
    
    func getEmployeeInfo(callback: @escaping (UserData.UserInfo) -> ()) {
        
        EmployeeIDEntry().fetchEmployee(employeeId: 1234) { user in
            callback(user)
            self.main.addOperation {
            }
        }
    }
    
    func checkJobProximity() {
        
        EmployeeIDEntry().getLocation() { completition in
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
    
}
