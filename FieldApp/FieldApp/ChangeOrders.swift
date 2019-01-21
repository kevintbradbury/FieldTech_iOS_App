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
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var descripLabel: UILabel!
    @IBOutlet weak var locationText: UITextField!
    @IBOutlet weak var materialText: UITextField!
    @IBOutlet weak var colorSpecText: UITextField!
    @IBOutlet weak var quantityText: UITextField!
    @IBOutlet weak var datePickerFields: UIDatePicker!
    @IBOutlet weak var descripText: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    let employeeID = UserDefaults.standard.string(forKey: "employeeID")
    let todaysJobPO = UserDefaults.standard.string(forKey: "todaysJobPO")
    let employeeName = UserDefaults.standard.string(forKey: "employeeName")
    let picker = ImagePickerController()
    let tool_rental = "Tool Rental"
    let change_order = "Change Order"
    let supplies_request = "Supplies Request"
    
    public var formTypeVal = ""
    public var todaysJob: String?
    var changeOrder: FieldActions.ChangeOrders?
    var toolRentalForm: FieldActions.ToolRental?
    var suppliesRequestForm: FieldActions.SuppliesRequest?
    var materialsCollection: [FieldActions.SuppliesRequest.MaterialQuantityColor] = []
    var imageAssets: [UIImage] { return AssetManager.resolveAssets(picker.stack.assets) }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        datePickerFields.calendar = Calendar.current
        datePickerFields.timeZone = Calendar.current.timeZone
        datePickerFields.setValue(UIColor.white, forKey: "textColor")
        
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

            self.getTextVals() { co in
                
                if self.formTypeVal == self.tool_rental { self.generateToolForm(co: co) }
                else if self.formTypeVal == self.change_order { self.changeOrder = co }
                else if self.formTypeVal == self.supplies_request { self.generateSuppliesReqForm(co: co) }
                
                self.present(self.picker, animated: true)
            }

    }
    
    func setViews() {
        formType.text = formTypeVal
        requestedByLabel.text = employeeName
        poNumberLabel.text = todaysJobPO
        activityIndicator.hidesWhenStopped = true
        activityIndicator.isHidden = true
        
        setJobName()
        self.setDismissableKeyboard(vc: self)
        
        if formTypeVal == tool_rental {
            viewForToolRental()
        } else if self.formTypeVal == change_order {
            view.backgroundColor = #colorLiteral(red: 0.9219594598, green: 0.1295425594, blue: 0.2093265057, alpha: 1)
        } else if self.formTypeVal == supplies_request {
            viewForSuppliesReq()
        }
    }
    
    func setJobName() {
        let jobName = UserDefaults.standard.string(forKey: "todaysJobName")
        
        if todaysJob != nil && todaysJob != "" {
            jobNameLabel.text = todaysJob
        } else if jobName != nil && jobName != "" {
            jobNameLabel.text = jobName
        } else {
            jobNameLabel.text = "---"
        }
    }
    
    func getTextVals(callback: @escaping (FieldActions.ChangeOrders) -> ()) {
        guard let employee = employeeName,
            let po = todaysJobPO,
            let location = locationText.text,
            let secsFrom1970: Double = datePickerFields.date.timeIntervalSince1970,
            let descrip = descripText.text else {
                showAlert(withTitle: "Incomplete", message: String("The " + formTypeVal + " form is missing values.") )
                return
        }
        var changeOrderObj = FieldActions.ChangeOrders(
            formType: formTypeVal,
            jobName: "",
            poNumber: po,
            requestedBy: employee,
            location: location,
            material: "",
            colorSpec: "",
            quantity: 0.0,
            neededBy: secsFrom1970,
            description: descrip
        )
        if formTypeVal == change_order || formTypeVal == tool_rental {
            guard let material = materialText.text,
                let colorspec = colorSpecText.text,
                let quantity: Double = Double(quantityText.text!) else {
                    showAlert(withTitle: "Incomplete", message: String("The " + formTypeVal + " form is missing values.") )
                    return
            }
            
            changeOrderObj.material = material
            changeOrderObj.colorSpec = colorspec
            changeOrderObj.quantity = quantity
        }
        
        if todaysJob != nil && todaysJob != "" {
            changeOrderObj.jobName = todaysJob
            callback(changeOrderObj)
            
        } else if UserDefaults.standard.string(forKey: "todaysJobName") != "" {
            changeOrderObj.jobName = UserDefaults.standard.string(forKey: "todaysJobName")
            callback(changeOrderObj)
            
        } else {
            dismiss(animated: true, completion: nil)
            showAlert(withTitle: "Error", message: "Couldn't find a Job name for this form.")
        }
//        else if let employeeJobs = HomeView.employeeInfo?.employeeJobs {
//            for oneJob in employeeJobs {
//                if oneJob.poNumber == todaysJobPO {
//                    guard let jbName = oneJob.jobName as? String else { return }
//                    UserDefaults.standard.set(jbName, forKey: "todaysJobName")
//                    HomeView.todaysJob.jobName = jbName
//                    todaysJob = jbName
//                }
//            }
//            if todaysJob != nil && todaysJob != "" {
//                changeOrderObj.jobName = todaysJob
//                callback(changeOrderObj)
//            }
//        }
        
    }
    
    func generateToolForm(co: FieldActions.ChangeOrders) {
        let rentForm = FieldActions.ToolRental(
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
    
    func generateSuppliesReqForm(co: FieldActions.ChangeOrders) {
        let srForm = FieldActions.SuppliesRequest(
            formType: formTypeVal,
            jobName: todaysJob,
            poNumber: todaysJobPO,
            requestedBy: co.requestedBy,
            location: co.location,
            neededBy: co.neededBy,
            description: co.description,
            suppliesCollection: materialsCollection
        )
        suppliesRequestForm = srForm
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
        view.backgroundColor = UIColor.blue
        locationLabel.text = "Tool Type"
        materialLabel.text = "Brand"
        descripLabel.text = "Location"
        colorSpecLabel.text = "Duration"
        colorSpecText.placeholder = "Number of Days"
        colorSpecText.keyboardType = .numberPad
    }
    
    func viewForSuppliesReq() {
        view.backgroundColor = #colorLiteral(red: 0, green: 0.776924789, blue: 0.5073772073, alpha: 1)
        materialText.isHidden = true
        materialLabel.isHidden = true
        colorSpecLabel.isHidden = true
        colorSpecText.isHidden = true
        quantityLabel.isHidden = true
        quantityText.isHidden = true
    }
}

extension ChangeOrdersView: ImagePickerDelegate {
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        imagePicker.expandGalleryView()
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        let images = imageAssets
        
        if images.count < 2 {
            dismiss(animated: true, completion: nil)
            
            let alert = UIAlertController(
                title: "Confirm", message: "Are you sure you would like to send the \(formTypeVal)?", preferredStyle: UIAlertControllerStyle.alert
            )
            let yes = UIAlertAction(title: "YES", style: .default, handler: { action in
                self.sendCO(images: images)
            } )
            
            alert.addAction(yes)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        } else {
            picker.showAlert(withTitle: "Single Photo", message: "You can only select 1 photo for change orders.")
        }
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
    }
    
    func sendCO(images: [UIImage]) {
        activityIndicator.startAnimating()
        
        if let po = UserDefaults.standard.string(forKey: "todaysJobPO"),
            let emply =  UserDefaults.standard.string(forKey: "employeeName") {
            
            checkFormType(images: images, po: po, employee: emply)
        } else if let emply =  UserDefaults.standard.string(forKey: "employeeName") {
            checkFormType(images: images, po: "---", employee: emply)
        
        } else {
            activityIndicator.stopAnimating()
            showAlert(withTitle: "Error", message: "An employee name is required for COs, Tool Rentals, & Supplies Reqs.")
        };
    }
    
    func checkFormType(images: [UIImage], po: String, employee: String) {
        let route = "changeOrder/\(po)"
        var data = Data()
        
        if formTypeVal == tool_rental {
            guard let tlRent = toolRentalForm else { return }
            data = APICalls().generateTOOLstring(toolForm: tlRent)
            
        } else if formTypeVal == change_order {
            guard let co = changeOrder else { return }
            data = APICalls().generateCOstring(co: co)
            
        } else  if formTypeVal == supplies_request {
            guard let srForm = suppliesRequestForm else { return }
            data = APICalls().generateSRFstring(srForm: srForm)
        }
        
        APICalls().alamoUpload(route: route, headers: ["formType", formTypeVal], formBody: data, images: images, uploadType: "changeOrder") { responseType in
            self.activityIndicator.stopAnimating()
            self.handleResponseType(responseType: responseType)
        }
    }
    
}



