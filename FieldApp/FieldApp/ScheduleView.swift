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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    @IBAction func dismissVC(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goGetDirections(_ sender: Any) {
        if jobNameLbl.text != "" {
            checkForJob(name: jobNameLbl.text!) { matchingJob in
                openMapsWithDirections(to: matchingJob.jobLocation!, destination: matchingJob.jobName)
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
                self.jobsArray.sort {
                    ($0.installDate < $1.installDate)
                }
                print(self.jobsArray)
                self.main.addOperation {
                    self.activityIndicator.stopAnimating()
                    self.calendarView.reloadData()
                }
            }
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        
        let cell = cell as! CalendarCell
        
        cell.dateLabel.text = cellState.text
        
        if cellState.dateBelongsTo != .thisMonth {
            cell.dateLabel.textColor = UIColor.lightGray
        } else {
            cell.dateLabel.textColor = UIColor.black
        }
        
        var dateIsEqual = false
        var i = 0
        var jobIndex = 0
        
        func checkJobsDates(cellstateDate: Date, withHandler completion: () -> Void) {
            
            for job in jobsArray {
                let adjustedDateTime = job.installDate+(28800)
                if adjustedDateTime == cellstateDate {
                    dateIsEqual = true
                    jobIndex = i
                }
                i += 1
            }
            completion()
        }
        func setJobInfo() {
            if dateIsEqual == true {
                let job = jobsArray[jobIndex]
                cell.backgroundColor = UIColor.yellow
                cell.jobName.text = job.jobName
            }
        }
        checkJobsDates(cellstateDate: cellState.date, withHandler: setJobInfo)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "customCalendarCell", for: indexPath) as! CalendarCell
        
        cell.dateLabel.text = cellState.text
        cell.highlightView.isHidden = true
        
        if cellState.dateBelongsTo != .thisMonth {
            cell.dateLabel.textColor = UIColor.lightGray
            cell.backgroundColor = UIColor.white
        } else {
            cell.backgroundColor = UIColor.white
        }
        
        checkJobsDates(date: cellState.date) { matchingJob in
            cell.highlightView.isHidden = false
            cell.jobName.text = matchingJob.jobName
        }
        
        return cell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CalendarCell else {return}
        
        checkJobsDates(date: cellState.date) {matchingJob in
            let installDate = getMonthDayYear(date: matchingJob.installDate)
            
            self.jobNameLbl.text = matchingJob.jobName
            self.poNumberLbl.text = "PO# " + String(matchingJob.poNumber)
            self.installDateLbl.text = installDate
            self.directionsBtn.isHidden = false
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
            let adjustedDateTime = job.installDate+(28800)
            if adjustedDateTime == date {
                guard let matchingJob = job as? Job.UserJob else { return }
                callback(matchingJob)
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
    
    struct DateObj {
        let month: String
        let day: String
        let year: String
    }
    
    func getMonthDayYear(date: Date) -> String {
        print( date.description(with: Locale(identifier: "en")) )
        let adjustedDateTime = date + (28800)
        print(adjustedDateTime)
        //since mongoDB defaults to UTC or GMT 0, and time is set for midnight UTC, that defaults to 4pm PST one day before, this could be resolved by setting DB local to PST and setting specific start time
        
        formatter.dateFormat = "MMM"
        let month = formatter.string(from: adjustedDateTime)
        formatter.dateFormat = "dd"
        let day = formatter.string(from: adjustedDateTime)
        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: adjustedDateTime)
        let dateString = month + " " + day + ", " + year
        
        return dateString
    }
}

