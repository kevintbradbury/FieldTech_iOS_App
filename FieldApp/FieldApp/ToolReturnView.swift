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
        tableView.reloadData()
        
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
        let toolRntl = rentals[index]
        
        if let img = images[index] as? UIImage,
            let toolName = toolRntl.toolType,
            let brand = toolRntl.brand,
            let jobNm = toolRntl.jobName,
            let rentDt = toolRntl.neededBy,
            let secs = rentDt as? TimeInterval {
            
            let dt = Date(timeIntervalSince1970: secs)
            let dtReadable = ScheduleView().getMonthDayYear(date: dt)
            let txt = String(jobNm + "\n" + brand + ": " + toolName + "\n" + "Rental Date: " + dtReadable)
            
            cell.toolImg.image = img
            cell.toolInfoLabel.text = txt
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = Int(indexPath.item)
        let toolRntl = rentals[index]
        
        if let img = images[index] as? UIImage,
            let toolName = toolRntl.toolType,
            let brand = toolRntl.brand,
            let jobNm = toolRntl.jobName,
            let rentDt = toolRntl.neededBy,
            let secs = rentDt as? TimeInterval {
            
            let dt = Date(timeIntervalSince1970: secs)
            let dtReadable = ScheduleView().getMonthDayYear(date: dt)
            
            showRentalDetails(jobName: jobNm, tool: toolName, returnDate: dtReadable)
        }
    }
}

extension ToolReturnView {
    func showRentalDetails(jobName: String, tool: String, returnDate: String) {
        let msg = jobName + "\n" + tool + ": " + returnDate
        let alert = UIAlertController(
            title: "Confirm Tool Return",
            message: msg,
            preferredStyle: .alert
        )
        
        let returnTool = UIAlertAction(title: "YES", style: .default) { action in
//            self.performSegue(withIdentifier: "toolSignOff", sender: nil)
        }
        let cancel = UIAlertAction(title: "NO", style: .destructive)
        
        alert.addAction(returnTool)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
}
