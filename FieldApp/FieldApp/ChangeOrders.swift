//
//  ChangeOrders.swift
//  FieldApp
//
//  Created by MB Mac 3 on 9/3/18.
//  Copyright © 2018 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit

class ChangeOrders: UIViewController {
    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func backAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
