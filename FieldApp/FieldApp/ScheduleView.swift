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

class ScheduleView: UIViewController {
    
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let formatter = DateFormatter()
    var employee: UserData.UserInfo?
    var jobsArray: [Job.UserJob] = []
    let main = OperationQueue.main
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.hidesWhenStopped = true
        calendarView.calendarDelegate = self
        calendarView.calendarDataSource = self
        calendarView.visibleDates { visibleDates in
            self.setUpCalendarViews(visibleDates: visibleDates)
            self.main.addOperation {
                self.activityIndicator.startAnimating()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
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
    
    @IBAction func dismissVC(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension ScheduleView: JTAppleCalendarViewDataSource, JTAppleCalendarViewDelegate {
    
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
                    print(job.jobName)
                }
                i += 1
            }
            completion()
        }
        func setJobInfo() {
            if dateIsEqual == true {
                guard let job = jobsArray[jobIndex] as? Job.UserJob else { return }
                cell.backgroundColor = UIColor.yellow
                cell.jobName.text = job.jobName
            }
        }
        checkJobsDates(cellstateDate: cellState.date, withHandler: setJobInfo)
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
    
    func getMonthDayYearObjs(date: Date) -> DateObj {
        formatter.dateFormat = "MM"
        let month = formatter.string(from: date)
        formatter.dateFormat = "dd"
        let day = formatter.string(from: date)
        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: date)
        let dateObj = DateObj(month: month, day: day, year: year)
        
        return dateObj
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
        var dateIsEqual = false
        var i = 0
        var jobIndex = 0
        
        func checkJobsDates(with completion: () -> Void) {
            
            for job in jobsArray {
                let adjustedDateTime = job.installDate+(28800)
                if adjustedDateTime == cellState.date {
                    dateIsEqual = true
                    jobIndex = i
                }
                i += 1
            }
            completion()
        }
        func setJobInfo() {
            if dateIsEqual == true {
                guard let job = jobsArray[jobIndex] as? Job.UserJob else { return }
                cell.highlightView.isHidden = false
                cell.jobName.text = job.jobName
                print(jobIndex)
            }
        }
        checkJobsDates(with: setJobInfo)
        
        return cell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CalendarCell else {return}
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CalendarCell else {return}
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        setUpCalendarViews(visibleDates: visibleDates)
    }
    
    func setUpCalendarViews(visibleDates: DateSegmentInfo) {
        calendarView.isPrefetchingEnabled = true
        
        calendarView.minimumLineSpacing = 1
        calendarView.minimumInteritemSpacing = 1
        
        guard let date = visibleDates.monthDates.first?.date else {return}
        
        formatter.dateFormat = "yyyy"
        yearLabel.text = formatter.string(from: date)
        formatter.dateFormat = "MMMM"
        monthLabel.text = formatter.string(from: date)
        
    }
    
    
}

