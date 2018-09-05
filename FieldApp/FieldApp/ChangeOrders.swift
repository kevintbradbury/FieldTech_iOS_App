//
//  ChangeOrders.swift
//  FieldApp
//
//  Created by MB Mac 3 on 9/3/18.
//  Copyright © 2018 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import NotificationCenter

class ChangeOrdersView: UIViewController {
    
    @IBOutlet weak var employeeNameTitle: UILabel!
    @IBOutlet weak var jobNameLabel: UILabel!
    @IBOutlet weak var poNumberLabel: UILabel!
    @IBOutlet weak var requestedByLabel: UILabel!
    @IBOutlet weak var locationText: UITextField!
    @IBOutlet weak var materialText: UITextField!
    @IBOutlet weak var colorSpecText: UITextField!
    @IBOutlet weak var quantityText: UITextField!
    @IBOutlet weak var needByText: UITextField!
    @IBOutlet weak var descripText: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    var todaysJob = UserDefaults.standard.string(forKey: "todaysJobName")
    let employeeID = UserDefaults.standard.string(forKey: "employeeID")
    let todaysJobPO = UserDefaults.standard.string(forKey: "todaysJobPO")
    let employeeName = UserDefaults.standard.string(forKey: "employeeName")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setViews()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    @IBAction func backAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func uploadCO(_ sender: Any) {
        view.frame.origin.y = 0

        getTextVals() { co in
            APICalls().sendChangeOrder(co: co)
        }
    }
    
    func setViews() {
        employeeNameTitle.text = employeeName
        requestedByLabel.text = employeeName
        poNumberLabel.text = todaysJobPO
        jobNameLabel.text = todaysJob
        
        self.view.addGestureRecognizer(
            UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        )
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    @objc func keyboardWillChange(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        if notification.name == Notification.Name.UIKeyboardWillShow || notification.name == Notification.Name.UIKeyboardWillChangeFrame {
            view.frame.origin.y = -(keyboardRect.height - 125)
        } else {
            view.frame.origin.y = 0
        }
    }
    
    func getTextVals(callback: @escaping (FieldActions.ChangeOrders) -> ()) {
        guard let employee = employeeName,
            let po = todaysJobPO,
            let location = locationText.text,
            let material = materialText.text,
            let colorspec = colorSpecText.text,
            let quantity = quantityText.text,
            let needBy = needByText.text,
            let descrip = descripText.text else {
                showAlert(withTitle: "Incomplete", message: "The Change Order form is missing values.")
                return
        }
        var changeOrderObj = FieldActions.ChangeOrders(
            jobName: "",
            poNumber: po,
            requestedBy: employee,
            location: location,
            material: material,
            colorSpec: colorspec,
            quantity: quantity,
            neededBy: needBy,
            description: descrip
        )
        
        if let job = todaysJob {
            changeOrderObj.jobName = job
            callback(changeOrderObj)
            
        } else if let theJobs = HomeView.employeeInfo?.employeeJobs {
            var job = ""
            
            for oneJob in theJobs {
                if oneJob.poNumber == todaysJobPO {
                    guard let jbName = oneJob.jobName as? String else { return }
                    UserDefaults.standard.set(jbName, forKey: "todaysJobName")
                    HomeView.todaysJob.jobName = jbName
                    job = jbName
                }
            }
            changeOrderObj.jobName = job
            callback(changeOrderObj)
            
        } else { callback(changeOrderObj) }
        
        
    }
    
}



