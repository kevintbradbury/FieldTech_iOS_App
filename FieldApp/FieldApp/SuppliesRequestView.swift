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
    
    var employeeInfo: UserData.UserInfo?
    var materialsCollection: [FieldActions.MaterialQuantityColor]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        materialsTable.delegate = self
        materialsTable.dataSource = self
        
//        self.setDismissableKeyboard(vc: self)
        self.view.addGestureRecognizer(
            UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        )
    }
    
    @IBAction func addMaterialsCell(_ sender: Any) {
        let emptyMaterial = FieldActions.MaterialQuantityColor(quantity: 0, material: "material", color: "color")
        
        materialsCollection?.append(emptyMaterial)
        OperationQueue.main.addOperation { self.materialsTable.reloadData() }
    }
    
    @IBAction func goBack(_ sender: Any) { self.dismiss(animated: true, completion: nil) }
    
}

extension SuppliesRequestView: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let collection = materialsCollection else { return 1 }
        let count = (collection.count + 1)
        
        return count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "suppliesCell") as? SuppliesRequestCell else {
                return UITableViewCell()
        }
        
        if let collection: [FieldActions.MaterialQuantityColor] = materialsCollection,
            let material: FieldActions.MaterialQuantityColor = collection[indexPath.row] {
            cell.colorField.text = material.color
            cell.materialFIeld.text = material.material
            cell.quantityField.text = "\(material.quantity)"
        }
        
        return cell
    }
}
