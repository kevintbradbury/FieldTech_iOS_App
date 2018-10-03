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
    
    @IBOutlet weak var formType: UILabel!
    @IBOutlet weak var jobNameLabel: UILabel!
    @IBOutlet weak var poNumberLabel: UILabel!
    @IBOutlet weak var requestedByLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var materialLabel: UILabel!
    @IBOutlet var colorSpecLabel: UILabel!
    @IBOutlet var descripLabel: UILabel!
    @IBOutlet weak var locationText: UITextField!
    @IBOutlet weak var materialText: UITextField!
    @IBOutlet weak var colorSpecText: UITextField!
    @IBOutlet weak var quantityText: UITextField!
    @IBOutlet weak var datePickerFields: UIDatePicker!
    @IBOutlet weak var descripText: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    let employeeID = UserDefaults.standard.string(forKey: "employeeID")
    let todaysJobPO = UserDefaults.standard.string(forKey: "todaysJobPO")
    let employeeName = UserDefaults.standard.string(forKey: "employeeName")
    let picker = ImagePickerController()
    let tool_rental = "Tool Rental"
    
    public var formTypeVal = ""
    public var todaysJob: String?
    var changeOrder: FieldActions.ChangeOrders?
    var toolRentalForm: FieldActions.ToolRental?
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
            
            if self.formTypeVal == self.tool_rental {
                self.generateToolForm(co: co)
                
            } else {
                self.changeOrder = co
            }
            
            self.present(self.picker, animated: true)
        }
    }
    
    func setViews() {
        formType.text = formTypeVal
        requestedByLabel.text = employeeName
        poNumberLabel.text = todaysJobPO
        
        setGestures()
        setJobName()
        
        if formTypeVal == tool_rental { viewForToolRental() }
    }
    
    func setGestures() {
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
    
    func setJobName() {
        let jobName = UserDefaults.standard.string(forKey: "todaysJobName")
        
        if todaysJob != "" && todaysJob != nil {
            jobNameLabel.text = todaysJob
        } else if jobName != nil {
            jobNameLabel.text = jobName
        } else {
            jobNameLabel.text = "---"
        }
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
            let descrip = descripText.text else {
                showAlert(withTitle: "Incomplete", message: "The Change Order form is missing values.")
                return
        }
        var changeOrderObj = FieldActions.ChangeOrders(
            formType: formTypeVal,
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
    
    func generateToolForm(co: FieldActions.ChangeOrders) {
        var rentForm = FieldActions.ToolRental(
            formType: co.formType,
            jobName: co.jobName,
            poNumber: co.poNumber,
            requestedBy: co.requestedBy,
            toolType: co.location,
            brand: co.material,
            duration: Int(co.colorSpec!),
            quantity: co.quantity,
            neededBy: co.neededBy,
            location: co.description
        )
        
        toolRentalForm = rentForm
    }
    
    func getDate(dateText: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yy"
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
    
    func viewForToolRental() {
        locationLabel.text = "Tool Type"
        materialLabel.text = "Brand"
        descripLabel.text = "Location"
        colorSpecLabel.text = "Duration"
        colorSpecText.placeholder = "Number of Days"
        colorSpecText.keyboardType = .numberPad
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
            sendCO(images: images)
        } else {
            picker.showAlert(withTitle: "Single Photo", message: "You can only select 1 photo for change orders.")
        }
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
    }
    
    func sendCO(images: [UIImage]) {
        guard let imageData = UIImageJPEGRepresentation(images[0], 1) else {
            print("Couldn't get JPEG representation");  return
        }
        
        if let po = UserDefaults.standard.string(forKey: "todaysJobPO"),
            let emply =  UserDefaults.standard.string(forKey: "employeeName") {
            
            checkFormTyp(imageData: imageData, po: po, employee: emply)
        } else if let emply =  UserDefaults.standard.string(forKey: "employeeName") {
            checkFormTyp(imageData: imageData, po: "---", employee: emply)
        } else {
            showAlert(withTitle: "Error", message: "An employee name is required for COs, Tool Rentals, & Supplies Reqs.")
        };
        dismiss(animated: true, completion: nil)
    }
    
    func checkFormTyp(imageData: Data, po: String, employee: String) {

        if formTypeVal == tool_rental {
            guard let tlRent = toolRentalForm else { return }
            let formBody = APICalls().generateTOOLstring(toolForm: tlRent)
            
            APICalls().sendChangeOrderReq(imageData: imageData, formType: "Tool Rental", formBody: formBody, po: po) { response in
                
            }
            
        } else {
            guard let co = changeOrder else { return }
            let formBody = APICalls().generateCOstring(co: co)
            
            APICalls().sendChangeOrderReq(imageData: imageData, formType: co.formType!, formBody: formBody, po: po) { response in
                
            }
        }
    }
    
}



