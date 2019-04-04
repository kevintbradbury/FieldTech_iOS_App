//
//  DataStructure.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MapKit

class UserData {
    
    var userID: Int?
    var userName: String?
    var userLocation: CLLocationCoordinate2D?
    var proximityConfirm: Bool?
    var timeIn: Int?
    var timeOut: Int?
    var timerSet: TimeInterval?
    var breakComplete: Bool?
    var overBreak: Bool?
    var punchedIn: Bool?
    var completedWorkPhotos: [UIImage]?
    var locationConfirm: Bool?
    
    struct UserInfoCodeable: Encodable {
        let userName: String
        let employeeID: String
        let coordinateLat: String
        let coordinateLong: String
        let currentRole: String
    }
    
    struct AddressInfo: Codable {
        let address: String?
        let city: String?
        let state: String?
        
        static func fromJSON(dictionary: NSDictionary) -> AddressInfo? {
            guard let address = dictionary["address"] as? String,
             let city = dictionary["city"] as? String,
             let state = dictionary["state"] as? String else {
                print("state address failed to parse"); return nil
            }
            
            return AddressInfo(address: address, city: city, state: state)
        }
    }
    
    struct UserInfo {
        
        let employeeID: Int
        let userName: String
        var employeeJobs: [Job.UserJob]
        var punchedIn: Bool?
        //                let employeePhone: Int?
        //                let workWeekHours: Int?
        //                let userPoints: Int?
        
        static func fromJSON(dictionary: NSDictionary) -> UserInfo? {
            var jobsToAdd = [Job.UserJob]()
            var clocked = false
//            var clocked = false
            
            guard let userId = dictionary["employeeID"] as? Int,
             let jobs = dictionary["employeeJobs"] as? NSArray,
             let userName = dictionary["username"] as? String else {
                print("User Info failed to parse"); return nil
            }
            if let clockInOut = dictionary["punchedIn"] as? Bool {
                clocked = clockInOut
            }
            //                let userNumber = dictionary["phoneNumber"] as? Int,
            //                let weekHours = dictionary["workWeekHours"] as? Int,
            //                let points = dictionary["userPoints"] as? Int,
            //                clocked = clockIn
            
            
            for job in jobs {
                guard let jobDIctionary = job as? NSDictionary,
                    let newJob = Job.UserJob.jsonToDictionary(dictionary:  jobDIctionary) else { continue }
                jobsToAdd.append(newJob)
            }
            
            return UserInfo(
                employeeID: userId, userName: userName, employeeJobs: jobsToAdd, punchedIn: clocked
            )
        }
    }
    
    struct TimeCard {
        
        let weekBeginDate: String?
        let sunday: NSDictionary?
        let monday: NSDictionary?
        let tuesday: NSDictionary?
        let wednesday: NSDictionary?
        let thursday: NSDictionary?
        let friday: NSDictionary?
        let saturday: NSDictionary?
        let totalHours: Int?
        
        static func fromJSON(dictionary: NSDictionary) -> TimeCard? {
            
            guard let beginDate = dictionary["weekBeginDate"] as? String,
                let sunday = dictionary["sunday"] as? NSDictionary,
                let monday = dictionary["monday"] as? NSDictionary,
                let tuesday = dictionary["tuesday"] as? NSDictionary,
                let wednesday = dictionary["wednesday"] as? NSDictionary,
                let thursday = dictionary["thursday"] as? NSDictionary,
                let friday = dictionary["friday"] as? NSDictionary,
                let saturday = dictionary["saturday"] as? NSDictionary,
                let total = dictionary["totalHours"] as? Int
                else {
                    print("failed fromJSON method, in TimeCard Struct")
                    return nil
            }
            
            return TimeCard(
                weekBeginDate: beginDate,
                sunday: sunday,
                monday: monday,
                tuesday: tuesday,
                wednesday: wednesday,
                thursday: thursday,
                friday: friday,
                saturday: saturday,
                totalHours: total
            )
        }
    }
}


class Job: Codable {
    
    var jobName: String?, poNumber: String?, jobLocation: [Double]?
    
    struct UserJob {
        
        let poNumber: String
        let jobName: String
        let dates: [JobDates]
        let jobLocation: CLLocationCoordinate2D
        let jobAddress: String, jobCity: String, jobState: String
        let projCoord: String
        let fieldLead: String
        let supervisor: String
        let assignedEmployees: [String]
        
        struct JobDates {
            let installDate: Date, endDate: Date
        }
        
        static func jsonToDictionary(dictionary: NSDictionary) -> UserJob? {
            
            guard let purchaseOrderNumber = dictionary["poNumber"] as? String,
                let jobName = dictionary["name"] as? String else {
                    print("couldnt parse storeName or poNumber"); return nil
            }
            
            var coordinates = CLLocationCoordinate2D()
            var address = "", city = "", state = "", coordinator = "", fieldLead = "", supervisor = "", assignedEmployees = [""]
            let dates = checkForArray(datesObj: dictionary["dates"], dictionary: dictionary)
            
            if let location = dictionary["jobLocation"] as? [Double] {
                var lat = CLLocationDegrees(0.0), long = CLLocationDegrees(0.0)
                
                if location.count > 1 {
                    lat = CLLocationDegrees(location[0])
                    long = CLLocationDegrees(location[1])
                }
                coordinates = CLLocationCoordinate2D(latitude: lat, longitude: long)
            }
            
            if let addressAsString = dictionary["jobAddress"] as? String,
                let cityAsString = dictionary["jobCity"] as? String,
                let stateAsString = dictionary["jobState"] as? String {
                
                address = addressAsString
                city = cityAsString
                state = stateAsString
            }
            
            if let projC = dictionary["projCoord"] as? String { coordinator = projC }
            if let json_fieldLd = dictionary["fieldLead"] as? String { fieldLead = json_fieldLd }
            if let json_super = dictionary["supervisor"] as? String { supervisor = json_super }
            if let json_employees = dictionary["assignedEmployees"] as? [String] {
                assignedEmployees = json_employees
            }
            
            return UserJob(
                poNumber: purchaseOrderNumber, jobName: jobName, dates: dates, 
                jobLocation: coordinates, jobAddress: address, jobCity: city, jobState: state, 
                projCoord: coordinator, fieldLead: fieldLead, supervisor: supervisor, assignedEmployees: assignedEmployees
                )
        }
        
        static func stringToDate(string: String) -> Date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
            
            guard let dateString = dateFormatter.date(from: string) else { fatalError("failed to cast string to type: date") }
            
            return dateString
        }
        
        static func checkForArray(datesObj: Any?, dictionary: NSDictionary) -> [JobDates] {
            var dates = [JobDates]()
            
            func handleJustDates() -> [JobDates] {
                var _ = ""
                guard let start = dictionary["installDate"] as? String else { return dates }
                guard let end = dictionary["endDate"] as? String else {
                    
                    let complete = stringToDate(string: start) + (86400)  // if no endDate, make end 24hrs * 60min * 60sec after start
                    let dtObj = JobDates(installDate: stringToDate(string: start), endDate: complete)
                    dates.append(dtObj)
                    
                    return dates
                }
                
                let dtObj = JobDates(installDate: stringToDate(string: start), endDate: stringToDate(string: end))
                dates.append(dtObj)
                
                return dates
            }
            
            if datesObj is [Any] {
                guard let datesCollection = datesObj as? [Dictionary<String, Any>] else { return dates }
                
                for i in datesCollection {
                    guard let start = i["installDate"] as? String else { return handleJustDates() }
                    guard let end = i["endDate"] as? String else { return handleJustDates() }

                    let startEnd = JobDates(installDate: stringToDate(string: start), endDate: stringToDate(string: end))
                    
                    dates.append(startEnd)
                }
            } else { handleJustDates() }
            
            return dates
        }
    }
}

class FieldActions {
    
    var formType: String?
    var jobName: String?
    var poNumber: String?
    var requestedBy: String?
    var location: String? // Address?
    var material: String?
    var colorSpec: String?
    var quantity: Double?
    var neededBy: Double? // Seconds from 1970
    var description: String?
    let hardwareLocations: Array = ["Ace", "Lowe's", "Orchard", "Harbor", "TheHome"]
    let maxDistance = 5  // Miles?
    

    
    struct SuppliesRequest: Encodable {
        var formType: String?
        var jobName: String?
        var poNumber: String?
        var requestedBy: String?
        var location: String?
        var neededBy: Double? // Seconds from 1970
        var description: String?
        var suppliesCollection: [MaterialQuantityColor]
        
        struct MaterialQuantityColor: Encodable {
            var quantity: Double
            var material: String
            var color:  String
        }
    }
    
    struct ToolRental: Encodable {
        var formType: String?
        var jobName: String?
        var poNumber: String?
        var requestedBy: String?
        var toolType: String?
        var brand: String?
        var duration: Int? // Number of Days
        var quantity: Double?
        var neededBy: Double? // Seconds from 1970
        var location: String?
        
        let reminderPeriods = [24, 48, 72, 96]
    }
    
    struct  ChangeOrders: Encodable {
        var formType: String?
        var jobName: String?
        var poNumber: String?
        var requestedBy: String?
        var location: String? // Address?
        var material: String?
        var colorSpec: String?
        var quantity: Double?
        var neededBy: Double? // Seconds from 1970
        var description: String?
    }
    
    
    struct VehicleChecklist: Encodable {
        var username: String
        var department: String
        var licensePlate: String
        var date: Double
        var outsideInspection: OutsideInspection
        var startupInspection: StartupInspection
        var issuesReport: String
        
        struct OutsideInspection: Encodable {
            var windows: Bool
            var tiresNnuts: Bool
            var engine: Bool
            var litesNsignals: Bool
            var mirrors: Bool
            var windshieldNwipres: Bool
            var dents: Bool
            var exteriorComments: String
        }
        
        struct StartupInspection: Encodable {
            var engine: Bool
            var gauges: Bool
            var wipers: Bool
            var horn: Bool
            var brakes: Bool
            var seatbelt: Bool
            var insuranceNregist: Bool
            var firstAidKit: Bool
            var clean: Bool
            var startupComments: String
        }
    }
    
    static func fromJSONtoTool(json: Any) -> ([FieldActions.ToolRental], [UIImage]) {
        var boxOtools = [FieldActions.ToolRental]()
        var toolImages = [UIImage]()
        
        if let tools = json as? Array<Any> {
            
            for oneTool in tools {
                
                if let dictionary = oneTool as? Dictionary<String, Any>,
                    let formType = dictionary["formType"] as? String,
                    let jobName = dictionary["jobName"] as? String,
                    let poNumber = dictionary["poNumber"] as? String,
                    let requestedBy = dictionary["requestedBy"] as? String,
                    let toolType = dictionary["toolType"] as? String,
                    let brand = dictionary["brand"] as? String,
                    let duration = dictionary["duration"] as? Int,
                    let neededBy = dictionary["neededBy"] as? String,
                    let quantity = dictionary["quantity"] as? Int,
                    let location = dictionary["location"] as? String,
                    let _ = dictionary["returnDate"] as? String,
                    let photoStr = dictionary["photo"] as? String,
                    let photoDecoded = Data(base64Encoded: photoStr, options: .ignoreUnknownCharacters),
                    let image = UIImage(data: photoDecoded) {
                        let neededDate = Job.UserJob.stringToDate(string: neededBy)
                        let needDouble = neededDate.timeIntervalSince1970
                    
                    let toolToAdd = FieldActions.ToolRental(
                        formType: formType, jobName: jobName, poNumber: poNumber, requestedBy: requestedBy, toolType: toolType, brand: brand, duration: duration, quantity: Double(quantity), neededBy: needDouble, location: location
                    )
                    boxOtools.append(toolToAdd)
                    toolImages.append(image)
                }
            }
        }
        
        return (boxOtools, toolImages)
    }
    
    static func getDateFromISOString(isoDate: String) -> Date {
        let adjStr = isoDate.components(separatedBy: "T")
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd" // 'T'HH:mm:ssZZZZZ
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let actualDate = dateFormatter.date(from: adjStr[0]) else {
                print("unable to change ISOstring to Date"); return Date()
        }
        return actualDate
    }
}

struct Holiday: Decodable {
    let date: String
    let start: Date
    let end: Date
    let name: String
    let type: String
    
    static func parseJson(dictionary: NSDictionary) -> Holiday {
        let hldy = Holiday(date: "", start: Date(), end: Date(), name: "", type: "")
        
        guard let date = dictionary["date"] as? String,
        let start = dictionary["start"] as? String,
        let end = dictionary["end"] as? String,
        let name = dictionary["name"] as? String,
        let type = dictionary["type"] as? String else {
            print("unable to parse Holiday dictionary: \n\(dictionary)")
            return hldy
        }
        
        return Holiday(
            date: date, start: FieldActions.getDateFromISOString(isoDate: start), end: FieldActions.getDateFromISOString(isoDate: end), name: name, type: type
        )
    }
}

struct TimeOffReq: Encodable  {
    let username: String
    let employeeID: Int
    let department: String
    let shiftHours: String
    let start: Double
    let end: Double
    let signedDate: Double
    let approved: Bool?
    
    static func parseJson(dictionary: NSDictionary) -> TimeOffReq {
        let timeOffReq = TimeOffReq(
            username: "", employeeID: 0, department: "", shiftHours: "", start: 0, end: 0, signedDate: 0, approved: nil
        )
        var approved: Bool?
        
        guard let username = dictionary["username"] as? String,
            let employeeID = dictionary["employeeID"] as? String,
            let department = dictionary["department"] as? String,
            let shiftHours = dictionary["shiftHours"] as? String,
            let start = dictionary["start"] as? String,
            let end = dictionary["end"] as? String,
            let signed = dictionary["signedDate"] as? String else {
                print("unable to parse timeOffReq \(dictionary)"); return timeOffReq
        }
        
        if dictionary["approved"] != nil {
            approved = dictionary["approved"] as? Bool
        }
        
        let startDt = FieldActions.getDateFromISOString(isoDate: start)
        let endDt = FieldActions.getDateFromISOString(isoDate: end)
        let signedDt = FieldActions.getDateFromISOString(isoDate: signed)
        
        return TimeOffReq(
            username: username, employeeID: Int(employeeID) ?? 0,
            department: department, shiftHours: shiftHours,
            start: startDt.timeIntervalSince1970, end: endDt.timeIntervalSince1970,
            signedDate: signedDt.timeIntervalSince1970, approved: approved
        )
    }
}


struct SafetyQuestion: Encodable {
    var question: String
    var options: answerOptions
    var answer: String

    struct answerOptions: Encodable { var a: String; var b: String; var c: String; var d: String }
    
    static func jsonToSQ(dictionary: NSDictionary) -> SafetyQuestion {
        
        guard let question = dictionary["question"] as? String,
            let answerOptions = dictionary["options"] as? NSDictionary,
            let a = answerOptions["a"] as? String,
            let b = answerOptions["b"] as? String,
            let c = answerOptions["c"] as? String,
            let d = answerOptions["d"] as? String,
            let answer = dictionary["answer"] as? String else {
                print("failed to parse safetyQuestion")
                return SafetyQuestion(
                    question: "", options: SafetyQuestion.answerOptions(a: "", b: "", c: "", d: ""), answer: ""
                )
        }
        let options = SafetyQuestion.answerOptions(a: a, b: b, c: c, d: d)
        
        return SafetyQuestion(question: question, options: options, answer: answer)
    }
}





