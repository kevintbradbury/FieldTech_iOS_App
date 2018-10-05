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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        
        calendarView.calendarDelegate = self
        calendarView.calendarDataSource = self
        calendarView.visibleDates { visibleDates in
            self.setUpCalendarViews(visibleDates: visibleDates)
            self.main.addOperation {
                self.clearJobInfo()
                self.activityIndicator.startAnimating()
            }
        }
        getCalendarInfo()
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
    
    func getCalendarInfo() {
        if let unwrappedEmployee = self.employee {
            let idToString = String(unwrappedEmployee.employeeID)
            
            APICalls().fetchJobInfo(employeeID: idToString) { jobs in
                self.jobsArray = jobs
                self.jobsArray.sort {($0.jobName < $1.jobName)}
                
                for i in self.jobsArray { print(i.jobName, i.dates, i.jobAddress) }
                
                self.main.addOperation {
                    self.activityIndicator.stopAnimating();
                    self.calendarView.reloadData()
                }
            }
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {

        let tableCell = setViewForCell(calendar: calendar, date: date, cellState: cellState, indexPath: indexPath)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        
        let tableCell = setViewForCell(calendar: calendar, date: date, cellState: cellState, indexPath: indexPath)
        return tableCell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CalendarCell else {return}
        
        checkJobsDates(date: cellState.date) { matchingJob, jobDate in
            self.jobNameLbl.text = matchingJob.jobName
            self.poNumberLbl.text = "PO " + String(matchingJob.poNumber)
            self.installDateLbl.text = "\(getMonthDayYear(date: jobDate.installDate)) \n\(getTime(date: jobDate.installDate)) "
            self.directionsBtn.isHidden = false
//            self.directionsBtn.titleLabel!.text = "\(matchingJob.jobAddress) \n \(matchingJob.jobCity), \(matchingJob.jobState)"
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CalendarCell else {return}
        clearJobInfo()
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        setUpCalendarViews(visibleDates: visibleDates)
    }
}

extension ScheduleView {
    
    func clearJobInfo() {
        jobNameLbl.text = ""
        poNumberLbl.text = ""
        installDateLbl.text = ""
        directionsBtn.isHidden = true
        //        directionsBtn.titleLabel?.text = ""
    }
    
    static func openMapsWithDirections(to coordinate: CLLocationCoordinate2D, destination name: String) {
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: options)
    }
    
    func checkJobsDates(date: Date, callback: (Job.UserJob, Job.UserJob.JobDates) -> ()) {
        for job in jobsArray {
            if job.dates.count > 0 {
                
                for dt in job.dates {
                    let calMDY = getMonthDayYear(date: date)
                    let jobStartMDY = getMonthDayYear(date: dt.installDate)
                    let jobEndMDY = getMonthDayYear(date: dt.endDate)
                    
                    if date >= dt.installDate  && date <= dt.endDate { callback(job, dt) }
                    else if jobStartMDY == calMDY || jobEndMDY == calMDY { callback(job, dt) }
                    
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
    
    func setUpCalendarViews(visibleDates: DateSegmentInfo) {
        activityIndicator.hidesWhenStopped = true
        calendarView.isPrefetchingEnabled = true
        
        calendarView.minimumLineSpacing = 1
        calendarView.minimumInteritemSpacing = 1
        
        guard let date = visibleDates.monthDates.first?.date else { return }
        print("visible Dates: date", date)
        
        formatter.dateFormat = "yyyy"
        yearLabel.text = formatter.string(from: date)
        formatter.dateFormat = "MMMM"
        monthLabel.text = formatter.string(from: date)
    }
    
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Calendar.current.locale
        
        let date = Date()
        let currentCalendar = Calendar.current
        let currentYear = currentCalendar.component(.year, from: date)
        let currentMonth = currentCalendar.component(.month, from: date)
        let currentDay = currentCalendar.component(.day, from: date)
        let dayOfWeek = currentCalendar.component(.weekday, from: date)
        
        func startDateString() -> String {
            let startDate = String(currentMonth) + "-" + String(currentDay) + "-" + String(currentYear)
            
            return startDate
        }
        
        func endDateString() -> String {
            let msVal = TimeInterval(Date().timeIntervalSince1970 + TimeInterval(60 * 60 * 24 * 21)) // 21 days
            let endDate = Date(timeIntervalSince1970: msVal)
            let endCalendar = Calendar.current
            let year = currentCalendar.component(.year, from: endDate)
            let month = currentCalendar.component(.month, from: endDate)
            let day = currentCalendar.component(.day, from: endDate)
            let dayOfWeek = currentCalendar.component(.weekday, from: endDate)
            let endString = String(month) + "-" + String(day) + "-" + String(year)
            print("endString ", endString)
            
            return endString
        }
        
        let startDate = formatter.date(from: startDateString())
        let endDate = formatter.date(from: endDateString())
        
        let parameters = ConfigurationParameters(startDate: startDate!,
                                                 endDate: endDate!,
                                                 numberOfRows: 1,
                                                 calendar: Calendar.current,
                                                 generateInDates: .forAllMonths,
                                                 generateOutDates: .off,
                                                 firstDayOfWeek: .sunday)
        
        return parameters
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
    
    func setViewForCell(calendar: JTAppleCalendarView, date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "customCalendarCell", for: indexPath) as! CalendarCell
        cell.highlightView.isHidden = true
        
        if cellState.dateBelongsTo == .previousMonthWithinBoundary || cellState.dateBelongsTo == .followingMonthWithinBoundary || cellState.dateBelongsTo != .thisMonth {
            formatter.dateFormat = "MMM"
            cell.dateLabel.text = formatter.string(from: date) + "\n " + cellState.text + "previousMonth"
            cell.dateLabel.textColor = UIColor.lightGray
            
        } else {
            cell.dateLabel.text = cellState.text
            cell.dateLabel.textColor = UIColor.black
            cell.backgroundColor = UIColor.white
            
            formatter.dateFormat = "yyyy"
            yearLabel.text = formatter.string(from: date)
            formatter.dateFormat = "MMMM"
            monthLabel.text = formatter.string(from: date)
        }
        
        checkJobsDates(date: cellState.date) { matchingJob, jobDate in
            cell.highlightView.isHidden = false
            cell.jobName.text = matchingJob.jobName
            cell.dateLabel.textColor = UIColor.white
        }
        
        return cell
    }
    
}

