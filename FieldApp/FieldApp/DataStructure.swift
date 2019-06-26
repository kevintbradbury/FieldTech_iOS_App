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
import MLPAutoCompleteTextField


struct UsernameAndPassword: Codable {
    let username: String
    let password: String
    
    static func saveIdUserAndPasswd(userNpass: UsernameAndPassword, employeeId: String, cb: @escaping(UsernameAndPassword) -> () ) {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("UsernameAndPassword.plist")
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        do {
            let data = try encoder.encode(userNpass)
            try data.write(to: path)
            
            UserDefaults.standard.set(employeeId, forKey: "employeeID")
            UsernameAndPassword.getUsernmAndPasswd() { usrNpass in
                cb(userNpass)
            }
        } catch {
            print("Error encoding username and password with error: \(error).")
        }
    }
    
    static func getUsernmAndPasswd(cb: @escaping (UsernameAndPassword)->()) {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("UsernameAndPassword.plist")
        
        do {
            let decoder = PropertyListDecoder()
            guard let data = try? Data(contentsOf: path),
                let userNpass = try? decoder.decode(UsernameAndPassword.self, from: data) else { return }
            
            cb(userNpass)
        } catch {
            print("Couldn't find saved username or password.")
        }
    }
}

class UserData {
    
    var userID: Int?,
    userName: String?,
    userLocation: CLLocationCoordinate2D?,
    proximityConfirm: Bool?,
    timeIn: Int?,
    timeOut: Int?,
    timerSet: TimeInterval?,
    breakComplete: Bool?,
    overBreak: Bool?,
    punchedIn: Bool?,
    completedWorkPhotos: [UIImage]?,
    locationConfirm: Bool?
    
    struct UserInfoCodeable: Encodable {
        let userName: String,
        employeeID: String,
        coordinateLat: String,
        coordinateLong: String,
        currentRole: String,
        po: String
    }
    
    struct AddressInfo: Codable {
        let address: String?, city: String?, state: String?
        
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
        
        var employeeID: Int,
        userName: String,
        employeeJobs: [Job.UserJob],
        punchedIn: Bool?
        //                let workWeekHours: Int?
        //                let userPoints: Int?
        
        static func fromJSON(dictionary: NSDictionary) -> UserInfo? {
            var jobsToAdd = [Job.UserJob]()
            var clocked = false
            
            guard let userId = dictionary["employeeID"] as? Int,
                let jobs = dictionary["employeeJobs"] as? NSArray,
                let userName = dictionary["username"] as? String else {
                    print("User Info failed to parse"); return nil
            }
            if let clockInOut = dictionary["punchedIn"] as? Bool {
                clocked = clockInOut
            }
            //                let weekHours = dictionary["workWeekHours"] as? Int,
            //                let points = dictionary["userPoints"] as? Int,
            
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
        
        let weekBeginDate: String?,
        sunday: NSDictionary?,
        monday: NSDictionary?,
        tuesday: NSDictionary?,
        wednesday: NSDictionary?,
        thursday: NSDictionary?,
        friday: NSDictionary?,
        saturday: NSDictionary?,
        totalHours: Int?
        
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
        
        let poNumber: String,
        jobName: String,
        dates: [JobDates],
        jobLocation: CLLocationCoordinate2D,
        jobAddress: String, jobCity: String, jobState: String,
        projCoord: String,
        fieldLead: String,
        supervisor: String,
        assignedEmployees: [String]
        
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
    
    struct JobCheckupInfo: Encodable {
        let returnTomorrow: Bool, numberOfWorkers: Int, addedMaterial: Bool, poNumber: String
    }
}

class FieldActions {
    
    var formType: String?,
    jobName: String?,
    poNumber: String?,
    requestedBy: String?,
    location: String?, // Address?
    material: String?,
    colorSpec: String?,
    quantity: Double?,
    neededBy: Double?, // Seconds from 1970
    description: String?
    let hardwareLocations: Array = ["Ace", "Lowe's", "Orchard", "Harbor", "TheHome"]
    let maxDistance = 5  // Miles?
    
    struct SuppliesRequest: Encodable {
        var formType: String?,
        jobName: String?,
        poNumber: String?,
        requestedBy: String?,
        location: String?,
        neededBy: Double?, // Seconds from 1970
        description: String?,
        suppliesCollection: [MaterialQuantityColor],
        jobCheckUp: Job.JobCheckupInfo?
        
        struct MaterialQuantityColor: Encodable {
            var quantity: String,
            material: String,
            color:  String,
            width: String?,
            depth: String?,
            height: String?
        }
    }
    
    struct ToolRental: Encodable {
        var formType: String?,
        jobName: String?,
        poNumber: String?,
        requestedBy: String?,
        toolType: String?,
        brand: String?,
        duration: Int?, // Number of Days
        quantity: Double?,
        neededBy: Double?, // Seconds from 1970
        location: String?
        
        let reminderPeriods = [24, 48, 72, 96]
    }
    
    struct ToolReturn: Encodable {
        let rental: FieldActions.ToolRental, signedDate: String, printedNames: [String]
    }
    
    struct ToolsNImages {
        let tools: [FieldActions.ToolRental], images: [UIImage]
    }
    
    struct ToolRentalExtension: Encodable {
        var requestedBy: String, toolType: String, brand: String, duration: String
    }
    
    struct  ChangeOrders: Encodable {
        var formType: String?,
        jobName: String?,
        poNumber: String?,
        requestedBy: String?,
        location: String?, // Address?
        material: String?,
        colorSpec: String?,
        quantity: String?,
        neededBy: Double?, // Seconds from 1970
        description: String?
    }
    
    struct VehicleChecklist: Encodable {
        var username: String,
        department: String,
        licensePlate: String,
        date: Double,
        outsideInspection: OutsideInspection,
        startupInspection: StartupInspection,
        issuesReport: String
        
        struct OutsideInspection: Encodable {
            var windows: Bool,
            tiresNnuts: Bool,
            engine: Bool,
            litesNsignals: Bool,
            mirrors: Bool,
            windshieldNwipres: Bool,
            dents: Bool,
            exteriorComments: String
        }
        
        struct StartupInspection: Encodable {
            var engine: Bool,
            gauges: Bool,
            wipers: Bool,
            horn: Bool,
            brakes: Bool,
            seatbelt: Bool,
            insuranceNregist: Bool,
            firstAidKit: Bool,
            clean: Bool,
            startupComments: String
        }
    }
    
    static func fromJSONtoTool(json: Any) -> ([FieldActions.ToolRental], [UIImage]) {
        var boxOtools = [FieldActions.ToolRental]()
        var toolImages = [UIImage]()
        
        if let tools = json as? Array<Any> {
            
            for oneTool in tools {
                
                if
                    let dictionary = oneTool as? Dictionary<String, Any>,
                    let photoStr = dictionary["photo"] as? String,
                    let photoDecoded = Data(base64Encoded: photoStr, options: .ignoreUnknownCharacters),
                    let image = UIImage(data: photoDecoded),
                    let duration = dictionary["duration"] as? Int,
                    let quantity = dictionary["quantity"] as? Int
                {
                    
                    let formType = FieldActions.nilOrString(val: dictionary["formType"])
                    let jobName = FieldActions.nilOrString(val: dictionary["jobName"])
                    let poNumber = FieldActions.nilOrString(val: dictionary["poNumber"])
                    let requestedBy = FieldActions.nilOrString(val: dictionary["requestedBy"])
                    let toolType = FieldActions.nilOrString(val: dictionary["toolType"])
                    let brand = FieldActions.nilOrString(val: dictionary["brand"])
                    let neededBy = FieldActions.nilOrString(val: dictionary["neededBy"])
                    let location = FieldActions.nilOrString(val: dictionary["location"])
                    
                    let neededDate = Job.UserJob.stringToDate(string: neededBy)
                    let needDouble = neededDate.timeIntervalSince1970
                    
                    let toolToAdd = FieldActions.ToolRental(
                        formType: formType,
                        jobName: jobName,
                        poNumber: poNumber,
                        requestedBy: requestedBy,
                        toolType: toolType,
                        brand: brand,
                        duration: duration,
                        quantity: Double(quantity),
                        neededBy: needDouble,
                        location: location
                    )
                    boxOtools.append(toolToAdd)
                    toolImages.append(image)
                } else {
                    print("Failed parsing Tool json.")
                }
            }
        }
        
        return (boxOtools, toolImages)
    }
    
    static func nilOrString(val: Any) -> String {
        if let valAsString = val as? String {
            return valAsString
        } else {
            return ""
        }
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
    let date: String, start: Date, end: Date
    let name: String, type: String
    
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
    let username: String,
    employeeID: Int,
    department: String,
    shiftHours: String,
    start: Double,
    end: Double,
    signedDate: Double,
    approved: Bool?
    
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
    
    struct answerOptions: Encodable { var A: String; var B: String; var C: String; var D: String }
    
    static func jsonToSQ(dictionary: NSDictionary) -> SafetyQuestion {
        
        guard let question = dictionary["question"] as? String,
            let answerOptions = dictionary["options"] as? NSDictionary,
            let A = answerOptions["A"] as? String,
            let B = answerOptions["B"] as? String,
            let C = answerOptions["C"] as? String,
            let D = answerOptions["D"] as? String,
            let answer = dictionary["answer"] as? String else {
                print("failed to parse safetyQuestion")
                return SafetyQuestion(
                    question: "", options: SafetyQuestion.answerOptions(A: "", B: "", C: "", D: ""), answer: ""
                )
        }
        let options = SafetyQuestion.answerOptions(A: A, B: B, C: C, D: D)
        
        return SafetyQuestion(question: question, options: options, answer: answer)
    }
}

class DefaultKeys: Encodable {
    public static let token = "token",
    employeeName = "employeeName",
    employeeID = "employeeID",
    todaysJobLatLong = "todaysJobLatLong",
    todaysJobPO = "todaysJobPO",
    todaysJobName = "todaysJobName",
    hadLunch = "hadLunch"
}

class AutoCompleteObj: NSObject, MLPAutoCompletionObject {
    var poNumber: NSString = ""
    
    override init() { super.init() }
    
    func initWithPO(po: String) -> AutoCompleteObj {
        self.poNumber = po as NSString
        return self
    }
    
    func autocompleteString() -> String! {
        return self.poNumber as String
    }
}

class AutoCompleteDataSrc: NSObject, MLPAutoCompleteTextFieldDataSource {
    var testWithAutoCompleteObjectsInsteadOfStrings = false
    var simulateLatency = false
    var poNums: [String] = [String]()
    
    override init() { super.init() }
    
    func initialize(pos: [String]) -> AutoCompleteDataSrc {
        self.poNums = pos
        return self
    }
    
    func autoCompleteTextField(_ textField: MLPAutoCompleteTextField!, possibleCompletionsFor string: String!) -> [Any]! {
        guard let typedText = string else { return [""]}
        var possibleMatches = [AutoCompleteObj]()
        
        for i in poNums {
            if i.contains(typedText) {
                let match = AutoCompleteObj().initWithPO(po: i)
                possibleMatches.append(match)
            }
        }
        return possibleMatches
    }
}

