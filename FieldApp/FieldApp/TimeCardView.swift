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
    @IBOutlet var totalHrsLbl: UILabel!
    @IBOutlet var dateStepper: UIStepper!
    @IBOutlet var timeCardTable: UITableView!
    @IBOutlet var signatureImg: UIImageView!
    @IBOutlet var signatureBtn: UIButton!
    @IBOutlet var confirmBtn: UIButton!
    @IBOutlet var backBtn: UIButton!
    
    public static var employeeInfo: UserData.UserInfo?
    var date = Date()
    var timesheet: UserData.TimeCard?
    
    let dateFormatter = DateFormatter()
    let daysOweek = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        getTSdata()
    }
    
    @IBAction func goBack(_ sender: Any) { dismiss(animated: true, completion: nil) }
    @IBAction func showSIgnature(_ sender: Any) { self.presentSignature(vc: self, subTitle: "Please sign here", title: "Sign") }
    @IBAction func didChangeDate(_ sender: Any) {
        print(dateStepper.value)
        
//        let dateToAdjust = date.timeIntervalSince1970 + dateStepper.value
//        date = Date(timeIntervalSince1970: dateToAdjust)
//        dateLabel.text = dateFormatter.string(from: date)
        
        // fetch TS for date
    }
    
    func setUpViews() {
        timeCardTable.delegate = self
        timeCardTable.dataSource = self
        backBtn.accessibilityIdentifier = "backBtn"
        
        dateFormatter.dateFormat = "MMM d, yyyy"
        dateLabel.text = " \(dateFormatter.string(from: date)) "
        
        let oneWeek = Double(60 * 60 * 24 * 7)
        let now = Double(date.timeIntervalSince1970)
        
        dateStepper.minimumValue = Double(now - 60 * 60 * 24 * 365)
        dateStepper.maximumValue = Double(now + oneWeek)
        dateStepper.value = now
        dateStepper.stepValue = oneWeek
        
        if let info = TimeCardView.employeeInfo {
            employeeLabel.text = " \(info.username) "
        }
    }
    
    func getTSdata() {
        inProgress(showProgress: false)
        
        guard let info = TimeCardView.employeeInfo else { return }
        APICalls().getTimesheet(username: info.username, date: date.timeIntervalSince1970) { timecard in
            self.timesheet = timecard
            
            OperationQueue.main.addOperation {
                guard let validTS = self.timesheet else { return }
                
                self.timeCardTable.reloadData()
                self.totalHrsLbl.text = " Total - \(validTS.totalHours.hours)h: \(validTS.totalHours.min)m "
            }
            self.completeProgress()
        }
    }
    
    func getDayOb(day: String) -> UserData.TimeCard.dayObj {
        var dayObj = UserData.TimeCard.dayObj(dict: ["":""])
        
        if let validTS = timesheet {
            switch day {
            case "Sun":
                dayObj = validTS.sunday
            case "Mon":
                dayObj = validTS.monday
            case "Tue":
                dayObj = validTS.tuesday
            case "Wed":
                dayObj = validTS.wednesday
            case "Thu":
                dayObj = validTS.thursday
            case "Fri":
                dayObj = validTS.friday
            case "Sat":
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
    
    func setTxt(thisDay: String, dayObj: UserData.TimeCard.dayObj) -> String {
        var txt = ""
        
        for (index, value) in dayObj.punchTimes.enumerated() {
            guard let completePnch = value else { continue }
            
            if index == 0 {
                txt += "Clock In/Out: \n \(completePnch.string) - "
            } else if index == (dayObj.punchTimes.count - 1) {
                txt += "\(completePnch.string)"
            } else if Int(index % 4) == 0 {
                txt += "\n \(completePnch.string) - "
            } else {
                txt += "\(completePnch.string) - "
            }
        }
        
        if let validPOs = dayObj.POs {
            for (indx, val) in validPOs.enumerated() {
                guard let kNv = val.first else { continue }
                
                if indx == 0 { txt += "\n Totals by PO: \n" }
                
                if kNv.key != nil && kNv.key != "" {
                    let onePO = "PO: \(kNv.key) - \(kNv.value)h \n "
                    txt += onePO
                }
            }
        }
        
        txt += "\n "
        
        if dayObj.duration.hours > 0 || dayObj.duration.min > 0 || dayObj.punchTimes.count > 0 {
            txt += " Total hrs: \(dayObj.duration.hours)h: \(dayObj.duration.min)m"
        }
        
        return txt
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "dayOweek") as? TimeCardCell else {
            return UITableViewCell()
        }
        let thisDay = daysOweek[indexPath.row]
        let dayObj = getDayOb(day: thisDay)
        var txt = setTxt(thisDay: thisDay, dayObj: dayObj)
        
        if let validDt = dayObj.date {
            dateFormatter.dateFormat = "d"
            let dt = dateFormatter.string(from: validDt)
         
            cell.cellDateLgLbl.text = dt
        }
        cell.cellDayNmLbl.text = thisDay
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
    @IBOutlet var cellDateLgLbl: UILabel!
    @IBOutlet var cellDayNmLbl: UILabel!
    
}
