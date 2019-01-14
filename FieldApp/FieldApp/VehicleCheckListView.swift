//
//  VehicleCheckListView.swift
//  FieldApp
//
//  Created by MB Mac 3 on 1/10/19.
//  Copyright © 2019 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import EPSignature

class VehicleCheckListView: UITableViewController {
    
    @IBOutlet var nameField: UITextField!
    @IBOutlet var signatureBtn: UIButton!
    @IBOutlet var departmentField: UITextField!
    @IBOutlet var licensePlateField: UITextField!
    @IBOutlet var dateLbl: UILabel!
    @IBOutlet var extWindowsSwitch: UISwitch!
    @IBOutlet var extTireSwitch: UISwitch!
    @IBOutlet var extEngineSwitch: UISwitch!
    @IBOutlet var extSignalsSwitch: UISwitch!
    @IBOutlet var extMirrors: UISwitch!
    @IBOutlet var extWindshieldSwitch: UISwitch!
    @IBOutlet var extDentSwitch: UISwitch!
    @IBOutlet var extCommentsField: UITextField!
    
    @IBOutlet var startupEngineSwitch: UISwitch!
    @IBOutlet var startupGaugeSwitch: UISwitch!
    @IBOutlet var startupWipersSWitch: UISwitch!
    @IBOutlet var startupHornSwitch: UISwitch!
    @IBOutlet var startupBrakesSwitch: UISwitch!
    @IBOutlet var startupSeatbeltsSwitch: UISwitch!
    @IBOutlet var startupInsuranceSwitch: UISwitch!
    @IBOutlet var startupFirstAidKitSwitch: UISwitch!
    @IBOutlet var startupCleanSwitch: UISwitch!
    @IBOutlet var startupComments: UITextField!
    
    @IBOutlet var maintenanceIssuesTxtField: UITextView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    let dateFormatter = DateFormatter()
    var currentDate = Date()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateFormat = "MMM d, yyyy"
        dateLbl.text = dateFormatter.string(from: currentDate)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.isHidden = true
        
        self.view.addGestureRecognizer(
            UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        )
    }
    
    @IBAction func pressedBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func pressedSignature(_ sender: Any) {
        self.presentSignature(vc: self, subTitle: "Sign your name here.", title: "Signature")
    }
    @IBAction func pressedSubmit(_ sender: Any) {
        confirmSubmit()
    }
    
    func getForm() -> FieldActions.VehicleChecklist {
        var vehicleForm: FieldActions.VehicleChecklist?
        
        if let name = nameField.text as? String,
            let department = departmentField.text as? String,
            let licenseNumber = licensePlateField.text as? String,
            let extWindows = extWindowsSwitch.isOn as? Bool,
            let extTire = extTireSwitch.isOn as? Bool,
            let extEngine = extEngineSwitch.isOn as? Bool,
            let extSignals = extSignalsSwitch.isOn as? Bool,
            let extMirr = extMirrors.isOn as? Bool,
            let extWindshd = extWindshieldSwitch.isOn as? Bool,
            let extDents = extDentSwitch.isOn as? Bool,
            let extCommts = extCommentsField.text as? String,
            let startEngine = startupEngineSwitch.isOn as? Bool,
            let startGauge = startupGaugeSwitch.isOn as? Bool,
            let startWiper = startupWipersSWitch.isOn as? Bool,
            let startHorn = startupHornSwitch.isOn as? Bool,
            let startBrake = startupBrakesSwitch.isOn as? Bool,
            let startSeatbt = startupSeatbeltsSwitch.isOn as? Bool,
            let startInsurance = startupInsuranceSwitch.isOn as? Bool,
            let startFirstAid = startupFirstAidKitSwitch.isOn as? Bool,
            let startClean = startupCleanSwitch.isOn as? Bool,
            let startCommts = startupComments.text,
            let issuesCmmts = maintenanceIssuesTxtField.text {
            
            let outsideInspect = FieldActions.VehicleChecklist.OutsideInspection(windows: extWindows, tiresNnuts: extTire, engine: extEngine, litesNsignals: extSignals, mirrors: extMirr, windshieldNwipres: extWindshd, dents: extDents, exteriorComments: extCommts)
            let startupInspect = FieldActions.VehicleChecklist.StartupInspection(engine: startEngine, gauges: startGauge, wipers: startWiper, horn: startHorn, brakes: startBrake, seatbelt: startSeatbt, insuranceNregist: startInsurance, firstAidKit: startFirstAid, clean: startClean, startupComments: startCommts)
            vehicleForm = FieldActions.VehicleChecklist(username: name, department: department, licensePlate: licenseNumber, date: currentDate.timeIntervalSince1970, outsideInspection: outsideInspect, startupInspection: startupInspect, issuesReport: issuesCmmts)
            
        }
        guard let uwrappedForm =  vehicleForm as? FieldActions.VehicleChecklist else {
            return FieldActions.VehicleChecklist(
                username: "",department: "",licensePlate: "",date: Date().timeIntervalSince1970,
                outsideInspection: FieldActions.VehicleChecklist.OutsideInspection(windows: false,tiresNnuts: false,engine: false,litesNsignals: false,mirrors: false,windshieldNwipres: false,dents: false,exteriorComments: ""),
                startupInspection: FieldActions.VehicleChecklist.StartupInspection(engine: false, gauges: false, wipers: false, horn: false, brakes: false, seatbelt: false, insuranceNregist: false, firstAidKit: false, clean: false, startupComments: ""),
                issuesReport: "")
        }
        
        return uwrappedForm
    }

    func confirmSubmit() {
        let alert = UIAlertController(title: "Confirm", message: "Submit Vehicle Inspection Form?", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        let yes = UIAlertAction(title: "YES", style: .default) { action in  self.sendForm() }
        
        alert.addAction(yes)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func sendForm() {
        activityIndicator.startAnimating()
        
        guard let signatureImg = signatureBtn.currentImage,
            let employeeID = UserDefaults.standard.string(forKey: "employeeID") else { return }
        let vehicleFm = getForm()
        let route = "vehicleCheckList/\(employeeID)"
        let encoder = JSONEncoder()
        var data = Data()
        
        do { data = try encoder.encode(vehicleFm) }
        catch { print(error.localizedDescription) }
        
        print(vehicleFm, signatureImg)
        
        APICalls().alamoUpload(
            route: route, headers: ["vehiclechecklist", "true" ], formBody: data, images: [signatureImg], uploadType: "vehicleCheckList"
        ) { success in
            self.activityIndicator.stopAnimating()
        }
    }
}

extension VehicleCheckListView: EPSignatureDelegate {
    func epSignature(_: EPSignatureViewController, didSign signatureImage: UIImage, boundingRect: CGRect) {
        signatureBtn.setImage(signatureImage, for: UIControlState.normal)
    }
}
