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
        
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name ==
            UIResponder.keyboardWillChangeFrameNotification {
            
            OperationQueue.main.addOperation {
                self.view.frame.origin.y = -(keyboardRect.height - (keyboardRect.height / 2))   //   75)
            }
        } else {
            OperationQueue.main.addOperation {
                self.view.frame.origin.y = 0
            }
        }
    }
    
    func setDismissableKeyboard(vc: UIViewController) {
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
    
    func handleResponseType(responseType: [String: String]) {
        OperationQueue.main.addOperation {
            if responseType["success"] == "true" { return }
            else if let msg = responseType["msg"] {
                self.showAlert(withTitle: "Upload Status", message: msg)
            } else if let error = responseType["error"] {
                self.showAlert(withTitle: "Error", message: error)
            } else { print(responseType) }
        }
    }
    
    func inProgress(activityBckgd: UIView, activityIndicator: UIActivityIndicatorView, showProgress: Bool) {
        activityBckgd.accessibilityIdentifier = "activityBckgd"
        
        if showProgress == true {
            let w = CGFloat(activityBckgd.frame.width / 2)
            let progressLabel = UIProgressView(
                frame: CGRect(
                    x: CGFloat(activityIndicator.center.x - (w / 2)),
                    y: CGFloat(activityIndicator.center.y + (activityIndicator.frame.height * 2)),
                    width: w,
                    height: CGFloat(activityIndicator.frame.height)
                )
            )
            
            progressLabel.accessibilityIdentifier = "progressLabel"
            progressLabel.progress = 0.0
            progressLabel.trackTintColor = .black
            
            activityBckgd.addSubview(progressLabel)
            
        } else {
            for subVw in activityBckgd.subviews {
                if subVw.accessibilityIdentifier == "progressLabel" {
                    activityBckgd.willRemoveSubview(subVw)
                }
            }
        }
        
        OperationQueue.main.addOperation {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            activityBckgd.isHidden = false
            activityIndicator.startAnimating()
        }
    }
    
    func completeProgress(activityBckgd: UIView, activityIndicator: UIActivityIndicatorView) {
        OperationQueue.main.addOperation {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            activityBckgd.isHidden = true
            activityIndicator.stopAnimating()
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
        
        alamoUpload(route: route, headers: headers, formBody: Data(), images: images, uploadType: "job_\(jobNumber)") { responseType in
            callback(responseType)
        }
    }
    
    func alamoUpload(route: String, headers: [String], formBody: Data, images: [UIImage], uploadType: String, callback: @escaping ([String: String]) -> ()) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let url = "\(APICalls.host)\(route)"
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
                        var i = 0
                        for img in images {
                            guard let imageData = img.jpegData(compressionQuality: 1) else { return }
                            let nm = "\(uploadType)_\(i)"
                            
                            multipartFormData.append( imageData, withName: nm, fileName: "\(nm).jpg", mimeType: "image/jpeg")
                            i += 1
                        }
                },
                    usingThreshold: UInt64.init(), to: url, method: .post, headers: headers,
                    encodingCompletion: { encodingResult in
                        switch encodingResult {
                        case .success(let upload, _, _):
                            var progressLabel = self.getProgressLabel()
                            upload.uploadProgress { progress in
                                let percent = Float(progress.fractionCompleted * 100).rounded()
                                progressLabel.setProgress(percent, animated: true)
                            }
                            upload.validate()
                            upload.responseString { response in
                                
                                guard response.result.isSuccess else {
                                    guard let err = response.error as? String else {
                                        APICalls.succeedOrFailUpload(msg: "Error occured with upload.", uploadType: uploadType, success: false)
                                        callback(["error" : response.result.description]); return
                                    }
                                    print("error while uploading file: \(err)");
                                    APICalls.succeedOrFailUpload(msg: "Error occured: \(err) with upload: ", uploadType: uploadType, success: false)
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
                            print(encodingError);
                            APICalls.succeedOrFailUpload(msg: "Failed to upload: ", uploadType: uploadType, success: false)
                            callback(["error": encodingError.localizedDescription]); return
                            
                        default:
                            APICalls.succeedOrFailUpload(msg: "Failed with error.", uploadType: uploadType, success: false)
                            callback(["error": "Unknown error"]); return
                        }
                }
                );  UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    
}


