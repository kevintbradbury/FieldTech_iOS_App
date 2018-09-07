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
import ImagePicker

class ChangeOrdersView: UIViewController {
    
    @IBOutlet weak var employeeNameTitle: UILabel!
    @IBOutlet weak var jobNameLabel: UILabel!
    @IBOutlet weak var poNumberLabel: UILabel!
    @IBOutlet weak var requestedByLabel: UILabel!
    @IBOutlet weak var locationText: UITextField!
    @IBOutlet weak var materialText: UITextField!
    @IBOutlet weak var colorSpecText: UITextField!
    @IBOutlet weak var quantityText: UITextField!
    @IBOutlet weak var datePickerFields: UIDatePicker!
    @IBOutlet weak var needByText: UITextField!
    @IBOutlet weak var descripText: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    let employeeID = UserDefaults.standard.string(forKey: "employeeID")
    let todaysJobPO = UserDefaults.standard.string(forKey: "todaysJobPO")
    let employeeName = UserDefaults.standard.string(forKey: "employeeName")
    let picker = ImagePickerController()
    
    var todaysJob = "---"
    var changeOrder: FieldActions.ChangeOrders?
    var imageAssets: [UIImage] { return AssetManager.resolveAssets(picker.stack.assets) }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        datePickerFields.calendar = Calendar.current
        datePickerFields.timeZone = Calendar.current.timeZone
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
            self.changeOrder = co
            self.present(self.picker, animated: true)
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
        
        guard let jobName = UserDefaults.standard.string(forKey: "todaysJobName") as? String else { return }
        jobNameLabel.text = jobName
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
            let quantity: Double = Double(quantityText.text!),
            let secsFrom1970: Double = datePickerFields.date.timeIntervalSince1970,

//            let needBy: Date = getDate(dateText: needByText.text!),
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
            neededBy: secsFrom1970,
            description: descrip
        )
        
        if let job = todaysJob as? String {
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
    
    func getDate(dateText: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yy"     //      formatter.dateFormat = "h:mm a"
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Calendar.current.locale
        
        guard let date = formatter.date(from: dateText) else {
            print("failed to cast string to dateFormatter"); return Date()
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .year], from: date)
        guard let humanReadableDt = calendar.date(from: components) else {
            print("failed to cast calendar components to Date"); return Date()
        }
        
        return humanReadableDt
    }
}

extension ChangeOrdersView: ImagePickerDelegate {
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        print("wrapper did press")
        imagePicker.expandGalleryView()
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        let images = imageAssets
        
        if images.count < 2 {
            
            if let po = UserDefaults.standard.string(forKey: "todaysJobPO"),
                let emply =  UserDefaults.standard.string(forKey: "employeeName") {
                
                guard let co = changeOrder else { return }
                guard let imageData = UIImageJPEGRepresentation(images[0], 1) else { print("Couldn't get JPEG representation");  return }
                
                APICalls().sendPhoto(imageData: imageData, co: co) { response in
                    
                }
            } else {
                guard let co = changeOrder else { return }
                guard let imageData = UIImageJPEGRepresentation(images[0], 1) else { print("Couldn't get JPEG representation");  return }

                APICalls().sendPhoto(imageData: imageData, co: co) { response in
                    
                }
            };  dismiss(animated: true, completion: nil)
        } else {
            picker.showAlert(withTitle: "Single Photo", message: "You can only select 1 photo for change orders.")
        }
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
    }
    
}




