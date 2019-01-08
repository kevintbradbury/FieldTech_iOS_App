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
    var materialsCollection: [FieldActions.MaterialQuantityColor] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        materialsTable.delegate = self
        materialsTable.dataSource = self
        
        self.view.addGestureRecognizer(
            UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        )
    }
    
    @IBAction func addMaterialsCell(_ sender: Any) {
        let emptyMaterial = FieldActions.MaterialQuantityColor(quantity: Double(), material: String(), color: String())
        
        materialsCollection.append(emptyMaterial)
        
        materialsTable.beginUpdates()
        materialsTable.insertRows(at: [IndexPath(row: 0, section: 0)], with: UITableViewRowAnimation.automatic)
        materialsTable.endUpdates()
    }
    
    @IBAction func goBack(_ sender: Any) { self.dismiss(animated: true, completion: nil) }
    
}

extension SuppliesRequestView: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = (materialsCollection.count + 1)
        return count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "suppliesCell") as? SuppliesRequestCell else {
                return UITableViewCell()
        }
        let existingIndx = materialsCollection.indices.contains(indexPath.row)
        
        if existingIndx == true, let material: FieldActions.MaterialQuantityColor = materialsCollection[indexPath.row] {
            cell.colorField.text = material.color
            cell.materialFIeld.text = material.material
            if material.quantity > 0 {
                cell.quantityField.text = "\(material.quantity)"
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            materialsTable.beginUpdates()
            
            if materialsCollection.indices.contains(indexPath.row) == true { materialsCollection.remove(at: indexPath.row) }
            else { materialsTable.endUpdates(); return }
            
            materialsTable.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
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
            let dbl: Double = Double(quantity) ?? 0
            
            materialsCollection[indxPt.row] = FieldActions.MaterialQuantityColor(quantity: dbl, material: material, color: color)
        }
    }
}

extension SuppliesRequestView {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        var z = 0
        for cell in materialsTable.visibleCells {
            
            guard let suppliesCell = cell as? SuppliesRequestCell,
                let color = suppliesCell.colorField.text,
                let material = suppliesCell.materialFIeld.text,
                let quantity = suppliesCell.quantityField.text else { return }
            let dbl: Double = Double(quantity) ?? 0
            let existingIndx = materialsCollection.indices.contains(z)
            
            if existingIndx == true {
                materialsCollection[z] = FieldActions.MaterialQuantityColor(quantity: dbl, material: material, color: color)
            } else {
                materialsCollection.append(FieldActions.MaterialQuantityColor(quantity: dbl, material: material, color: color))
            }
            z += 1
        }
        
        if segue.identifier == "suppliesReqForm" {
            guard let destn = segue.destination as? ChangeOrdersView else { return }
            destn.materialsCollection = materialsCollection
            destn.formTypeVal = "Supplies Request"
            print("materialsCollection: \(materialsCollection)")
            
            if todaysJob?.jobName != nil && todaysJob?.jobName != "" { destn.todaysJob = todaysJob?.jobName }
        }
    }
    
}