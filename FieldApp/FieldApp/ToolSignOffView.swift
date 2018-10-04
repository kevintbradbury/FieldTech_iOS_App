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
    
    public var toolToReturn: FieldActions.ToolRental?
    var signatureRole = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setGesturesAndViews()
        print("toolToReturn: ", toolToReturn)
    }
    
    @IBAction func goBack(_ sender: Any) { dismiss(animated: true, completion: nil) }
    @IBAction func returnerTap(_ sender: Any) { presentSignature(role: "returner") }
    @IBAction func receiverTap(_ sender: Any) { presentSignature(role: "receiver") }
    @IBAction func submitReturn(_ sender: Any) {
        showAlert(withTitle: "Send Return", message: "(under construction)")
        sendSignatures()
    }
    
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
        
        view.frame.origin.y = 0
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil
        )
    }
    
    func presentSignature(role: String) {
        signatureRole = role
        
        let signatureVC = EPSignatureViewController(signatureDelegate: self, showsDate: true)
        signatureVC.subtitleText = String("Tool \(role) sign your initials here.")
        signatureVC.title = "Initial Here"
        
        let nav = UINavigationController(rootViewController: signatureVC)
        present(nav, animated: true, completion: nil)
    }
    
    @objc func keyboardWillChange(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        if notification.name == Notification.Name.UIKeyboardWillShow || notification.name == Notification.Name.UIKeyboardWillChangeFrame {
            view.frame.origin.y = -(keyboardRect.height - 75)
        } else {
            view.frame.origin.y = 0
        }
    }
    
    func sendSignatures() {
        let dt = dateLabel.text
        let returnerSig = returnerSIgnatureView.image
        let returnerNm = printNameRenterField.text
        let receiverSig = receiverSignatureView.image
        let receiverNm = printNameReceiverField.text
        let rental = toolToReturn
        
        APICalls()
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
    
    func epSignature(_: EPSignatureViewController, didCancel error: NSError) {}
    
}
