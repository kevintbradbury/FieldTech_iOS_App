//
//  TimeOffRequestView.swift
//  FieldApp
//
//  Created by MB Mac 3 on 1/2/19.
//  Copyright © 2019 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import EPSignature


class TimeOffRequestView: UIViewController {
    @IBOutlet var userLabel: UILabel!
    @IBOutlet var userNameLbl: UILabel!
    @IBOutlet var departmentField: UITextField!
    @IBOutlet var shiftHrsField: UITextField!
    @IBOutlet var startDtPicker: UIDatePicker!
    @IBOutlet var endDtPicker: UIDatePicker!
    @IBOutlet var returnDtField: UITextField!
    @IBOutlet var signatureBtn: UIButton!
    @IBOutlet var signatureImg: UIImageView!
    @IBOutlet var sendBtn: UIButton!
    @IBOutlet var backBtn: UIButton!
    
    var employeeInfo: UserData.UserInfo?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setDismissableKeyboard(vc: self)
        
        if employeeInfo?.userName != nil {
            userNameLbl.text = employeeInfo?.userName
        }
    }
    
    @IBAction func goBack(_ sender: Any) { self.dismiss(animated: true, completion: nil) }
    @IBAction func sendTimeOffForm(_ sender: Any) { getTimeOffVals() }
    @IBAction func showSignatureView(_ sender: Any) { self.presentSignature(vc: self, subTitle: "Sign your name here", title: "Signature") }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    func getTimeOffVals() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        guard let username = employeeInfo?.userName,
            let id = employeeInfo?.employeeID,
            let deprtmt = departmentField.text,
            let shiftHours = shiftHrsField.text,
            let start = startDtPicker.date.timeIntervalSince1970 as? Double,
            let end = endDtPicker.date.timeIntervalSince1970 as? Double,
            let returnDtText = returnDtField.text,
            let signature = signatureImg.image,
            let currentDt =  dateFormatter.string(from: Date()) as? String,
            let returnDate = dateFormatter.date(from: returnDtText),
            let returnSecs = returnDate.timeIntervalSince1970 as? Double else {
                showAlert(withTitle: "Incomplete Form", message: "Please complete the entire form before submitting.")
                return
        }
        
        
        showAlert(
            withTitle: "get Time off vals",
            message: "\(username), \(id), \(deprtmt), \(shiftHours), \n\(returnDate), \n\(start), \n\(end)"
        )
        
//        let tmOffForm = TimeOffReq
    }
    
}

extension TimeOffRequestView: EPSignatureDelegate {
    func epSignature(_: EPSignatureViewController, didSign signatureImage: UIImage, boundingRect: CGRect) {
        self.signatureImg.image = signatureImage
    }
    
    func epSignature(_: EPSignatureViewController, didCancel error: NSError) {
        
    }
}
