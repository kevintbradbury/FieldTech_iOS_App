//
//  ScheduleView.swift
//  FieldApp
//
//  Created by MB Mac 3 on 1/2/18.
//  Copyright © 2018 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import JTAppleCalendar
import CoreLocation
import MapKit

class ScheduleView: UIViewController {
    
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    @IBOutlet var jobsTable: UITableView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var jobDetailView: UIView!
    @IBOutlet weak var jobNameLbl: UILabel!
    @IBOutlet weak var poNumberLbl: UILabel!
    @IBOutlet weak var installDateLbl: UILabel!
    @IBOutlet weak var directionsBtn: UIButton!
    @IBOutlet var daysOfWeekView: UIView!
    @IBOutlet var sundaySwitch: UISwitch!
    @IBOutlet var mondaySwitch: UISwitch!
    @IBOutlet var tuesdaySwitch: UISwitch!
    @IBOutlet var wednesdaySwitch: UISwitch!
    @IBOutlet var thursdaySwitch: UISwitch!
    @IBOutlet var fridaySwitch: UISwitch!
    @IBOutlet var saturdaySwitch: UISwitch!
    @IBOutlet var submitBtn: UIButton!
    @IBOutlet var cancelBtn: UIButton!
    
    
    let formatter = DateFormatter()
    let main = OperationQueue.main
    
    var employee: UserData.UserInfo?
    var holidays: [Holiday] = []
    var timeOreqs: [TimeOffReq] = []
    var jobsArray: [Job.UserJob] = []
    var selectedJobs: [Job.UserJob] = []
    var selectedDates: [Job.UserJob.JobDates] = []
    public static var scheduleRdy: Bool?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialCalSetup()
        
        jobsTable.delegate = self
        jobsTable.dataSource = self
        daysOfWeekView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        checkScheduleReady()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        checkForNotifUpdates()
    }
    
    @IBAction func dismissVC(_ sender: Any) { dismiss(animated: true, completion: nil) }
    @IBAction func accptMoreHrsBtn(_ sender: Any) { confirmRegOrMoreHrs() }
    @IBAction func sendDaysOfWeek(_ sender: Any) { getDaysAccepted() }
    @IBAction func cancelMoreHours(_ sender: Any) { daysOfWeekView.isHidden = true }
    @IBAction func goGetDirections(_ sender: Any) {
        if jobNameLbl.text != "" {
            checkForJob(name: jobNameLbl.text!) { matchingJob in
                    self.openMapsWithDirections(to: matchingJob.jobLocation, destination: matchingJob.jobName)
            }
        }
    }
    
}

extension ScheduleView: JTAppleCalendarViewDataSource, JTAppleCalendarViewDelegate {
    
    func initialCalSetup() {
//        HomeView.scheduleReadyNotif = false
        
        calendarView.calendarDelegate = self
        calendarView.calendarDataSource = self
        calendarView.isPrefetchingEnabled = true
        calendarView.minimumInteritemSpacing = 1
        calendarView.minimumLineSpacing = 1
        calendarView.scrollDirection = .horizontal
        calendarView.visibleDates { visibleDates in
            self.loading()
            self.getCalendarInfo()
            self.setMonthYearElements(visibleDates: visibleDates)
        }
    }
    
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        let calndr = Calendar.current
        
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.timeZone = calndr.timeZone
        formatter.locale = calndr.locale

        let msVal = TimeInterval(Date().timeIntervalSince1970 + TimeInterval(60 * 60 * 24 * 14)) // sec * min * hours * 14 days
        let endDate = Date(timeIntervalSince1970: msVal)
        let parameters = ConfigurationParameters(
            startDate: Date(),
            endDate: endDate,
            numberOfRows: 5,
            calendar: calndr,
            generateInDates: .forAllMonths,
            generateOutDates: .tillEndOfRow,
            firstDayOfWeek: .sunday
        )
        
        calendarView.scrollToHeaderForDate(Date())
        
        return parameters
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let tableCell = setViewForCell(calendar: calendar, date: date, cellState: cellState, indexPath: indexPath)
        return tableCell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        _ = setViewForCell(calendar: calendar, date: date, cellState: cellState, indexPath: indexPath)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CalendarCell else { return }
        dateSelected(validCell: validCell, cellState: cellState)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CalendarCell else { return }
        clearJobInfo()
        deselectCell(subViews: validCell.subviews)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        setMonthYearElements(visibleDates: visibleDates)
        
        for collectionCell in calendar.visibleCells {
            deselectCell(subViews: collectionCell.subviews)
        }
    }

    func getCalendarInfo() {
        if let unwrappedEmployee = self.employee {
            let idToString = String(unwrappedEmployee.employeeID)
            
            APICalls().fetchJobInfo(employeeID: idToString, vc: self) { (jobs, timeOffReqs, holidayss) in
                self.jobsArray = jobs
                self.jobsArray.sort { ($0.jobName < $1.jobName) }
                self.timeOreqs = timeOffReqs
                self.holidays = holidayss
                self.stopLoading()
            }
        }
    }
    
    func dateSelected(validCell: CalendarCell, cellState: CellState) {
        let borderView = UIView(
            frame: CGRect(x: 0.0, y: 0.0, width: validCell.frame.width, height: validCell.frame.height
            )
        )
        borderView.accessibilityIdentifier = "borderView"
        borderView.layer.borderWidth = 2
        borderView.layer.borderColor = UIColor.white.cgColor
        
        validCell.addSubview(borderView)
        
        formatter.dateFormat = "MMMM dd"
        monthLabel.text = formatter.string(from: cellState.date)
        
        checkJobsDates(date: cellState.date) { matchingJbs, jobDts, colorInts in
            selectedJobs = matchingJbs
            selectedDates = jobDts
 
            main.addOperation {
                self.jobsTable.reloadData()
            }
        }
    }
    
    func deselectCell(subViews: [UIView]) {
        for oneView in subViews {
            guard let id = oneView.accessibilityIdentifier else { continue }
            if id == "borderView" { oneView.removeFromSuperview() }
        }
    }

}

struct AcceptMoreDays: Encodable {
    let sun: Bool, mon: Bool, tue: Bool, wed: Bool, thu: Bool, fri: Bool, sat: Bool
}

extension ScheduleView {
    
    func checkScheduleReady() {
        guard let readyOrNot = ScheduleView.scheduleRdy else {
            return
        }
        if readyOrNot == true {
            confirmRegOrMoreHrs()
        }
    }
    
    func getDaysAccepted() {
        let acceptMoreHrs = AcceptMoreDays(
            sun: sundaySwitch.isOn,
            mon: mondaySwitch.isOn,
            tue: tuesdaySwitch.isOn,
            wed: wednesdaySwitch.isOn,
            thu: thursdaySwitch.isOn,
            fri: fridaySwitch.isOn,
            sat: saturdaySwitch.isOn
        )
        guard let user = employee?.userName else { return }
        let mirror = Mirror(reflecting: acceptMoreHrs)
        var acceptedDays = 0
        
        for (property, val) in mirror.children {
            guard let boool = val as? Bool else { return }
            if boool == true {
                acceptedDays += 1
            }
        }
        
        if (acceptedDays < 2) {
            showAlert(withTitle: "Select Nights", message: "You must select at least 2 nights."); return
        }
        activityIndicator.startAnimating()
        APICalls().acceptMoreHrs(employee: user, moreDays: acceptMoreHrs, vc: self) { success in
            self.main.addOperation {
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    func confirmRegOrMoreHrs() {
        daysOfWeekView.isHidden = false
        daysOfWeekView.layer.cornerRadius = 20
        submitBtn.layer.cornerRadius = 10
        cancelBtn.layer.cornerRadius = 10
        ScheduleView.scheduleRdy = nil
        HomeView.scheduleReadyNotif = nil
    }
    
    func loading() {
        self.main.addOperation {
            self.clearJobInfo()
            self.activityIndicator.hidesWhenStopped = true
            self.activityIndicator.startAnimating()
        }
    }
    
    func stopLoading() {
        self.main.addOperation {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.calendarView.reloadData()
            self.activityIndicator.stopAnimating()
        }
    }
    
    func clearJobInfo() {
        jobNameLbl.text = ""
        poNumberLbl.text = ""
        installDateLbl.text = ""
        directionsBtn.isHidden = true
    }
    
    func checkJobsDates(date: Date, callback: ([Job.UserJob], [Job.UserJob.JobDates], [Int]) -> ()) {
        var jobsToSend: [Job.UserJob] = []
        var datesToSend: [Job.UserJob.JobDates] = []
        var colorInts: [Int] = []
        var x = 0
        
        for job in jobsArray {
            if job.dates.count > 0 {
                
                for dt in job.dates {
                    let calMDY = getMonthDayYear(date: date)
                    let jobStartMDY = getMonthDayYear(date: dt.installDate)
                    let jobEndMDY = getMonthDayYear(date: dt.endDate)
                    
                    if date >= dt.installDate  && date <= dt.endDate {
                        colorInts.append(x)
                        jobsToSend.append(job)
                        datesToSend.append(dt)
                    } else if jobStartMDY == calMDY || jobEndMDY == calMDY {
                        colorInts.append(x)
                        jobsToSend.append(job)
                        datesToSend.append(dt)
                    }
                }
                let end = Int(jobsArray.count - 1)
                
                if jobsArray.count > 0 && job.jobName == jobsArray[end].jobName {
                    callback(jobsToSend, datesToSend, colorInts)
                }
            }
            x += 1
            if x == 4 { x = 0 }
        }
    }
    
    func checkForTOR(date: Date, cb: (TimeOffReq) -> () ) {
        
        if timeOreqs.count > 0 {
            let dtMDY = getMonthDayYear(date: date)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            for day in timeOreqs {
                if day.approved != true { continue }
                
                let st = Date(timeIntervalSince1970: day.start)
                let end = Date(timeIntervalSince1970: day.end)
                let stMDY = getMonthDayYear(date: st)
                
                if st < date && date < end {
                    cb(day)
                } else if dtMDY == stMDY {
                    cb(day)
                }
            }
        }
    }
    
    func checkForHoliday(date: Date, cell: CalendarCell, cb: (Holiday) -> () ) {
        for subVw in cell.subviews {
            if subVw.accessibilityIdentifier == "holidayLabel" {
                subVw.removeFromSuperview()
            }
        }
        
        if holidays.count > 0 {
            let dtMDY = getMonthDayYear(date: date)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            for day in holidays {
                let st = day.start
                let end = day.end
                let stMDY = getMonthDayYear(date: st)
                
                if st < date && date < end {
                    cb(day)
                } else if dtMDY == stMDY {
                    cb(day)
                }
            }
        }
    }
    
    func setHldyLabel(cell: CalendarCell, holidy: Holiday) {
        
        let splitName = holidy.name.components(separatedBy: " ")
        var holidayName = ""
        var fontSize = 8
        
        for char in splitName {
            
            if char.count > 7 {
                fontSize -= 1
                holidayName += "\(char)\n"
            } else {
                holidayName += "\(char)\n"
            }
        }
        
        let frame = CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height)
        let label = UILabel(frame: frame)
        label.numberOfLines = (splitName.count + 1)
        label.backgroundColor = UIColor.blue
        label.textColor = UIColor.white
        label.text = holidayName
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
        label.accessibilityIdentifier = "holidayLabel"
        
        self.main.addOperation { cell.addSubview(label) }
    }
    
    func checkForJob(name: String, callback: (Job.UserJob) -> ()) {
        for job in jobsArray {
            if name == job.jobName {
                callback(job)
            }
        }
    }
    
    func setMonthYearElements(visibleDates: DateSegmentInfo) {
        guard let date = visibleDates.monthDates.first?.date else { return }
        
        formatter.dateFormat = "yyyy"
        yearLabel.text = formatter.string(from: date)
        formatter.dateFormat = "MMMM dd"
        monthLabel.text = formatter.string(from: date)
    }
    
    
    func getMonthDayYear(date: Date) -> String {
        let adjustedDateTime = date

        formatter.dateFormat = "MMM"
        let month = formatter.string(from: adjustedDateTime)
        formatter.dateFormat = "dd"
        let day = formatter.string(from: adjustedDateTime)
        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: adjustedDateTime)
        let dateString = month + " " + day + ", " + year
        
        return dateString
    }
    
    func getTime(date: Date) -> String {
        let adjustedDateTime = date
        
        formatter.dateFormat = "h:mm a"
        let time = formatter.string(from: adjustedDateTime)
        
        return time
    }
    
    func setViewForCell(calendar: JTAppleCalendarView, date: Date, cellState: CellState, indexPath: IndexPath) -> CalendarCell {
        let cell = calendar.dequeueReusableCell(withReuseIdentifier: "customCalendarCell", for: indexPath) as! CalendarCell
        cell.highlightView.isHidden = true
        
        if cellState.dateBelongsTo == .previousMonthWithinBoundary || cellState.dateBelongsTo == .followingMonthWithinBoundary || cellState.dateBelongsTo != .thisMonth {
            formatter.dateFormat = "MMM"
            cell.dateLabel.text = "\(formatter.string(from: date)) \(cellState.text)"
            cell.dateLabel.textColor = UIColor.lightGray
            cell.alpha = .init(0.4)
            
        } else {
            cell.dateLabel.text = cellState.text
            cell.dateLabel.textColor = UIColor.white
            cell.backgroundColor = UIColor.darkGray
            
            formatter.dateFormat = "yyyy"
            yearLabel.text = formatter.string(from: date)
            formatter.dateFormat = "MMMM dd"
            monthLabel.text = formatter.string(from: date)
        }
        
        checkJobsDates(date: cellState.date) { matchingJbs, jobDates, colorInts in
            
            if matchingJbs.count > 0 && jobDates.count > 0 {
                let colorChoices = [UIColor.cyan, UIColor.magenta, UIColor.yellow, UIColor.lightGray]
                var i = 0

                for oneJb in matchingJbs {
                    let jobVw = createJobTab(cell: cell, oneDt: jobDates[i], oneJb: oneJb, i: i)
                    jobVw.backgroundColor = colorChoices[colorInts[i]]
                    self.main.addOperation { cell.addSubview(jobVw) }
                    i += 1
                }
            } else {
                    for subVw in cell.subviews {
                        if subVw.accessibilityIdentifier == "jobTab" { subVw.removeFromSuperview() }
                    }
            }
        }
        
        checkForTOR(date: cellState.date) { tmOffReq in
            cell.backgroundColor = UIColor.white
            cell.dateLabel.textColor = UIColor.black
        }
        
        checkForHoliday(date: cellState.date, cell: cell) { holidy in
            self.setHldyLabel(cell: cell, holidy: holidy)
        }
        
        return cell
    }
    
    // Effectively handles no more than 4 jobs in single calendar cell
    func createJobTab(cell: CalendarCell, oneDt: Job.UserJob.JobDates, oneJb: Job.UserJob, i: Int) -> UILabel {  // UIView
        
        let w = cell.frame.width - 1
        let h = CGFloat(cell.frame.height / 8)
        let x = CGFloat(1.0)
        let y = CGFloat(Double(cell.frame.height / 2) + Double(i) * Double(h)) - h
        let frame = CGRect(x: x, y: y, width: w, height: h)
        let poNumTx = " PO-\(oneJb.poNumber)"
        
        let label = UILabel(frame: frame)
        label.text = poNumTx
        label.textAlignment = .justified
        label.font = UIFont.systemFont(ofSize: 7)
        label.accessibilityIdentifier = "jobTab"
        
        return label
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "torList" {
            guard let vc = segue.destination as? TORLogView else { return }
            vc.timeOffReqs = timeOreqs
        }
    }
}

extension ScheduleView: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var z = 0
        z += selectedJobs.count
        return z
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "jobInfoCell", for: indexPath) as? JobCell else {
            return UITableViewCell()
        }

        if selectedJobs.count > 0 {
            let jb = selectedJobs[indexPath.row]
            let dt = selectedDates[indexPath.row]
            let labelTxt = createLabel(jb: jb, dt: dt)

            cell.jobInfoLabel.text = labelTxt
        }
        let blkBkgd = UIView()
        blkBkgd.backgroundColor = .darkGray
        
        cell.selectedBackgroundView = blkBkgd

        return cell
    }
    
    func createLabel(jb: Job.UserJob, dt: Job.UserJob.JobDates) -> String {
        let jobName = jb.jobName
        let startTm = getTime(date: dt.installDate)
        let address = "\(jb.jobAddress), \(jb.jobCity), \(jb.jobState)"
        
        var labelTxt = "\(jobName) \(startTm) \n\(address) \nSuper: \(jb.supervisor) | Lead: \(jb.fieldLead) \nEmployees: "
        
        jb.assignedEmployees.enumerated().map { (index, oneEmployee) in
            if index == (jb.assignedEmployees.count - 1) {
                labelTxt += "\(oneEmployee)"
            } else {
                labelTxt += "\(oneEmployee), "
            }
        }
        
        return labelTxt
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        showDirectionsAlert(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        showDirectionsAlert(indexPath: indexPath)
    }
    
    func showDirectionsAlert(indexPath: IndexPath) {
        let matchingJob = selectedJobs[indexPath.row]
        
        let alert = UIAlertController(title: "Directions", message: "Get directions to PO: \(matchingJob.poNumber) \n\(matchingJob.jobName)?", preferredStyle: .actionSheet)
        let yes = UIAlertAction(title: "Yes", style: .default) { (action) in
            self.openMapsWithDirections(to: matchingJob.jobLocation, destination: matchingJob.jobName)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .destructive)
        
        alert.addAction(yes)
        alert.addAction(cancel)
        
        self.main.addOperation { self.present(alert, animated: true, completion: nil) }
    }
}


// -- Cells Classes

class CalendarCell: JTAppleCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var highlightView: UIView!
    @IBOutlet weak var jobName: UILabel!
}

class JobCell: UITableViewCell {
    @IBOutlet var jobInfoLabel: UILabel!
}
