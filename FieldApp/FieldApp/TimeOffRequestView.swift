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
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var employeeInfo: UserData.UserInfo?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setDismissableKeyboard(vc: self)
        activityIndicator.isHidden = true
        activityIndicator.hidesWhenStopped = true
        
        if employeeInfo?.userName != nil {
            userNameLbl.text = employeeInfo?.userName
        }
    }
    
    @IBAction func goBack(_ sender: Any) { self.dismiss(animated: true, completion: nil) }
    @IBAction func sendTimeOffForm(_ sender: Any) { getTimeOffVals() }
    @IBAction func showSignatureView(_ sender: Any) {
        self.presentSignature(vc: self, subTitle: "Sign your name here", title: "Signature")
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    func getTimeOffVals() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        guard let usrnm = employeeInfo?.userName,
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
        
        activityIndicator.startAnimating()
        let tmOffForm = TimeOffReq(
            username: usrnm, employeeID: id, department: dprtmt, shiftHours: shftHrs,
            start: start, end: end, signedDate: crrntDt
        )
        let jsonEncoder = JSONEncoder()
        let route = "employee/\(tmOffForm.employeeID)/timeOffReq"
        let headers = ["timeOffReq", "true"]
        var data = Data()
        
        do { data = try jsonEncoder.encode(tmOffForm) }
        catch { print(error.localizedDescription) };
        
        APICalls().alamoUpload(route: route, headers: headers, formBody: data, images: [signature], uploadType: "timeOffRequest") { success in
            self.activityIndicator.stopAnimating()
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
