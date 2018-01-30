//
//  DataStructure.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

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
    
    struct UserInfo: Encodable {
        
        let employeeID: Int
        let employeeJobs: [String]
        let userName: String
        let punchedIn: Bool?
        //                let employeePhone: Int?
        //                let workWeekHours: Int?
        //                let userPoints: Int?
        
        
        static func fromJSON(dictionary: NSDictionary) -> UserInfo? {
            
            guard let userId = dictionary["employeeID"] as? Int,
                let jobs = dictionary["employeeJobs"] as? NSArray,
                let userName = dictionary["username"] as? String,
                let clockIn = dictionary["punchedIn"] as? Bool
                //                let userNumber = dictionary["phoneNumber"] as? Int,
                //                let weekHours = dictionary["workWeekHours"] as? Int,
                //                let points = dictionary["userPoints"] as? Int,  
                else {
                    print("failed fromJSON method, in UserInfo Struct")
                    return nil
            }
            
            return UserInfo(employeeID: userId, employeeJobs: jobs as! [String], userName: userName, punchedIn: clockIn)
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
    var poNumber: Int?
    
    struct UserJob {
        
        let poNumber: Int
        let jobName: String
        let installDate: Date
        let jobLocation: CLLocationCoordinate2D?
        
//        let jobAddress: String
//        let jobCity: String
//        let jobState: String
//        let jobBudgetHours: String?
//        let employeeJobHours: String?
        
        static func jsonToDictionary(dictionary: NSDictionary) -> UserJob? {
            
            guard let date = dictionary["installDate"] as? String else { print("couldnt parse dateObject")
                return nil }
            guard let location = dictionary["jobLocation"] as? [Double] else { print("couldnt parse jobLocation")
                return nil }
            guard let purchaseOrderNumber = dictionary["poNumber"] as? Int else { print("couldnt parse poNumber")
                return nil }
            guard let jobName = dictionary["storeName"] as? String else { print("couldnt parse storeName")
                return nil }
                
//                let address = dictionary["Address"] as? String,
//                let city = dictionary["City"] as? String,
//                let state = dictionary["State"] as? String,
//                let budgetHours = dictionary["jobBudgetHours"] as? String,
//                let employeeHours = dictionary["employeeJobHours"] as? String
            
//            else {
//                print("failed fromJSON method, in UserJobs Struct")
//                return nil
//            }

            var coordinates = CLLocationCoordinate2DMake(0.0, 0.0)
//            if let latitude = Double(location[0]),
//                let longitude = Double(location[1]){
                coordinates = CLLocationCoordinate2D(latitude: location[0], longitude: location[1])
//            }
            let dateString = stringToDate(string: date)
//            guard let po = Int(purchaseOrderNumber) else {
//                fatalError()
//            }
            
            return UserJob(poNumber: purchaseOrderNumber, jobName: jobName, installDate: dateString, jobLocation: coordinates)
        }
        
        static func stringToDate(string: String) -> Date {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            guard let dateString = dateFormatter.date(from: string) else {
                fatalError("failed to cast string to type: date")
            }
            
            return dateString
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




