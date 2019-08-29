//
//  ViewExtensions.swift
//  FieldApp
//
//  Created by MB Mac 3 on 8/30/18.
//  Copyright © 2018 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import UserNotificationsUI
import EPSignature
import MapKit
import Alamofire
import MLPAutoCompleteTextField


extension UIViewController {

    func setShadows(btns: [UIButton]) {
        for button in btns {
            button.layer.shadowColor = UIColor.darkGray.cgColor
            button.layer.shadowOffset = CGSize(width: 1, height: 2)
            button.layer.shadowRadius = 2
            button.layer.shadowOpacity = 0.80
        }
    }
    
    func showAlert(withTitle title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        let main = OperationQueue.main
        
        alert.addAction(action)
        main.addOperation { self.present(alert, animated: true, completion: nil) }
    }
    
    func createNotification(intervalInSeconds interval: Double, title: String, message: String, identifier: String) -> UNNotificationRequest {
        let timeInterval = TimeInterval(interval)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        return request
    }
    
    func presentSignature(vc: UIViewController, subTitle: String, title: String) {
        guard let delegate = vc as? EPSignatureDelegate else { return }
        let signatureVC = EPSignatureViewController(signatureDelegate: delegate, showsDate: true)
        
        signatureVC.subtitleText = subTitle
        signatureVC.title = title
        
        let nav = UINavigationController(rootViewController: signatureVC)
        OperationQueue.main.addOperation {
            vc.present(nav, animated: true, completion: nil)
        }
    }
    
    @objc func keyboardWillChange(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
            
            OperationQueue.main.addOperation {
                self.view.frame.origin.y = -(keyboardRect.height - (keyboardRect.height / 2))
            }
        } else {
            OperationQueue.main.addOperation {
                self.view.frame.origin.y = 0
            }
        }
    }
    
    func setDismissableKeyboard(vc: UIViewController) {
        OperationQueue.main.addOperation {
            vc.view.addGestureRecognizer(
                UITapGestureRecognizer(target: vc.view, action: #selector(UIView.endEditing(_:)))
            )
        }
    }
    
    func setNotifsForAdjustedFrame(vc: UIViewController) {
        OperationQueue.main.addOperation {
            vc.view.frame.origin.y = 0
            
            vc.view.addGestureRecognizer(
                UITapGestureRecognizer(target: vc.view, action: #selector(UIView.endEditing(_:)))
            )
            NotificationCenter.default.addObserver(
                vc, selector: #selector(vc.keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil
            )
            NotificationCenter.default.addObserver(
                vc, selector: #selector(vc.keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil
            )
            NotificationCenter.default.addObserver(
                vc, selector: #selector(vc.keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil
            )
        }
    }
    
    func openMapsWithDirections(to coordinate: CLLocationCoordinate2D, destination name: String) {
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: options)
    }
    
    func handleResponseType(responseType: [String: String], formType: String) {
        OperationQueue.main.addOperation {
            
            if responseType["success"] == "true" {
                if formType == "fetchEmployee" { return }
                
                let alert = UIAlertController(title: "Success!", message: "\(formType) was uploaded successfully.", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default) { action in
                    if formType == "Supplies Request" {
                        self.performSegue(withIdentifier: "toHomeFromChangeOrder", sender: nil)
                    } else {
                        self.dismiss(animated: true)
                    }
                }
                
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
                
            } else if let msg = responseType["msg"] {
                self.showAlert(withTitle: "Upload Status", message: msg)
                
            } else if let error = responseType["error"] {
                self.showAlert(withTitle: "Error", message: error)
                
            } else {
                print(responseType)
            }
        }
    }
    
    func inProgress(showProgress: Bool) {
        
        OperationQueue.main.addOperation {
            let blurredView = UIVisualEffectView()
            blurredView.frame = self.view.frame
            blurredView.effect = UIBlurEffect(style: .regular)
            
            let indicator = UIActivityIndicatorView(frame: self.view.frame)
            indicator.style = .whiteLarge
            indicator.color = UIColor.blue
            indicator.hidesWhenStopped = true
            indicator.startAnimating()
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.view.addSubview(blurredView)
            self.view.addSubview(indicator)
            
            for vw in self.view.subviews {
                if vw.isKind(of: UIButton.self) && vw.accessibilityIdentifier == "backBtn" {
                    self.view.bringSubviewToFront(vw)
                }
            }
        }
        
        if showProgress == true {
            let w = CGFloat(view.frame.width / 2)
            let progressLabel = UIProgressView(
                frame: CGRect(
                    x: CGFloat(view.center.x - (w / 2)),
                    y: CGFloat(view.center.y + (view.frame.height * 2)),
                    width: w,
                    height: CGFloat(view.frame.height)
                )
            )
            progressLabel.accessibilityIdentifier = "progressLabel"
            progressLabel.progress = 0.0
            progressLabel.trackTintColor = .black
            
            OperationQueue.main.addOperation {
                self.view.addSubview(progressLabel)
                self.view.bringSubviewToFront(progressLabel)
            }
        }
    }
    
    func completeProgress() {
        OperationQueue.main.addOperation {
            for vw in self.view.subviews {
                if vw.isKind(of: UIVisualEffectView.self) || vw.isKind(of: UIActivityIndicatorView.self) || vw.isKind(of: UIProgressView.self) {
                    vw.removeFromSuperview()
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }
    }
    
    func getProgressLabel() -> UIProgressView {
        var progressLabel: UIProgressView?
        
        for subVw in self.view.subviews {
            if subVw.accessibilityIdentifier == "activityBckgd" {
                
                for subSubVw in subVw.subviews {
                    if subSubVw.accessibilityIdentifier == "progressLabel" {
                        progressLabel = subSubVw as? UIProgressView
                    }
                }
            }
        }
        guard var unwrappedLb = progressLabel as? UIProgressView else { return UIProgressView() }
        return unwrappedLb
    }
    
    func uploadJobImages(images: [UIImage], jobNumber: String, employee: String, callback: @escaping ([String : String]) -> () ) {
        let route = "job/\(jobNumber)/upload"
        let headers = ["employee", employee]
        let uploadType = "job_\(jobNumber)"
        
        alamoUpload(route: route, headers: headers, formBody: Data(), images: images, uploadType: uploadType) { responseType in
            callback(responseType)
        }
    }
    
    func alamoUpload(route: String, headers: [String], formBody: Data, images: [UIImage?], uploadType: String, callback: @escaping ([String: String]) -> () ) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        guard let url = URL(string: "\(APICalls.host)\(route)") else { return }
        var headers: HTTPHeaders = [
            "Content-type" : "multipart/form-data", headers[0] : headers[1]
        ]
        UsernameAndPassword.getUsernmAndPasswd() { userNpass in
            headers.updateValue(userNpass.username, forKey: "username")
            headers.updateValue(userNpass.password, forKey: "password")
            
            APICalls.getFIRidToken() { idToken in
                headers.updateValue(idToken, forKey: "Authorization")
                headers.updateValue("close", forKey: "Connection")
                
                Alamofire.upload(
                    multipartFormData: { multipartFormData in
                        multipartFormData.append(formBody, withName: uploadType)
                        
                            for (i, val) in images.enumerated() {
                                guard let validImage = val as? UIImage else { continue }
                                guard let imageData = validImage.jpegData(compressionQuality: 1) else { return }
                                let nm = "\(uploadType)_\(i)"

                                multipartFormData.append(imageData, withName: nm, fileName: "\(nm).jpg", mimeType: "image/jpeg")
                            }
                },
                    usingThreshold: UInt64.init(),
                    to: url,
                    headers: headers,
                    encodingCompletion: { encodingResult in
                        
                        switch encodingResult {
                            
                        case .success(let upload, _, _):
                            var progressLabel = self.getProgressLabel()
                            OperationQueue.main.addOperation { self.view.bringSubviewToFront(progressLabel) }
                            
                            upload.uploadProgress { progress in
                                let percent = Float(progress.fractionCompleted * 100).rounded()
                                OperationQueue.main.addOperation { progressLabel.setProgress(percent, animated: true) }
                            }
                            upload.validate()
                           
                            upload.responseString() { response in
                                print("Alamofire upload: response: \n\(response.response) \n\(response.error)")
                                
                                guard response.result.isSuccess else {
                                    guard let err = response.error as? String else {
                                        APICalls.succeedOrFailUpload(msg: "Error occured with upload. ", uploadType: uploadType, success: false)
                                        callback(["error" : response.result.description]); return
                                    }
                                    print("error while uploading file: \(err)");
                                    APICalls.succeedOrFailUpload(msg: "Error occured with upload: \(err)", uploadType: uploadType, success: false)
                                    callback(["error" : err]); return
                                }
                                guard let msg = response.result.value,
                                    let data: Data = msg.data(using: String.Encoding.utf16, allowLossyConversion: true),
                                    let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? NSDictionary else {
                                        APICalls.succeedOrFailUpload(msg: " uploaded successfully.", uploadType: uploadType, success: true);
                                        callback(["success": "true"]); return
                                }
                                APICalls().handleResponseMsgOrErr(json: json, uploadType: uploadType) { responseType in
                                    callback(responseType)
                                }
                            }
                        case .failure(let encodingError):
                            print("encodingError: \(encodingError)");
                            APICalls.succeedOrFailUpload(msg: "Failed to encode photos.", uploadType: uploadType, success: false)
                            callback(["error": encodingError.localizedDescription]); return
                            
                        default:
                            APICalls.succeedOrFailUpload(msg: "Failed with unknown error.", uploadType: uploadType, success: false)
                            callback(["error": "Unknown error"]); return
                        }
                })
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    
    func checkForNotifUpdates() {
        if let checklistForVehicle = HomeView.vehicleCkListNotif {
            if checklistForVehicle == true {
                self.dismiss(animated: true, completion: nil)
            }
            
        } else if let readySchedule = HomeView.scheduleReadyNotif {
            if readySchedule == true {
                self.dismiss(animated: true, completion: nil)
            }
        } else if let jobCheck = HomeView.jobCheckup {
            if jobCheck == true {
                self.dismiss(animated: true, completion: nil)
            }
        }
        //        else if HomeView.toolRenewal != nil { extendToolRental() }
    }
    
    func showPOEntryWindow(foundUser: UserData.UserInfo?, role: String) {
        guard let coordinates = UserLocation.instance.currentCoordinate,
            let uwrappedUsr = foundUser else {
                print("no coordinates, user or role found")
                return
        }
        let alert = UIAlertController(
            title: "Manual PO Entry", message: "No PO found. \nEnter PO number manually?", preferredStyle: .alert
        )
        let cancel = UIAlertAction(title: "Cancel", style: .destructive)
        let manualPOentry = UIAlertAction(title: "Send", style: .default) { action in
            let poNumber = alert.textFields![0]
            
            if poNumber.text != nil && poNumber.text != "" {
                let po = poNumber.text!
                
                APICalls().sendCoordinates(
                    employee: uwrappedUsr, location: coordinates, autoClockOut: false, role: role, po: po, override: true
                ) { success, currentJob, poNumber, jobLatLong, clockedIn, err in
                    // do smth here
                }
            }
        }
        
        alert.addAction(manualPOentry)
        alert.addAction(cancel)
        alert.addTextField { textFieldPOnum in
            textFieldPOnum.placeholder = "PO number"; textFieldPOnum.keyboardType = UIKeyboardType.asciiCapableNumberPad
        }
        OperationQueue.main.addOperation { self.present(alert, animated: true, completion: nil) }
    }
    
    
    func roundCorners(corners: UIRectCorner, radius: CGFloat, vw: UIView) {
        let path = UIBezierPath(roundedRect: vw.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        vw.layer.mask = mask
    }
    
    func addBackgroundBlur(vw: UIView) {
        let blurEffect = UIBlurEffect(style: .dark)
        
        OperationQueue.main.addOperation {
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = self.view.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurView.accessibilityIdentifier = "backgroundBlurView"
            vw.addSubview(blurView)
        }
    }
    
    func removeSubviewWithIdentifier(identifier: String, vw: UIView) {
        for subView in vw.subviews {
            if subView.accessibilityIdentifier == identifier {
                OperationQueue.main.addOperation { subView.removeFromSuperview() }
            }
        }
    }
    
}

//extension UIViewController: UITextFieldDelegate, MLPAutoCompleteTextFieldDelegate, MLPAutoCompleteTextFieldDataSource {
//
//}
