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
    @IBOutlet var signatureBtn: UIButton!
    @IBOutlet var signatureImg: UIImageView!
    @IBOutlet var sendBtn: UIButton!
    @IBOutlet var backBtn: UIButton!
//    @IBOutlet var activityIndicator: UIActivityIndicatorView!
//    @IBOutlet var activityBckgrd: UIView!
    
    var employeeInfo: UserData.UserInfo?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        activityIndicator.isHidden = true
//        activityIndicator.hidesWhenStopped = true
//        activityBckgrd.isHidden = true
        backBtn.accessibilityIdentifier = "backBtn"
        
        if employeeInfo?.username != nil {
            userNameLbl.text = employeeInfo?.username
        }
        OperationQueue.main.addOperation {
            self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        checkForNotifUpdates()
    }
    
    @IBAction func goBack(_ sender: Any) { self.dismiss(animated: true, completion: nil) }
    @IBAction func sendTimeOffForm(_ sender: Any) { getTimeOffVals() }
    @IBAction func showSignatureView(_ sender: Any) {
        self.presentSignature(vc: self, subTitle: "Sign your name here", title: "Signature")
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    func getTimeOffVals() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        guard let usrnm = employeeInfo?.username,
            let id = employeeInfo?.employeeID,
            let dprtmt = departmentField.text,
            let shftHrs = shiftHrsField.text,
            let start = startDtPicker.date.timeIntervalSince1970 as? Double,
            let end = endDtPicker.date.timeIntervalSince1970 as? Double,
            let signature = signatureImg.image,
            let crrntDt =  Date().timeIntervalSince1970 as? Double else {
                showAlert(withTitle: "Incomplete Form", message: "Please complete the entire form before submitting.")
                return
        }
        
        inProgress(showProgress: false)
        
        let tmOffForm = TimeOffReq(
            username: usrnm, employeeID: id, department: dprtmt, shiftHours: shftHrs,
            start: start, end: end, signedDate: crrntDt, approved: nil
        )
        let jsonEncoder = JSONEncoder()
        let route = "employee/\(tmOffForm.employeeID)/timeOffReq"
        let headers = ["timeOffReq", "true"]
        var data = Data()
        
        do { data = try jsonEncoder.encode(tmOffForm) }
        catch { print(error.localizedDescription) };
        
        alamoUpload(route: route, headers: headers, formBody: data, images: [signature], uploadType: "timeOffRequest") { responseType in

            self.completeProgress()
            self.handleResponseType(responseType: responseType, formType: "Time Off Request")
        }
    }
    
}

extension TimeOffRequestView: EPSignatureDelegate {
    func epSignature(_: EPSignatureViewController, didSign signatureImage: UIImage, boundingRect: CGRect) {
        self.signatureBtn.isHidden = true
        self.signatureImg.image = signatureImage
    }
    
    func epSignature(_: EPSignatureViewController, didCancel error: NSError) {
        
    }
}
