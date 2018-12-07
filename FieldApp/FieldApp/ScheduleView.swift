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
    var jobsArray: [Job.UserJob] = []
    var selectedJobs: [Job.UserJob] = []
    var selectedDates: [Job.UserJob.JobDates] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialCalSetup()
        
        jobsTable.delegate = self
        jobsTable.dataSource = self as? UITableViewDataSource
    }
    
    @IBAction func dismissVC(_ sender: Any) { dismiss(animated: true, completion: nil) }
    
    @IBAction func goGetDirections(_ sender: Any) {
        if jobNameLbl.text != "" {
            checkForJob(name: jobNameLbl.text!) { matchingJob in
                ScheduleView.openMapsWithDirections(to: matchingJob.jobLocation, destination: matchingJob.jobName)
            }
        }
    }
    
}

extension ScheduleView: JTAppleCalendarViewDataSource, JTAppleCalendarViewDelegate {
    
    func initialCalSetup() {
        calendarView.calendarDelegate = self as? JTAppleCalendarViewDelegate
        calendarView.calendarDataSource = self as? JTAppleCalendarViewDataSource
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

        let msVal = TimeInterval(Date().timeIntervalSince1970 + TimeInterval(60 * 60 * 24 * 14)) // 14 days
        let endDate = Date(timeIntervalSince1970: msVal)
        let parameters = ConfigurationParameters(
            startDate: Date(),
            endDate: endDate,
            numberOfRows: 4,
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
            
            APICalls().fetchJobInfo(employeeID: idToString) { jobs in
                self.jobsArray = jobs
                self.jobsArray.sort { ($0.jobName < $1.jobName) }
                self.stopLoading()

                print("jobs count: \(self.jobsArray.count)")
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
        
        checkJobsDates(date: cellState.date) { matchingJbs, jobDts in
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
    
    static func openMapsWithDirections(to coordinate: CLLocationCoordinate2D, destination name: String) {
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: options)
    }
    
    func checkJobsDates(date: Date, callback: ([Job.UserJob], [Job.UserJob.JobDates]) -> ()) {
        var jobsToSend: [Job.UserJob] = []
        var datesToSend: [Job.UserJob.JobDates] = []
        
        for job in jobsArray {
            if job.dates.count > 0 {
                
                for dt in job.dates {
                    let calMDY = getMonthDayYear(date: date)
                    let jobStartMDY = getMonthDayYear(date: dt.installDate)
                    let jobEndMDY = getMonthDayYear(date: dt.endDate)
                    
                    if date >= dt.installDate  && date <= dt.endDate {
                        jobsToSend.append(job)
                        datesToSend.append(dt)
                    } else if jobStartMDY == calMDY || jobEndMDY == calMDY {
                        jobsToSend.append(job)
                        datesToSend.append(dt)
                    }
                }
                let end = Int(jobsArray.count - 1)
                
                if jobsArray.count > 0 && job.jobName == jobsArray[end].jobName {
                    callback(jobsToSend, datesToSend)
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
        
        checkJobsDates(date: cellState.date) { matchingJbs, jobDates in
            print("matchingJobs.count : \(matchingJbs.count)")
            
            if matchingJbs.count > 0 && jobDates.count > 0 {
                var i = 0

                for oneDt in jobDates {
                    let jobVw = createJobTab(cell: cell, oneDt: oneDt, i: i)
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
        
        return cell
    }
    
    // Effectively handles no more than 4 jobs in single calendar cell
    
    func createJobTab(cell: CalendarCell, oneDt: Job.UserJob.JobDates, i: Int) -> UIView {
        let colorChoices = [
            UIColor.cyan.cgColor, UIColor.magenta.cgColor, UIColor.yellow.cgColor, UIColor.lightGray.cgColor
        ]
        
        let w = CGFloat(cell.frame.width / 4)
        let h = CGFloat(oneDt.endDate.timeIntervalSince1970 - oneDt.installDate.timeIntervalSince1970) / 10000
        let x = CGFloat(Double(w) * Double(i))
        let frame = CGRect(x: x, y: 0.0, width: w, height: h)
        let jobVw = UIView(frame: frame)
        jobVw.layer.backgroundColor = colorChoices[i]
        jobVw.accessibilityIdentifier = "jobTab"
        
        return jobVw
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
            let dt = selectedDates[indexPath.row]
            let a = selectedJobs[indexPath.row].jobName
            let b = selectedJobs[indexPath.row].poNumber
            let bb = getTime(date: dt.installDate)
            let cc = getMonthDayYear(date: dt.installDate)
            let dd = getTime(date: dt.endDate)
            let ee = getMonthDayYear(date: dt.endDate)
            
            cell.jobInfoLabel.text = " PO: \(b) \(bb) | \(cc) "
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let matchingJob = selectedJobs[indexPath.row]
        
        let alert = UIAlertController(title: "Directions", message: "Get driving Directions?", preferredStyle: .actionSheet)
        let yes = UIAlertAction(title: "Yes", style: .default) { (action) in
            ScheduleView.openMapsWithDirections(to: matchingJob.jobLocation, destination: matchingJob.jobName)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .destructive)
        
        alert.addAction(yes)
        alert.addAction(cancel)
        
        self.main.addOperation { self.present(alert, animated: true, completion: nil) }
    }

}
