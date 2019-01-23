//
//  ToolSignOffView.swift
//  FieldApp
//
//  Created by MB Mac 3 on 10/3/18.
//  Copyright © 2018 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import NotificationCenter
import EPSignature

class ToolSignOffView: UIViewController {
    
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var backBtn: UIButton!
    @IBOutlet var returnerBtn: UIButton!
    @IBOutlet var returnerSIgnatureView: UIImageView!
    @IBOutlet var printNameRenterField: UITextField!
    @IBOutlet var receiverBtn: UIButton!
    @IBOutlet var receiverSignatureView: UIImageView!
    @IBOutlet var printNameReceiverField: UITextField!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var activityBckgd: UIView!
    
    public var toolToReturn: FieldActions.ToolRental?
    var signatureRole = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setGesturesAndViews()
        print("toolToReturn: \(String(describing: toolToReturn))")
    }
    
    @IBAction func goBack(_ sender: Any) { dismiss(animated: true, completion: nil) }
    @IBAction func returnerTap(_ sender: Any) {
        signatureRole = "returner"
        self.presentSignature(vc: self, subTitle: String("Tool \(signatureRole) sign your initials here."), title: "Initial here")
    }
    @IBAction func receiverTap(_ sender: Any) {
        signatureRole = "receiver"
        self.presentSignature(vc: self, subTitle: String("Tool \(signatureRole) sign your initials here."), title: "Initial here")
    }
    @IBAction func submitReturn(_ sender: Any) { sendSignatures() }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
}

extension ToolSignOffView {
    
    func setGesturesAndViews() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, YYYY"
        dateLabel.text = dateFormatter.string(from: Date())
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.isHidden = true
        activityBckgd.isHidden = true
        
        self.setDismissableKeyboard(vc: self)
    }
    
    func sendSignatures() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy, h:mm a"
        
        guard let returnerSig = returnerSIgnatureView.image,
            let receiverSig = receiverSignatureView.image,
            let returnerNm = printNameRenterField.text,
            let receiverNm = printNameReceiverField.text,
            let rental = toolToReturn,
            let employeeID = UserDefaults.standard.string(forKey: "employeeID") else {
                showAlert(withTitle: "Incomplete", message: "Fill out all fields before submitting."); return
        }
        inProgress(activityBckgd: activityBckgd, activityIndicator: activityIndicator)
        
        let dt =  dateFormatter.string(from: Date())
        let images = [returnerSig, receiverSig]
        let printedNames = [returnerNm, receiverNm]
        let formBody = APICalls().generateToolReturnData(toolForm: rental, signedDate: dt, printedNames: printedNames)
        let route = "toolReturn/\(employeeID)"
        let headers = ["formType", "Tool Return"]
        
        APICalls().alamoUpload(route: route, headers: headers, formBody: formBody, images: images, uploadType: "toolReturn") { responseType in
            self.completeProgress(activityBckgd: self.activityBckgd, activityIndicator: self.activityIndicator)
            self.handleResponseType(responseType: responseType)
        }
    }
}

extension ToolSignOffView: EPSignatureDelegate {
    func epSignature(_: EPSignatureViewController, didSign signatureImage: UIImage, boundingRect: CGRect) {
        if signatureRole == "returner" {
            returnerSIgnatureView.image = signatureImage
        } else  if signatureRole == "receiver" {
            receiverSignatureView.image = signatureImage
        }
    }
    
    func epSignature(_: EPSignatureViewController, didCancel error: NSError) {
    }
    
}

