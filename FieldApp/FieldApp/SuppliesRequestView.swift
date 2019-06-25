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
    
    var todaysJob: Job?
    var employeeInfo: UserData.UserInfo?
    var materialsCollection: [FieldActions.SuppliesRequest.MaterialQuantityColor] = []
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
        let emptyMaterial = FieldActions.SuppliesRequest.MaterialQuantityColor(
            quantity: String(), material: String(), color: String(), width: String(), depth: String(), height: String(), panelOrLam: String()
        )
        
        materialsCollection.append(emptyMaterial)
        
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
        let count = (materialsCollection.count + 1)
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
        let existingIndx = materialsCollection.indices.contains(indexPath.row)
        
        if existingIndx == true {
            let material = materialsCollection[indexPath.row]
            
            cell.colorField.text = material.color
            cell.materialFIeld.text = material.material
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            materialsTable.beginUpdates()
            
            if materialsCollection.indices.contains(indexPath.row) == true { materialsCollection.remove(at: indexPath.row) }
            else { materialsTable.endUpdates(); return }
            
            materialsTable.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            materialsTable.endUpdates()
        }
    }
    
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        guard let indxPt: IndexPath = indexPath else { return }
        let existingIndx = materialsCollection.indices.contains(indxPt.row)
        
        if existingIndx == true {
            guard let cell = materialsTable.cellForRow(at: indxPt) as? SuppliesRequestCell,
                let color = cell.colorField.text,
                let material = cell.materialFIeld.text,
                let quantity = cell.quantityField.text else { return }
                let width = cell.widthField.text ?? ""
                let depth = cell.depthField.text ?? ""
                let height = cell.heightField.text ?? ""
            
            let selectedIndex = cell.panelOrLamType.selectedSegmentIndex
            let panelOrLam = cell.panelOrLamType.titleForSegment(at: selectedIndex)
            
            materialsCollection[indxPt.row] = FieldActions.SuppliesRequest.MaterialQuantityColor(
                quantity: quantity, material: material, color: color, width: width, depth: depth, height: height, panelOrLam: panelOrLam
            )
        }
    }
}

extension SuppliesRequestView {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let allRows = materialsTable.numberOfRows(inSection: 1) - 1
        var z = 0
        
        for i in 0...allRows {
            let indxPath = IndexPath(row: i, section: 1)
            let cell = materialsTable.cellForRow(at: indxPath)
            
            guard let suppliesCell = cell as? SuppliesRequestCell,
                let color = suppliesCell.colorField.text,
                let material = suppliesCell.materialFIeld.text,
                let quantity = suppliesCell.quantityField.text else { return }
                let width = suppliesCell.widthField.text ?? ""
                let depth = suppliesCell.depthField.text ?? ""
                let height = suppliesCell.heightField.text ?? ""
            
            let selectedIndex = suppliesCell.panelOrLamType.selectedSegmentIndex
            let panelOrLam = suppliesCell.panelOrLamType.titleForSegment(at: selectedIndex)
            let existingIndx = materialsCollection.indices.contains(z)
            
            if existingIndx == true {
                materialsCollection[z] = FieldActions.SuppliesRequest.MaterialQuantityColor(quantity: quantity, material: material, color: color, width: width, depth: depth, height: height, panelOrLam: panelOrLam)
            } else {
                materialsCollection.append(FieldActions.SuppliesRequest.MaterialQuantityColor(quantity: quantity, material: material, color: color, width: width, depth: depth, height: height, panelOrLam: panelOrLam))
            }
            z += 1
        }
        
        if segue.identifier == "suppliesReqForm" {
            guard let vc = segue.destination as? ChangeOrdersView else { return }
            vc.materialsCollection = materialsCollection
            vc.formTypeVal = "Supplies Request"
            print("materialsCollection: \(materialsCollection)")
            
            if let jbNm = todaysJob?.jobName { vc.todaysJob = jbNm }
            if SuppliesRequestView.jobCheckupInfo != nil { ChangeOrdersView.jobCheckupInfo = SuppliesRequestView.jobCheckupInfo }
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
