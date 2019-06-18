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
    @IBOutlet var poNumberField: UITextField!
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
    @IBOutlet var activityBckgrd: UIView!
    
    let employeeID = UserDefaults.standard.string(forKey: "employeeID")
    let todaysJobPO = UserDefaults.standard.string(forKey: "todaysJobPO")
    let employeeName = UserDefaults.standard.string(forKey: "employeeName")
    let picker = ImagePickerController()
    let tool_rental = "Tool Rental"
    let change_order = "Change Order"
    let supplies_request = "Supplies Request"
    
    public var formTypeVal = "", todaysJob: String?
    
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
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        checkForNotifUpdates()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
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
    
    @objc func thisKeyboardWillChange(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
            print(notification.name)
            
            if self.descripText.isFirstResponder == true {
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
    
    func setViews() {
        descripText.text = ""
        formType.text = formTypeVal
        requestedByLabel.text = employeeName
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.isHidden = true
        activityBckgrd.isHidden = true
        
        setJobName()
        setThisDismissableKeyboard()
        
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
        let chosenDate = datePickerFields.date.timeIntervalSince1970
        let now = Date().timeIntervalSince1970 - (60 * 60 * 12)
        
        if chosenDate < now {
            showAlert(withTitle: "Date Error", message: "Can't pick a date earlier than today."); return
        }
        
        guard let employee = employeeName,
            let po = poNumberField.text,
            let location = locationText.text,
            let descrip = descripText.text else {
                showAlert(withTitle: "Incomplete", message: String("The " + formTypeVal + " form is missing values.") )
                return
        }
        todaysJob = po
        var changeOrderObj = FieldActions.ChangeOrders(
            formType: formTypeVal,
            jobName: "",
            poNumber: po,
            requestedBy: employee,
            location: location,
            material: "",
            colorSpec: "",
            quantity: 0.0,
            neededBy: chosenDate,
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
        backButton.setTitleColor(UIColor.white, for: UIControl.State.normal)
        
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
        
        if formTypeVal == supplies_request {
            if images.count >= materialsCollection.count {
                dismiss(animated: true, completion: nil)
                
                let alert = UIAlertController(title: "Confirm", message: "Are you sure you would like to send the \(formTypeVal)?", preferredStyle: UIAlertController.Style.alert)
                let yes = UIAlertAction(title: "YES", style: .default, handler: { action in self.sendCO(images: images) })
                
                alert.addAction(yes)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                picker.showAlert(withTitle: "More Photos", message: "You must take at least \(materialsCollection.count) photos for each piece of material.")
            }
            
        } else if images.count < 2 {
            dismiss(animated: true, completion: nil)
            
            let alert = UIAlertController(title: "Confirm", message: "Are you sure you would like to send the \(formTypeVal)?", preferredStyle: UIAlertController.Style.alert)
            let yes = UIAlertAction(title: "YES", style: .default, handler: { action in self.sendCO(images: images) })
            
            alert.addAction(yes)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        } else {
            picker.showAlert(withTitle: "Single Photo", message: "You can only select 1 photo for \(formType).")
        }
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func sendCO(images: [UIImage]) {
        inProgress(activityBckgd: activityBckgrd, activityIndicator: activityIndicator, showProgress: true)
        
        if let po = UserDefaults.standard.string(forKey: "todaysJobPO"),
            let emply =  UserDefaults.standard.string(forKey: "employeeName") {
            
            checkFormType(images: images, po: po, employee: emply)
        } else if let emply =  UserDefaults.standard.string(forKey: "employeeName"),
            let poNum = todaysJob {
            checkFormType(images: images, po: poNum, employee: emply)
        
        } else {
            completeProgress(activityBckgd: activityBckgrd, activityIndicator: activityIndicator)
            showAlert(withTitle: "Error", message: "An employee name or PO number is required for COs, Tool Rentals, & Supplies Reqs.")
        };
    }
    
    func checkFormType(images: [UIImage], po: String, employee: String) {
        let route = "changeOrder/\(po)", jsonEncoder = JSONEncoder()
        var data = Data()
        
        if formTypeVal == tool_rental {
            guard let toolRental = toolRentalForm else { return }
            
            do { data = try jsonEncoder.encode(toolRental) }
            catch { print("error converting \(formTypeVal) to DATA: \(error)"); return }
            
        } else if formTypeVal == change_order {
            guard let co = changeOrder else { return }
            
            do { data = try jsonEncoder.encode(co) }
            catch { print("error converting \(formTypeVal) to DATA: \(error)"); return }
            
        } else  if formTypeVal == supplies_request {
            guard let srForm = suppliesRequestForm else { return }
            
            do { data = try jsonEncoder.encode(srForm) }
            catch { print("error converting \(formTypeVal) to DATA: \(error)"); return }
        }
        
        alamoUpload(route: route, headers: ["formType", formTypeVal], formBody: data, images: images, uploadType: "changeOrder") { responseType in
            let resType = responseType
            self.completeProgress(activityBckgd: self.activityBckgrd, activityIndicator: self.activityIndicator)
            self.handleResponseType(responseType: resType, formType: self.formTypeVal)
        }
    }
    
}



