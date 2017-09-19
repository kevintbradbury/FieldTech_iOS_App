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
    var distanceFromJob: Int?
    var proximityConfirm: Bool?
    var timeIn: Int?
    var timeOut: Int?
    //field set to minutes, values set to minutes
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
    
    struct UserJobInfo {
        
        let userName: String
        let workWeekHours: Int?
        let userPoints: Int?
        let employeeJobs: NSArray
        
        static func fromJSON(dictionary: NSDictionary) -> UserJobInfo? {
            
            guard let userName = dictionary["userName"] as? String,
                let weekHours = dictionary["workWeekHours"] as? Int,
                let points = dictionary["userPoints"] as? Int,
                let jobs = dictionary["employeeJobs"] as? NSArray
                else {
                    print("failed fromJSON method, in TimeInOut Struct")
                    return nil
            }
            
            return UserJobInfo(userName: userName, workWeekHours: weekHours, userPoints: points, employeeJobs: jobs)
        }
    }
}

class Job {
    
    var jobName: String?
    var poNumber: Int?
    
    struct UserJob {
        
        let jobName: String
        let poNumber: Int
        let jobBudgetHours: Double?
        let employeeJobHours: Double?
        let jobAddress: String
        let jobCity: String
        let jobLocation: CLLocationCoordinate2D
        
        static func jsonToDictionary(dictionary: NSDictionary) -> UserJob? {
            
            guard let jobName = dictionary["jobName"] as? String,
                let purchaseOrderNumber = dictionary["purchaseOrderNumber"] as? Int,
                let budgetHours = dictionary["jobBudgetHours"] as? Double,
                let employeeHours = dictionary["employeeJobHours"] as? Double,
                let address = dictionary["jobAddress"] as? String,
                let city = dictionary["jobCity"] as? String,
                let location = dictionary["jobLocation"] as? NSDictionary
                else {
                    print("failed fromJSON method, in UserJobs Struct")
                    return nil
            }
            guard let latitude = location["latitude"] as? CLLocationDegrees else {return nil}
            guard let longitude = location["longitude"] as? CLLocationDegrees else {return nil}
            let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            return UserJob(jobName: jobName, poNumber: purchaseOrderNumber, jobBudgetHours: budgetHours, employeeJobHours: employeeHours, jobAddress: address, jobCity: city, jobLocation: coordinates)
        }
    }
    
}

class ContactInfo {
    
    let departmentEmail = "admin@millworkbrothers.com"
    let faxNumber = 123
    let textNumbers: NSDictionary = [
        "Pete" : 123,
        "Natalie" : 123,
        "Jesus" : 123,
        "Office" : 123
    ]
    
}

class FieldUtilities {

    var requestedUser: String?
    
class SuppliesRequests {
    
    let hardwareLocations: Array = ["Home Depot", "Lowes", "Ace Hardware", "Orchards"]
    var chosenLocation: String?
    let maxDistance = 5  // Miles?
    var receiptPhoto = UIImage()
    var arrived: Bool?
    var poNumber: Int?
    let poFolder = URL(string: "P O Server Folder")
    var jobName: String?
    
    let material: Array = ["material1", "material2", "etc."]
    var materialQuantity: Int?
    var neededBy: String?
    var description: String?
    var receiptUploaded: Bool?
    var fieldSuppliesDestinationFolder = URL(string: "Supplies Server Folder")
    
}

class ToolRental {
    
    var requestedUser: String?
    let toolType: Array = ["drill", "hammer", "powerTools", "etc."]
    let brand = ["brand1", "brand2", "brand3"]
    var quantity: Int?
    
    
}

}
