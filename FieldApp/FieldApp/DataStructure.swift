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
            
            guard let userId = dictionary["employeeID"] as? Int else { print("employeeID failed to parse"); return nil}
            guard let jobs = dictionary["employeeJobs"] as? NSArray else { print("employeejobs  failed to parse"); return nil}
            guard let userName = dictionary["username"] as? String else { print("username  failed to parse"); return nil }
            guard let clockIn = dictionary["punchedIn"] as? Bool else { print("clockin failed to parse"); return nil }
            clocked = clockIn
            
            for job in jobs {
                guard let newJob = Job.UserJob.jsonToDictionary(dictionary: job as! NSDictionary) else { return nil }
                jobsToAdd.append(newJob)
            }
            
            //                let userNumber = dictionary["phoneNumber"] as? Int,
            //                let weekHours = dictionary["workWeekHours"] as? Int,
            //                let points = dictionary["userPoints"] as? Int,
            
            return UserInfo(employeeID: userId, userName: userName, employeeJobs: jobsToAdd, punchedIn: clocked)
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
            
            return TimeCard(weekBeginDate: beginDate, sunday: sunday, monday: monday, tuesday: tuesday, wednesday: wednesday, thursday: thursday, friday: friday, saturday: saturday, totalHours: total)
        }
    }
}


class Job: Codable {
    
    var jobName: String?
    var poNumber: String?
    var jobLocation: [Double]?
    
    struct UserJob {
        
        let poNumber: String
        let jobName: String
        let dates: [JobDates]
        let jobLocation: CLLocationCoordinate2D
        let jobAddress: String
        let jobCity: String
        let jobState: String
        let projCoord: String
        
        struct JobDates {
            let installDate: Date
            let endDate: Date
        }

//        let employeeJobHours: String?
        
        static func jsonToDictionary(dictionary: NSDictionary) -> UserJob? {
            
            guard let purchaseOrderNumber = dictionary["poNumber"] as? String else { print("couldnt parse poNumber"); return nil }
            guard let jobName = dictionary["name"] as? String else { print("couldnt parse storeName"); return nil }
            
            var lat = CLLocationDegrees()
            var long = CLLocationDegrees()
            var coordinates = CLLocationCoordinate2D()
            var address = "", city = "", state = "", coordinator = ""
            let dates = checkForArray(datesObj: dictionary["dates"], dictionary: dictionary)
            
            if let location = dictionary["jobLocation"] as? [Double] {
                lat = CLLocationDegrees(location[0])
                long = CLLocationDegrees(location[1])
                coordinates = CLLocationCoordinate2D()
                coordinates.latitude = lat
                coordinates.longitude = long
                
                print(dictionary["jobAddress"])
                
                if let addressAsString = dictionary["jobAddress"] as? String,
                    let cityAsString = dictionary["jobCity"] as? String,
                    let stateAsString = dictionary["jobState"] as? String {
//                    print("job address from server: \(addressAsString)")
                    
                    address = addressAsString
                    city = cityAsString
                    state = stateAsString
                    
                    if let projC = dictionary["projCoord"] as? String { coordinator = projC }
                }
            }
            
            //                let budgetHours = dictionary["jobBudgetHours"] as? String,
            //                let employeeHours = dictionary["employeeJobHours"] as? String
            
            return UserJob(poNumber: purchaseOrderNumber, jobName: jobName, dates: dates, jobLocation: coordinates, jobAddress: address, jobCity: city, jobState: state, projCoord: coordinator)
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
                var endString = ""
                guard let start = dictionary["installDate"] as? String else { return dates }
                guard let end = dictionary["endDate"] as? String else {
                    
                    var complete = stringToDate(string: start) + (86400)  // if no endDate, make end 24hrs * 60min * 60sec after start
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

class ContactInfo {
    
    let departmentEmail = "admin@millworkbrothers.com"
    let faxNumber: Int64 = 5628021113
    let textNumbers: [String:Int64] = [
        "Pete" : 123,
        "Natalie" : 123,
        "Jesus" : 123,
        "Office" : 5625842155
    ]
    
}

class FieldActions {
    
    let poFolder = URL(string: "P O Server Folder")
    var requestedUser: String?
    var poNumber: Int?
    var date: Date?
    var jobName: String?
    var neededBy: String?
    var description: String?
    
    struct SuppliesRequest {
        let hardwareLocations: Array = ["Home Depot", "Lowes", "Ace Hardware", "Orchards"]
        let maxDistance = 5  // Miles?
        let material: Array = ["material1", "material2", "etc."]
        var chosenLocation: String?
        var receiptPhoto = UIImage()
        var arrived: Bool?
        var materialQuantity: Int?
        var receiptUploaded: Bool?
        var fieldSuppliesDestinationFolder = URL(string: "Supplies Server Folder")
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
                    let returnDate = dictionary["returnDate"] as? String,
                    let photoStr = dictionary["photo"] as? String,
                    let photoDecoded = Data(base64Encoded: photoStr, options: .ignoreUnknownCharacters),
                    let image = UIImage(data: photoDecoded),
                    let neededDate = Job.UserJob.stringToDate(string: neededBy) as? Date,
                    let needDouble = neededDate.timeIntervalSince1970 as? Double {
                    
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
    
    class PhotoUpload {
        
        var projectPhotos: [UIImage]?
        let presetEmail = "supervisor@millworkbrothers.com"
    }
    
}

struct GeoKey {
    static let latitude = "latitude"
    static let longitude = "longitude"
    static let radius = "radius"
    static let identifier = "identifier"
    static let note = "note"
    static let eventType = "eventType"
}

enum EventType: String {
    case onEntry = "On Entry"
    case onExit = "On Exit"
}



