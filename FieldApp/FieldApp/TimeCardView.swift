//
//  TimeCardView.swift
//  FieldApp
//
//  Created by MB Mac 3 on 8/21/19.
//  Copyright © 2019 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import EPSignature


class TimeCardView: UIViewController {
    @IBOutlet var employeeLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var dateStepper: UIStepper!
    @IBOutlet var timeCardTable: UITableView!
    @IBOutlet var signatureImg: UIImageView!
    @IBOutlet var signatureBtn: UIButton!
    @IBOutlet var confirmBtn: UIButton!
    
    public static var employeeInfo: UserData.UserInfo?
    var date = Date()
    var timesheet: UserData.TimeCard?
    
    let dateFormatter = DateFormatter()
    let daysOweek = [ "sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timeCardTable.delegate = self
        timeCardTable.dataSource = self
        
        dateFormatter.dateFormat = "MM-dd-yy"
        dateLabel.text = dateFormatter.string(from: date)
        
        dateStepper.value = Double(date.timeIntervalSince1970)
        dateStepper.stepValue = Double(60 * 60 * 24 * 7)
        
        if let info = TimeCardView.employeeInfo {
            employeeLabel.text = info.username
        }
        getTSdata()
    }
    
    @IBAction func goBack(_ sender: Any) { dismiss(animated: true, completion: nil) }
    @IBAction func showSIgnature(_ sender: Any) { self.presentSignature(vc: self, subTitle: "Please sign here", title: "Sign") }
    @IBAction func didChangeDate(_ sender: Any) {
        date = Date(timeIntervalSince1970: dateStepper.value)
        dateLabel.text = dateFormatter.string(from: date)
        
        // fetch TS for date
    }
    
    func getTSdata() {
        inProgress(showProgress: false)
        
        guard let info = TimeCardView.employeeInfo else { return }
        APICalls().getTimesheet(username: info.username, date: date.timeIntervalSince1970) { timecard in
            self.completeProgress()
            self.timesheet = timecard
        }
    }
    
    func getDayOb(day: String) -> UserData.TimeCard.dayObj {
        var dayObj = UserData.TimeCard.dayObj(dict: ["":""])
        
        if let validTS = timesheet {
            switch day {
            case "sunday":
                dayObj = validTS.sunday
            case "monday":
                dayObj = validTS.monday
            case "tuesday":
                dayObj = validTS.tuesday
            case "wednesday":
                dayObj = validTS.wednesday
            case "thursday":
                dayObj = validTS.thursday
            case "friday":
                dayObj = validTS.friday
            case "saturday":
                dayObj = validTS.saturday
                
            default:
                break;
            }
        }
        return dayObj
    }
}

extension TimeCardView: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return daysOweek.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "dayOweek") as? TimeCardCell else {
            return UITableViewCell()
        }
        let thisDay = daysOweek[indexPath.row]
        var txt = ""
        let dayObj = getDayOb(day: thisDay)
        
        txt = "\(daysOweek[indexPath.row]): \(dayObj.date) \n"
        
        for pnch in dayObj.punchTimes {
            if let completePnch = pnch {
                txt += "PO: \(completePnch.po) - \(completePnch.string)"
            }
        }
        cell.dayOweekLbl.text = txt
        
        return cell
    }
}

extension TimeCardView: EPSignatureDelegate {
    func epSignature(_: EPSignatureViewController, didSign signatureImage: UIImage, boundingRect: CGRect) {
        signatureImg.image = signatureImage
    }
    
    func epSignature(_: EPSignatureViewController, didCancel error: NSError) {
    }
}

class TimeCardCell: UITableViewCell {
    @IBOutlet var dayOweekLbl: UILabel!
    
}
