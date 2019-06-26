//
//  SuppliesRequestView.swift
//  FieldApp
//
//  Created by MB Mac 3 on 1/7/19.
//  Copyright © 2019 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit

class SuppliesRequestView: UIViewController {
    
    @IBOutlet var backBtn: UIButton!
    @IBOutlet var materialsTable: UITableView!
    @IBOutlet var addMaterialBtn: UIButton!
    @IBOutlet var continueBtn: UIButton!
    
    let emptyMaterial = FieldActions.SuppliesRequest.MaterialQuantityColor(
        quantity: String(), material: String(), color: String(), width: String(), depth: String(), height: String()
    )
    
    var todaysJob: Job?
    var employeeInfo: UserData.UserInfo?
    var materialsCollection: [FieldActions.SuppliesRequest.MaterialQuantityColor] = [FieldActions.SuppliesRequest.MaterialQuantityColor(
        quantity: String(), material: String(), color: String(), width: String(), depth: String(), height: String()
        )]
    var indexToAdjust: Int = 0
    public static var jobCheckupInfo: Job.JobCheckupInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        materialsTable.delegate = self
        materialsTable.dataSource = self
        
        self.view.addGestureRecognizer(
            UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        checkForNotifUpdates()
    }
    
    @IBAction func addMaterialsCell(_ sender: Any) {
        
        if materialsCollection.count == materialsTable.numberOfRows(inSection: 0) {
            materialsCollection.append(emptyMaterial)
        }
        
        materialsTable.beginUpdates()
        materialsTable.insertRows(at: [IndexPath(row: 0, section: 0)], with: UITableView.RowAnimation.automatic)
        materialsTable.endUpdates()
    }
    
    @IBAction func goBack(_ sender: Any) { self.dismiss(animated: true, completion: nil) }
    
}

extension SuppliesRequestView: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.rowHeight = 180
        let count = materialsCollection.count
        return count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.separatorInset  = UIEdgeInsets(top: 100, left: 0, bottom: 100, right: 0)
        cell.layoutMarginsDidChange()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "suppliesCell") as? SuppliesRequestCell else {
            return UITableViewCell()
        }
        
        cell.materialFIeld.delegate = self
        cell.colorField.delegate = self
        cell.quantityField.delegate = self
        cell.widthField.delegate = self
        cell.heightField.delegate = self
        cell.depthField.delegate = self
        
        let existingIndx = materialsCollection.indices.contains(indexPath.row)
        
        if existingIndx == true && indexPath.row != 0 {
            let item = materialsCollection[indexPath.row]
            
            cell.materialFIeld.text = item.material
            cell.colorField.text = item.color
            cell.quantityField.text = item.quantity
            cell.widthField.text = item.width
            cell.depthField.text = item.depth
            cell.heightField.text = item.height
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            materialsTable.beginUpdates()
            
            if materialsCollection.indices.contains(indexPath.row) == true {
                materialsTable.deleteRows(at: [indexPath], with: UITableView.RowAnimation.left)
                materialsCollection.remove(at: indexPath.row)
            } else {
                guard let cell = materialsTable.dequeueReusableCell(withIdentifier: "suppliesCell", for: indexPath) as? SuppliesRequestCell else { return }
                cell.materialFIeld.text = nil
                cell.colorField.text = nil
                cell.quantityField.text = nil
                cell.widthField.text = nil
                cell.heightField.text = nil
                cell.depthField.text = nil
            }
            
            materialsTable.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        guard let indxPt: IndexPath = indexPath else { return }
    }
    
}

extension SuppliesRequestView: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        setMaterials()
    }
}

extension SuppliesRequestView {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "suppliesReqForm" {
            guard let vc = segue.destination as? ChangeOrdersView else { return }
            vc.materialsCollection = materialsCollection
            vc.formTypeVal = "Supplies Request"
            print("materialsCollection: \(materialsCollection)")
            
            if let jbNm = todaysJob?.jobName { vc.todaysJob = jbNm }
            if SuppliesRequestView.jobCheckupInfo != nil { ChangeOrdersView.jobCheckupInfo = SuppliesRequestView.jobCheckupInfo }
        }
    }
    
    func setMaterials() {
        var z = materialsTable.numberOfRows(inSection: 0) - 1
        
        for cell in materialsTable.visibleCells {
            
            guard let suppliesCell = cell as? SuppliesRequestCell,
                let color = suppliesCell.colorField.text,
                let material = suppliesCell.materialFIeld.text,
                let quantity = suppliesCell.quantityField.text else {
                    z -= 1; continue
            }
            let width = suppliesCell.widthField.text
            let depth = suppliesCell.depthField.text
            let height = suppliesCell.heightField.text
            
            if color == "" || quantity == "" || material == "" { z -= 1; continue }
            //            let selectedIndex = suppliesCell.panelOrLamType.selectedSegmentIndex
            //            let panelOrLam = suppliesCell.panelOrLamType.titleForSegment(at: selectedIndex)
            
            let existingIndx = materialsCollection.indices.contains(z)
            let oneMaterial = FieldActions.SuppliesRequest.MaterialQuantityColor(quantity: quantity, material: material, color: color, width: width, depth: depth, height: height)
            
            if existingIndx == true { materialsCollection[z] = oneMaterial }
            z -= 1
        }
    }
}


// -------
class SuppliesRequestCell: UITableViewCell {
    
    @IBOutlet var materialFIeld: UITextField!
    @IBOutlet var quantityField: UITextField!
    @IBOutlet var colorField: UITextField!
    @IBOutlet var widthField: UITextField!
    @IBOutlet var depthField: UITextField!
    @IBOutlet var heightField: UITextField!
    @IBOutlet var panelOrLamType: UISegmentedControl!
    
}
