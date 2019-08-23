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
//    @IBOutlet var activityIndicator: UIActivityIndicatorView!
//    @IBOutlet var activityBckgd: UIView!
    
    public var toolToReturn: FieldActions.ToolRental?
    var signatureRole = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setGesturesAndViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        checkForNotifUpdates()
        returnerSIgnatureView.accessibilityIdentifier = "ToolSgn_returnerSIgnatureView"
        receiverSignatureView.accessibilityIdentifier = "ToolSgn_receiverSignatureView"
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
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
}

extension ToolSignOffView {
    
    @objc func thisKeyboardWillChange(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
            
            if self.printNameReceiverField.isFirstResponder == true {
                OperationQueue.main.addOperation {
                    self.view.frame.origin.y = -(keyboardRect.height - (keyboardRect.height / 4))
                }
            }
        } else {
            OperationQueue.main.addOperation {
                self.view.frame.origin.y = 0
            }
        }
    }
    
    func setThisDismissableKeyboard() {
        OperationQueue.main.addOperation {
            self.view.frame.origin.y = 0
            self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
            
            NotificationCenter.default.addObserver(
                self, selector: #selector(self.thisKeyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil
            )
            NotificationCenter.default.addObserver(
                self, selector: #selector(self.thisKeyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil
            )
            NotificationCenter.default.addObserver(
                self, selector: #selector(self.thisKeyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil
            )
        }
    }
    
    func setGesturesAndViews() {
        view.accessibilityIdentifier = "ToolSignOff View"
        dateLabel.accessibilityIdentifier = "ToolSgn_dateLabel"
        backBtn.accessibilityIdentifier = "backBtn"
        returnerBtn.accessibilityIdentifier = "ToolSgn_returnerBtn"
        printNameRenterField.accessibilityIdentifier = "ToolSgn_printNameRenterField"
        receiverBtn.accessibilityIdentifier = "ToolSgn_receiverBtn"
        printNameReceiverField.accessibilityIdentifier = "ToolSgn_printNameReceiverField"
        sendButton.accessibilityIdentifier = "ToolSgn_sendButton"
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, YYYY"
        dateLabel.text = dateFormatter.string(from: Date())
        
        setThisDismissableKeyboard()
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
        inProgress(showProgress: true)
        
        let dt = Date().timeIntervalSince1970,
        images = [returnerSig, receiverSig],
        printedNames = [returnerNm, receiverNm],
        jsonEncoder = JSONEncoder(),
        route = "toolReturn/\(employeeID)",
        headers = ["formType", "Tool Return"],
        returnObj = FieldActions.ToolReturn(rental: rental, signedDate: dt, printedNames: printedNames)
        var formBody = Data()
        
        do { formBody = try jsonEncoder.encode(returnObj) }
        catch { print("error converting ToolReturn to DATA", error); return }
        
        alamoUpload(route: route, headers: headers, formBody: formBody, images: images, uploadType: "toolReturn") { responseType in
            self.completeProgress()
            self.handleResponseType(responseType: responseType, formType: "Tool Return")
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

