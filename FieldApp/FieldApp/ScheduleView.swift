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
    var employee: UserData.UserInfo?
    var jobsArray: [Job.UserJob] = []
    let main = OperationQueue.main
    
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
                self.openMapsWithDirections(to: matchingJob.jobLocation, destination: matchingJob.jobName)
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
                
                self.main.addOperation { self.activityIndicator.stopAnimating(); self.calendarView.reloadData() }
            }
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {

        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "customCalendarCell", for: indexPath) as! CalendarCell
        
        cell.dateLabel.text = cellState.text
        cell.highlightView.isHidden = true
        
        if cellState.dateBelongsTo != .thisMonth {
            cell.dateLabel.textColor = UIColor.lightGray
        } else {
            cell.dateLabel.textColor = UIColor.black
            cell.backgroundColor = UIColor.white
        }
        
        checkJobsDates(date: cellState.date) { matchingJob in
            cell.highlightView.isHidden = false
            cell.jobName.text = matchingJob.jobName
            cell.dateLabel.textColor = UIColor.white
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "customCalendarCell", for: indexPath) as! CalendarCell
        
        cell.dateLabel.text = cellState.text
        cell.highlightView.isHidden = true
        
        if cellState.dateBelongsTo != .thisMonth {
            cell.dateLabel.textColor = UIColor.lightGray
        } else {
            cell.dateLabel.textColor = UIColor.black
            cell.backgroundColor = UIColor.white
        }
        
        checkJobsDates(date: cellState.date) { matchingJob in
            cell.highlightView.isHidden = false
            cell.jobName.text = matchingJob.jobName
            cell.dateLabel.textColor = UIColor.white
        }
        
        return cell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CalendarCell else {return}
        
        checkJobsDates(date: cellState.date) { matchingJob in
            self.jobNameLbl.text = matchingJob.jobName
            self.poNumberLbl.text = "PO " + String(matchingJob.poNumber)
            self.installDateLbl.text = "\(getMonthDayYear(date: matchingJob.dates[0].installDate)) \n \(getTime(date: matchingJob.dates[0].installDate))"
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
//        directionsBtn.titleLabel?.text = ""
        directionsBtn.isHidden = true
    }
    
    func openMapsWithDirections(to coordinate: CLLocationCoordinate2D, destination name: String) {
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: options)
    }
    
    func checkJobsDates(date: Date, callback: (Job.UserJob) -> ()) {
        
        for job in jobsArray {
            if job.dates.count > 0 {
                let calMDY = getMonthDayYear(date: date)
                let jobStartMDY = getMonthDayYear(date: job.dates[0].installDate)
                let jobEndMDY = getMonthDayYear(date: job.dates[0].endDate)
                
                if date >= job.dates[0].installDate  && date <= job.dates[0].endDate {
                    callback(job)
                } else if jobStartMDY == calMDY || jobEndMDY == calMDY {
                    callback(job)
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
        
        guard let date = visibleDates.monthDates.first?.date else {return}
        
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
            var startDate = ""
            
            startDate = String(currentMonth) + "-" + String(currentDay) + "-" + String(currentYear)
            return startDate
        }
        
        func endDateString() -> String {
            var month = 0
            var day = 0
            var year = 0
            var endDate = ""
            
            if currentDay >= 15 {
                day = currentDay - 14
                if currentMonth == 12 {
                    month = 1
                    year = currentYear + 1
                } else {
                    month = currentMonth + 1
                    year = currentYear
                }
            } else {
                day = currentDay + 14
                month = currentMonth
                year = currentYear
            }
            
            endDate = String(month) + "-" + String(day) + "-" + String(year)
            return endDate
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
        
        formatter.dateFormat = "HH:mm"
        let time = formatter.string(from: adjustedDateTime)
        
        return time
    }
}

