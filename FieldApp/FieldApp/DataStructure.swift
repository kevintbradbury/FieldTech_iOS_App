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
    //keys set to minutes, values set to seconds
    let timer: NSDictionary = [
        15 : 600,
        30 : 1500,
        45 : 2400,
        60 : 3000
    ]
    var timerSet: TimeInterval?
    var breakComplete: Bool?
    var overBreak: Bool?
    var punchedIn: Bool?
    var completedWorkPhotos: [UIImage]?
    var locationConfirm: Bool?
    
    
    
    struct UserInfo {
        
        let employeeID: Int
        let employeeJobs: [Job.UserJob]
        let userName: String
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
            
            for job in jobsToAdd { print(job) }
            //                let userNumber = dictionary["phoneNumber"] as? Int,
            //                let weekHours = dictionary["workWeekHours"] as? Int,
            //                let points = dictionary["userPoints"] as? Int,
            
            return UserInfo(employeeID: userId, employeeJobs: jobsToAdd, userName: userName, punchedIn: clocked)
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
        let dates: [Date]
        let jobLocation: CLLocationCoordinate2D
        
        //        let jobAddress: String
        //        let jobCity: String
        //        let jobState: String
        //        let employeeJobHours: String?
        
        static func jsonToDictionary(dictionary: NSDictionary) -> UserJob? {
            
            guard let purchaseOrderNumber = dictionary["poNumber"] as? String else {
                print("couldnt parse poNumber")
                return nil
            }
            guard let jobName = dictionary["name"] as? String else {
                print("couldnt parse storeName")
                return nil
            }
            
            var lat = CLLocationDegrees()
            var long = CLLocationDegrees()
            var coordinates = CLLocationCoordinate2D()
            var dates = [Date()]
            
            if let location = dictionary["jobLocation"] as? [Double] {
                lat = CLLocationDegrees(location[0])
                long = CLLocationDegrees(location[1])
                coordinates = CLLocationCoordinate2D()
                coordinates.latitude = lat
                coordinates.longitude = long
                dates = checkForArray(datesObj: dictionary["dates"], dictionary: dictionary)
            }
            
            //                let address = dictionary["Address"] as? String,
            //                let city = dictionary["City"] as? String,
            //                let state = dictionary["State"] as? String,
            //                let budgetHours = dictionary["jobBudgetHours"] as? String,
            //                let employeeHours = dictionary["employeeJobHours"] as? String
            
            return UserJob(poNumber: purchaseOrderNumber, jobName: jobName, dates: dates, jobLocation: coordinates)
        }
        
        static func stringToDate(string: String) -> Date {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            guard let dateString = dateFormatter.date(from: string) else {
                fatalError("failed to cast string to type: date")
            }
            
            return dateString
        }
        
        static func checkForArray(datesObj: Any, dictionary: NSDictionary) -> [Date]{
            var dates = [Date]()
            
            if datesObj is [Any] {
                guard let datesCollection = datesObj as? [Dictionary<String, Any>] else { print("couldnt cast datesinto an array"); return dates}
                for i in datesCollection {
                    guard let install = i["installDate"] as? String else { print("couldnt cast install date from array to string"); return dates}
                    let date = stringToDate(string: install)
                    dates.append(date)
                }
            } else {
                guard let install = dictionary["installDate"] as? String else { print("couldnt cast date to string"); return dates}
                let date = stringToDate(string: install)
                dates.append(date)
            }
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
    
    var requestedUser: String?
    var poNumber: Int?
    let poFolder = URL(string: "P O Server Folder")
    var date: Date?
    var jobName: String?
    var neededBy: String?
    var description: String?
    
    class SuppliesRequest {
        
        let hardwareLocations: Array = ["Home Depot", "Lowes", "Ace Hardware", "Orchards"]
        var chosenLocation: String?
        let maxDistance = 5  // Miles?
        var receiptPhoto = UIImage()
        var arrived: Bool?
        let material: Array = ["material1", "material2", "etc."]
        var materialQuantity: Int?
        var receiptUploaded: Bool?
        var fieldSuppliesDestinationFolder = URL(string: "Supplies Server Folder")
        
    }
    
    class ToolRental {
        
        let toolType: Array = ["drill", "hammer", "powerTools", "etc."]
        let brand = ["brand1", "brand2", "brand3"]
        var toolQuantity: Int?
        var duration: Int?
        var toolPhoto: UIImage?
        var photoUploaded: Bool?
        let rentalLogDestination = URL(string: "Tool Rental Server Folder")
        let supervisorEmail = "super@millworkbrothers.com"
        var rentalIn: Date?
        var rentalOut: Date? //This value is to record the actual return date.
        var returnDate: Date? //This is the user entered date value.
        let reminderPeriods = [24, 48, 72, 96]
        var rentalAuthorized: Bool?
        
    }
    
    class ChangeOrders {
        
        var location: String? //Field Installers reference OR documentation purposes?
        var material: String?
        var colorSpec: String?
        var quantity: Int?
        
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

class Geotification: NSObject, NSCoding, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDistance
    var identifier: String
    var note: String
    var eventType: EventType
    
    var title: String? {
        if note.isEmpty {
            return "no note"
        }
        return note
    }
    init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String, note: String, eventType: EventType) {
        self.coordinate = coordinate
        self.radius = radius
        self.identifier = identifier
        self.note = note
        self.eventType = eventType
    }
    required init?(coder decoder: NSCoder) {
        let latitude = decoder.decodeDouble(forKey: GeoKey.latitude)
        let longitude = decoder.decodeDouble(forKey: GeoKey.longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        radius = decoder.decodeDouble(forKey: GeoKey.radius)
        identifier = decoder.decodeObject(forKey: GeoKey.identifier) as! String
        note = decoder.decodeObject(forKey: GeoKey.note) as! String
        eventType = EventType(rawValue: decoder.decodeObject(forKey: GeoKey.eventType)as! String)!
    }
    func encode(with coder: NSCoder) {
        coder.encode(coordinate.latitude, forKey: GeoKey.latitude)
        coder.encode(coordinate.longitude, forKey: GeoKey.longitude)
        coder.encode(radius, forKey: GeoKey.radius)
        coder.encode(identifier, forKey: GeoKey.identifier)
        coder.encode(note, forKey: GeoKey.note)
        coder.encode(eventType.rawValue, forKey: GeoKey.eventType)
    }
}


