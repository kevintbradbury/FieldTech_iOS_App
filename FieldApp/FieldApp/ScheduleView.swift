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
    
    let formatter = DateFormatter()
    let main = OperationQueue.main
    var employee: UserData.UserInfo?
    var timeOreqs: [TimeOffReq] = []
    var jobsArray: [Job.UserJob] = []
    var selectedJobs: [Job.UserJob] = []
    var selectedDates: [Job.UserJob.JobDates] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialCalSetup()
        
        jobsTable.delegate = self
        jobsTable.dataSource = self
    }
    
    @IBAction func dismissVC(_ sender: Any) { dismiss(animated: true, completion: nil) }
    
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
        HomeView.scheduleReadyNotif = false
        
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
        let tableCell = setViewForCell(calendar: calendar, date: date, cellState: cellState, indexPath: indexPath)
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
            
            APICalls().fetchJobInfo(employeeID: idToString) { (jobs, timeOffReqs) in
                self.jobsArray = jobs
                self.jobsArray.sort { ($0.jobName < $1.jobName) }
                self.timeOreqs = timeOffReqs
                self.timeOreqs.sort { ($0.start < $1.start) }
                
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

extension ScheduleView {
    
    func loading() {
        self.main.addOperation {
            self.clearJobInfo()
            self.activityIndicator.hidesWhenStopped = true
            self.activityIndicator.startAnimating()
        }
    }
    
    func stopLoading() {
        self.main.addOperation {
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
            
            for day in timeOreqs {
                let st = Date(timeIntervalSince1970: day.start)
                let end = Date(timeIntervalSince1970: day.end)
                let dtMDY = getMonthDayYear(date: date)
                let stMDY = getMonthDayYear(date: st)
                
                if st < date && date < end {
                    cb(day)
                } else if dtMDY == stMDY {
                    cb(day)
                }
            }
        }
    }
    
    func checkForJob(name: String, callback: (Job.UserJob) -> ()) {
        for job in jobsArray {
            if name == job.jobName {
                guard let matchingJob = job as? Job.UserJob else { return }
                callback(matchingJob)
            }
        }
    }
    
    func setMonthYearElements(visibleDates: DateSegmentInfo) {
        guard let date = visibleDates.monthDates.first?.date else { return }
        
        formatter.dateFormat = "yyyy"
        yearLabel.text = formatter.string(from: date)
        formatter.dateFormat = "MMMM"
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
            formatter.dateFormat = "MMMM"
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
                        if subVw.accessibilityIdentifier == "jobTab" {
                            subVw.removeFromSuperview()
                        }
                    }
            }
        }
        
        checkForTOR(date: cellState.date) { tmOffReq in
            cell.backgroundColor = UIColor.white
        }
        
        return cell
    }
    
    // Effectively handles no more than 4 jobs in single calendar cell
    func createJobTab(cell: CalendarCell, oneDt: Job.UserJob.JobDates, oneJb: Job.UserJob, i: Int) -> UILabel {
        
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
    
}

extension ScheduleView: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
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
            let jobName = jb.jobName
            let po = jb.poNumber
            let startTm = getTime(date: dt.installDate)
            let address = "\(jb.jobAddress), \(jb.jobCity), \(jb.jobState)"
            
            cell.jobInfoLabel.text = "\(jobName) \(startTm) \n\(address)"
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let matchingJob = selectedJobs[indexPath.row]
        
        let alert = UIAlertController(title: "Directions", message: "Get directions to PO: \(matchingJob.poNumber) \n\(matchingJob.jobName)?", preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: .destructive)
        let yes = UIAlertAction(title: "Yes", style: .default) { (action) in
            self.openMapsWithDirections(to: matchingJob.jobLocation, destination: matchingJob.jobName)
        }
        
        alert.addAction(yes)
        alert.addAction(cancel)
        
        self.main.addOperation { self.present(alert, animated: true, completion: nil) }
    }

}
