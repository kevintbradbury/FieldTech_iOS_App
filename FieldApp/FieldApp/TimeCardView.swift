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
        let dateToAdjust = date.timeIntervalSince1970 + dateStepper.value
        date = Date(timeIntervalSince1970: dateToAdjust)
        dateLabel.text = dateFormatter.string(from: date)
        
        // fetch TS for date
    }
    
    func setUpViews() {
        timeCardTable.delegate = self
        timeCardTable.dataSource = self
        backBtn.accessibilityIdentifier = "backBtn"
        
        dateFormatter.dateFormat = "MM-dd-yy"
        dateLabel.text = dateFormatter.string(from: date)
        
        dateStepper.value = Double(date.timeIntervalSince1970)
        dateStepper.stepValue = Double(60 * 60 * 24 * 7)
        
        if let info = TimeCardView.employeeInfo {
            employeeLabel.text = info.username
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
                self.totalHrsLbl.text = "Total - \(validTS.totalHours.hours)h: \(validTS.totalHours.min)m"
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
    
    func setTxt(thisDay: String) -> String {
        var txt = "\(thisDay)"
        let dayObj = getDayOb(day: thisDay)
        
        if dayObj.duration.hours > 0 || dayObj.duration.min > 0 {
            txt += " - \(dayObj.duration.hours)h: \(dayObj.duration.min)m"
        }
        
        txt += "\n"
        
        for (index, value) in dayObj.punchTimes.enumerated() {
            guard let completePnch = value else { continue }
            
            if index == (dayObj.punchTimes.count - 1) {
                txt += "\(completePnch.string)"; continue
            }
            txt += "\(completePnch.string), "
        }
        
        txt += "\n"
        
        if let validPOs = dayObj.POs {
            for p in validPOs {
                guard let kNv = p.first else { continue }
                
                if kNv.key != nil && kNv.key != "" {
                    let onePO = "PO: \(kNv.key) - \(kNv.value)h "
                    txt += onePO
                }
            }
        }
        
        return txt
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "dayOweek") as? TimeCardCell else {
            return UITableViewCell()
        }
        let thisDay = daysOweek[indexPath.row]
        var txt = setTxt(thisDay: thisDay)
        
//        let dayObj = getDayOb(day: thisDay)
//        if dayObj.duration.hours > 0 && dayObj.duration.min > 0 {
//            txt = "\(daysOweek[indexPath.row]) - \(dayObj.duration.hours)h: \(dayObj.duration.min)m\n"
//        }
//        for pnch in dayObj.punchTimes {
//            if let completePnch = pnch { txt += "\(completePnch.string), " }
//        }
//        txt += "\n"
//        if let validPOs = dayObj.POs {
//            for p in validPOs {
//                guard let kNv = p.first else { continue }
//                if kNv.key != nil && kNv.key != "" {
//                    let onePO = "PO: \(kNv.key) - \(kNv.value)h | "
//                    txt += onePO
//                }
//            }
//        }
        
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
