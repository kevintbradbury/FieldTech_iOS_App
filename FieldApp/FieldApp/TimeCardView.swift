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
import Alamofire


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
    @IBOutlet var revisionLbl: UILabel!
    @IBOutlet var reqRevisionSwitch: UISwitch!
    @IBOutlet var noInjuriesLbl: UILabel!
    @IBOutlet var noInjuriesSwitch: UISwitch!
    @IBOutlet var sickTimeLbl: UILabel!
    @IBOutlet var sickTimeField: UITextField!
    
    
    public static var employeeInfo: UserData.UserInfo?
    var date = Date()
    var timesheet: UserData.TimeCard?
    var employeeSignature: UIImage?
    var revisionRequestNotes = ""
    
    let dateFormatter = DateFormatter()
    let daysOweek = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        getTSdata(date: date)
//        setDismissableKeyboard(vc: self)
        setThisDismissableKeyboard()
    }
    
    @IBAction func goBack(_ sender: Any) { dismiss(animated: true, completion: nil) }
    @IBAction func showSIgnature(_ sender: Any) {
        self.presentSignature(vc: self, subTitle: "Please sign here", title: "Sign")
    }
    @IBAction func didChangeDate(_ sender: Any) {
        let newDt = Date(timeIntervalSince1970: dateStepper.value)
        setWeekBgDate(dt: newDt, fromTS: false)
        getTSdata(date: newDt)
    }
    @IBAction func touchRevisionSwitch(_ sender: Any) { showRevisionNotesPopup() }
    @IBAction func sendTSconfirmation(_ sender: Any) { getUserDateForTSAndCheckSigntr() }
    
    
    func setThisDismissableKeyboard() {
        OperationQueue.main.addOperation {
            self.view.frame.origin.y = 0
            self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
            
            NotificationCenter.default.addObserver(
                self, selector: #selector(self.thisKeyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil
            )
            NotificationCenter.default.addObserver(
                self, selector: #selector(self.thisKeyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil
            )
            NotificationCenter.default.addObserver(
                self, selector: #selector(self.thisKeyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil
            )
        }
    }
    
    @objc func thisKeyboardWillChange(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
            
            if self.sickTimeField.isFirstResponder == true {
                OperationQueue.main.addOperation {
                    self.view.frame.origin.y = -(keyboardRect.height - (keyboardRect.height / 2))
                }
            }
        } else {
            OperationQueue.main.addOperation {
                self.view.frame.origin.y = 0
            }
        }
    }
    
    func setWeekBgDate(dt: Date, fromTS: Bool) {
        date = dt
        dateFormatter.dateFormat = "MMM d, yyyy"
        dateLabel.text = "Week of: \(dateFormatter.string(from: date))"
    }
    
    func getUserDateForTSAndCheckSigntr() {
        guard let validTS = timesheet else { return }
        let userANDdateID = validTS.userANDdateID
        let revisionRequested = reqRevisionSwitch.isOn
        let injuryFree = noInjuriesSwitch.isOn
        let route = "timeclock/\(userANDdateID)/mobile/confirm"
        
        let sickStr = sickTimeField?.text ?? ""
        let sickTime: Double = Double(sickStr) ?? 0.0
        
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let dtPOSIX = dateFormatter.string(from: date)
        
        struct ConfirmTS: Encodable {
            let revisionRequested: Bool, userANDdateID: String, username: String, date: String, revisionNotes: String, injuryFree: Bool, sickTime: Double
        }
        let body = ConfirmTS(
            revisionRequested: revisionRequested, userANDdateID: userANDdateID, username: validTS.username, date: dtPOSIX, revisionNotes: revisionRequestNotes, injuryFree: injuryFree, sickTime: sickTime
        )
        
        var data = Data()
        var signatureArray = [UIImage]()
        let jsonEncoder = JSONEncoder();
        
        do { data = try jsonEncoder.encode(body) }
        catch { print("Couldn't encode body to json data."); return }
        
        if revisionRequested == false {
            guard let validSignature = employeeSignature else {
                showAlert(withTitle: "No Signature", message: "Please provide signature to verify timesheet or request revisions."); return
            }
            signatureArray.append(validSignature)
        } else {
            if revisionRequestNotes == "" {
                showAlert(withTitle: "Missing Revisions", message: "Please add revision notes.")
                return
            }
        }
        
        inProgress(showProgress: true)
        
        alamoUpload(route: route, headers: ["employee", body.username], formBody: data, images: signatureArray, uploadType: "confirmTS", callback: { (json) in
            self.completeProgress()
        })
    }
    
    func showRevisionNotesPopup() {
        if reqRevisionSwitch.isOn {
            let popup = UIAlertController(title: "Timesheet Revisions", message: "Please type the revisions in the text field below.", preferredStyle: .alert)
            let submit = UIAlertAction(title: "Submit", style: .default) { (action) in
                guard let txtFields = popup.textFields,
                    let notes = txtFields[0].text else { return }
                self.revisionRequestNotes = notes
                popup.dismiss(animated: true, completion: nil)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            popup.addTextField { (txtField) in
                txtField.placeholder = "Enter revision(s) here."
            }
            
            popup.addAction(submit)
            popup.addAction(cancel)
            
            present(popup, animated: true, completion: nil)
        }
    }
    
    func setUpViews() {
        timeCardTable.delegate = self
        timeCardTable.dataSource = self
        backBtn.accessibilityIdentifier = "backBtn"
        
        dateStepper.setDecrementImage(UIImage(named: "back_arrow"), for: .normal)
        dateStepper.setIncrementImage(UIImage(named: "forward_arrow"), for: .normal)
        
        dateStepper.translatesAutoresizingMaskIntoConstraints = false
        
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
    
    func getTSdata(date: Date) {
        inProgress(showProgress: false)
        
        guard let info = TimeCardView.employeeInfo else {
            showAlert(withTitle: "Error", message: "No employee info.")
            completeProgress()
            return
        }
        clearVals()

        APICalls().getTimesheet(username: info.username, date: date) { (err, timecard) in
            guard let validTS = timecard else {
                self.completeProgress()
                if let er = err { self.showAlert(withTitle: "Error", message: er) }
                return
            }
            self.timesheet = validTS
            
            OperationQueue.main.addOperation {
                if let weekBeginDt = validTS.weekBeginDate { self.setWeekBgDate(dt: weekBeginDt, fromTS: true) }
                self.timeCardTable.reloadData()
                self.totalHrsLbl.text = " Total - \(validTS.totalHours.hours)h: \(validTS.totalHours.min)m "
            }
            self.completeProgress()
        }
    }
    
    func clearVals() {
        self.timesheet = nil
        employeeSignature = nil
        revisionRequestNotes = ""
        
        OperationQueue.main.addOperation {
            self.totalHrsLbl.text = ""
            self.timeCardTable.reloadData()
            self.reqRevisionSwitch.isOn = false
            self.signatureImg.image = UIImage(named: "signature")
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
                txt += " Clock In/Out: \n \(completePnch.string) - "
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
                
                if kNv.key != nil && kNv.key != "" {
                    if indx == 0 { txt += "\n Totals by PO: \n" }
                    let unrounded = Double(kNv.value) ?? 0.0
                    let hrs = Double(unrounded * 100).rounded() / 100
                    let onePO = " PO: \(kNv.key) - \(hrs)h \n "
                    txt += onePO
                }
            }
        }
        
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
            cell.dayOweekLbl.text = txt
        } else {
            cell.cellDateLgLbl.text = "--"
            cell.dayOweekLbl.text = ""
        }
        
        cell.cellDayNmLbl.text = thisDay
        
        return cell
    }
}

extension TimeCardView: EPSignatureDelegate {
    func epSignature(_: EPSignatureViewController, didSign signatureImage: UIImage, boundingRect: CGRect) {
        signatureImg.image = signatureImage
        employeeSignature = signatureImage
        signatureBtn.titleLabel?.text = ""
    }
    
    func epSignature(_: EPSignatureViewController, didCancel error: NSError) {
    }
}

class TimeCardCell: UITableViewCell {
    
    @IBOutlet var dayOweekLbl: UILabel!
    @IBOutlet var cellDateLgLbl: UILabel!
    @IBOutlet var cellDayNmLbl: UILabel!
    
}
