//
//  TORLogView.swift
//  FieldApp
//
//  Created by MB Mac 3 on 1/22/19.
//  Copyright © 2019 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit

class TORLogView: UITableViewController {
    
    @IBOutlet var backBtn: UIBarButtonItem!
    
    let formatter = DateFormatter()
    var timeOffReqs: [TimeOffReq]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatter.dateFormat = "MMM dd, yyyy"
        tableView.allowsSelection = false
        
        if timeOffReqs?.count == 0 {
            showAlert(withTitle: "No Requests", message: "No time off requests.")
        }
    }
    
    @IBAction func goBack(_ sender: Any) { dismiss(animated: true, completion: nil) }
    
    override func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let safeAry = timeOffReqs else { return 1 }
        return safeAry.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let safeAry = timeOffReqs,
            var cell = tableView.dequeueReusableCell(withIdentifier: "torLogCell", for: indexPath) as? TORLogTableCell else {
                return TORLogTableCell()
        }
        let tOR = safeAry[indexPath.row]
        let start = formatter.string(from: Date(timeIntervalSince1970: tOR.start))
        let end = formatter.string(from: Date(timeIntervalSince1970: tOR.end))
        let aprv = changeToYesNo(approved: tOR.approved)
        let txt = "\(start) - \(end) \nApproved: \(aprv)"
        
        cell.infoLabel.text = txt
        
        return cell
    }
    
    func changeToYesNo(approved: Bool?) -> String {
        guard let aprv = approved else { return "(TBD)" }
        
        if aprv == true { return "yes" }
        else if aprv == false { return "no" }
        else { return "(TBD)" }
    }
}


class TORLogTableCell: UITableViewCell {
    
    @IBOutlet var infoLabel: UILabel!
    
}
