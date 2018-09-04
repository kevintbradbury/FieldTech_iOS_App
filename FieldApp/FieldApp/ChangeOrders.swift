//
//  ChangeOrders.swift
//  FieldApp
//
//  Created by MB Mac 3 on 9/3/18.
//  Copyright © 2018 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit

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
    
    let employeeName = UserDefaults.standard.string(forKey: "employeeName")
    let employeeID = UserDefaults.standard.string(forKey: "employeeID")
    let todaysJobPO = UserDefaults.standard.string(forKey: "todaysJobPO")
    var todaysJob: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setViews()
    }
    
    @IBAction func backAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func uploadCO(_ sender: Any) {
        let co = getTextVals()
        APICalls().sendChangeOrder(co: co)
    }
//    @IBAction func superviewTap(_ sender: Any) {
//        self.resignFirstResponder()
//    }
    
    func setViews() {
        employeeNameTitle.text = employeeName
        requestedByLabel.text = employeeName
        jobNameLabel.text = todaysJob
        poNumberLabel.text = todaysJobPO
        
        for textField in self.view.subviews where textField is UITextField {
            textField.resignFirstResponder()
        }
    }
    
    func getTextVals() -> FieldActions.ChangeOrders {
        guard let job = jobNameLabel.text,
            let po = todaysJobPO,
            let employee = employeeName,
            let location = locationText.text,
            let material = materialText.text,
            let colorspec = colorSpecText.text,
            let quantity = quantityText.text,
            let needBy = needByText.text,
            let descrip = descripText.text else { return FieldActions.ChangeOrders() }
        
        let changeOrderObj = FieldActions.ChangeOrders(
            jobName: job,
            poNumber: po,
            requestedBy: employee,
            location: location,
            material: material,
            colorSpec: colorspec,
            quantity: quantity,
            neededBy: needBy,
            description: descrip
        )
        return changeOrderObj
    }
    
}



