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
    
    public var employeeID: Int?
    var rentals = [FieldActions.ToolRental]()
    var images = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        APICalls().getToolRentals(employeeID: employeeID!) { toolsNimgs in
            self.rentals = toolsNimgs.tools
            self.images = toolsNimgs.images
            self.tableView.reloadData()
        }
    }
    
    @IBAction func goBack(_ sender: Any) { dismiss(animated: true, completion: nil) }
    
}

extension ToolReturnView {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rentalCount = 1
        
        if let unwrap = rentals as? [FieldActions.ToolRental],
            let count = unwrap.count as? Int {
            rentalCount = count
        }
        
        return rentalCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rentalCell", for: indexPath) as! ToolRentalReturnCell
        let index = Int(indexPath.item)
        
        if let img = images[index] as? UIImage,
            let toolName = rentals[index].toolType as? String {
            cell.toolImg.image = img
            cell.toolInfoLabel.text = toolName
            cell.activityIndicator.hidesWhenStopped = true
            cell.activityIndicator.stopAnimating()
        } else {
            cell.activityIndicator.startAnimating()
        }

        return cell
    }
    
    
}
