//
//  ToolReturnView.swift
//  FieldApp
//
//  Created by MB Mac 3 on 9/26/18.
//  Copyright © 2018 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit

class ToolReturnView: UITableViewController {
    
    @IBOutlet var navBar: UINavigationBar!
    @IBOutlet var tableTitle: UINavigationItem!
    @IBOutlet var backButton: UIBarButtonItem!
    public var rentals: [FieldActions.ToolRental]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func goBack(_ sender: Any) { dismiss(animated: true, completion: nil) }
    
}

extension ToolReturnView {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rentalCount = 2
        
        if let unwrap = rentals,
            let count = unwrap.count as? Int {
            rentalCount = count
        }
        
        return rentalCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rentalCell", for: indexPath) as! ToolRentalReturnCell
        
        
        return cell
    }
    
    
}
