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
    
    let formatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calendarView.calendarDelegate = self
        calendarView.calendarDataSource = self
        calendarView.visibleDates { visibleDates in
            self.setUpCalendarViews(visibleDates: visibleDates)
        }
    }
}

extension ScheduleView: JTAppleCalendarViewDataSource, JTAppleCalendarViewDelegate {
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        
        let cell = cell as! CalendarCell
        
        cell.dateLabel.text = cellState.text
    }
    
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        formatter.dateFormat = "MM dd yyyy"
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Calendar.current.locale
        
        let date = Date()
        let currentCalendar = Calendar.current
        let currentYear = currentCalendar.component(.year, from: date)
        let currentMonth = currentCalendar.component(.month, from: date)
        
        func startDateString() -> String {
            var month = 0
            var year = 0
            var startDate = ""
            
            if currentMonth >= 07 {
                month = currentMonth - 6
                year = currentYear
            } else if currentMonth < 07 {
                month = currentMonth + 6
                year = currentYear - 1
            }
            
            startDate = String(month) + " 01 " + String(year)
            print("startDate string -- \(startDate)")
            return startDate
        }
        
        func endDateString() -> String {
            var month = 0
            var year = 0
            var endDate = ""
            
            if currentMonth >= 07 {
                month = currentMonth - 6
                year = currentYear + 1
            } else if currentMonth < 07 {
                month = currentMonth + 6
                year = currentYear
            }
            
            endDate = String(month) + " 01 " + String(year)
            print("endDateString is -- \(endDate)")
            return endDate
        }
        
        let startDate = formatter.date(from: startDateString())
        let endDate = formatter.date(from: endDateString())
        
        let parameters = ConfigurationParameters(startDate: startDate!,
                                                 endDate: endDate!,
                                                 numberOfRows: 6,
                                                 calendar: Calendar.current,
                                                 generateInDates: .forAllMonths,
                                                 generateOutDates: .tillEndOfGrid,
                                                 firstDayOfWeek: .sunday)
        
        return parameters
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "customCalendarCell", for: indexPath) as! CalendarCell
        
        cell.dateLabel.text = cellState.text
        
        if cellState.dateBelongsTo == .thisMonth {
            cell.dateLabel.textColor = UIColor.black
        } else {
            cell.dateLabel.textColor = UIColor.white
        }
        
        return cell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CalendarCell else {return}
        
        validCell.backgroundColor = UIColor.cyan
    }
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CalendarCell else {return}
        
        validCell.backgroundColor = UIColor.lightGray
    }
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        setUpCalendarViews(visibleDates: visibleDates)
    }
    
    func setUpCalendarViews(visibleDates: DateSegmentInfo) {
        
        calendarView.minimumLineSpacing = 0
        calendarView.minimumInteritemSpacing = 0
        
        guard let date = visibleDates.monthDates.first?.date else {return}
        
        formatter.dateFormat = "yyyy"
        yearLabel.text = formatter.string(from: date)
        formatter.dateFormat = "MMMM"
        monthLabel.text = formatter.string(from: date)
        
    }
}

