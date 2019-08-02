//
//  APITestCall.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import EventKit
import Alamofire
import UserNotifications
import UserNotificationsUI
import Firebase


class APICalls {
    static var host = ""
    let jsonEncoder = JSONEncoder()
    
    public static func getHostFromPList() {
        var resourceDictionary: NSDictionary?
        
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            resourceDictionary = NSDictionary(contentsOfFile: path)
        }
        
        if let resourceFileDIctionaryContent = resourceDictionary {
            APICalls.host = resourceFileDIctionaryContent["TEST_SERVER"] as? String ?? ""
//            APICalls.host = resourceFileDIctionaryContent["HOST_SERVER"] as? String ?? ""
        }
    }
    
    func checkForToken(employeeID: String, callback: @escaping (Bool)->() ) {
        let route = "checkForToken/\(employeeID)"
        var hasToken = false
        
        setupRequest(route: route, method: "GET") { request in
            self.startSession(request: request, route: route) { json in
            
                if let yesHasToken = json["hasToken"] as? Bool { hasToken = yesHasToken }
                callback(hasToken)
            }
        }
    }
    
    func updateToken(token: String, route: String) {
        UserDefaults.standard.set(token, forKey: "token");
        
        setupRequest(route: route, method: "POST") { req in
            var request = req
            request.addValue(token, forHTTPHeaderField: "token")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil {
                    print("Error in updateToken: \(error)"); return
                } else {
                    // need to send validation 
                    print("updateToken successfully"); return
                }
            }; task.resume()
        }
    }
    
    func fetchJobInfo(employeeID: String, callback: @escaping ([Job.UserJob], [TimeOffReq], [Holiday]) -> ()) {
        let route = "employee/" + employeeID + "/jobs"
        
        setupRequest(route: route, method: "GET") { request in
            self.startSession(request: request, route: route) { json in
                var holidays: [Holiday] = [],
                employeeJobs: [Job.UserJob] = [],
                timeOffReqs: [TimeOffReq] = []
                
                if let hldys = json["holidays"] as? NSArray { holidays = self.parseHolidays(from: hldys) }
                if let jobs = json["employeeJobs"] as? NSArray { employeeJobs = self.parseJobs(from: jobs) }
                if let tORS = json["timeOffReqs"] as? NSArray { timeOffReqs = self.parseTORS(from: tORS) }
                
                callback(employeeJobs, timeOffReqs, holidays)
            }
        }
    }
    
    func sendCoordinates(employee: UserData.UserInfo, location: [String], autoClockOut: Bool, role: String, po: String, override: Bool, callback: @escaping (Bool, String, String, [Double], Bool, String) -> ()) {
        var route = "employee/\(employee.employeeID)"
        if override == true {
            route += "/override/\(po)"
        }
        
        let data = convertToJSON(employee: employee, location: location, role: role, po: po)
        var auto: String {
            if autoClockOut == true { return "true" } else { return "" }
        }
        
        setupRequest(route: route, method: "POST") { req in
            var requestWithData = req
            requestWithData.httpBody = data
            requestWithData.addValue(auto, forHTTPHeaderField: "autoClockOut")
            
            self.startSession(request: requestWithData, route: route) { json in
                
                guard let successfulPunch = json["success"] as? Bool else {
                    print("APICalls > sendCoordinates > successfulPunch failed")
                    callback(false, "", "", [0.0], false, "APICalls > sendCoordinates > successfulPunch failed")
                    return
                }
                
                if let err = json["error"] as? String {
                    print("APICalls > sendCoordinates > Error \(err)");
                    callback(successfulPunch, "", "", [0.0], false, err)

                } else if let currentJob = json["job"] as? String,
                    let poNumber = json["poNumber"] as? String,
                    let jobLatLong = json["jobLatLong"] as? [Double],
                    let clockedIn = json["punchedIn"] as? Bool {
                    callback(successfulPunch, currentJob, poNumber, jobLatLong, clockedIn, "")

                } else if autoClockOut == true {
                    callback(successfulPunch, "", "", [0.0], false, "")
                }
            }
        }
    }
    
    func justCheckCoordinates(location: [String], callback: @escaping (Bool) -> ()) {
        guard let employee = UserDefaults.standard.string(forKey: "employeeName"),
            let emplyID = UserDefaults.standard.string(forKey: "employeeID"),
            let po = UserDefaults.standard.string(forKey: "todaysJobPO") else { return }
        
        let route = "checkCoordinates/\(employee)"
        let person = UserData.UserInfoCodeable(
            userName: employee,
            employeeID: emplyID,
            coordinateLat: location[0], coordinateLong: location[1],
            currentRole: "-",    //  CurrentRole set from DB, no need to send here
            po: po
        )
        setupRequest(route: route, method: "POST") { request in
            var requestWithData = request
            var data = Data()
            
            do { data = try self.jsonEncoder.encode(person) }
            catch { print("Error in justCheckCoordinates: \(error)"); callback(false); return }
            
            requestWithData.httpBody = data
            
            self.startSession(request: requestWithData, route: route) { json in
                
                guard let successfulPunch = json["success"] as? Bool else {
                    print("APICalls > justCheckCoordinates > failed on data or json or successfulPunch")
                    callback(false); return
                }
                callback(successfulPunch)
            }
        }
    }
    
    func sendJobCheckup(po: String, body: Data, vc:UIViewController, callback: @escaping () -> ()){
        let route = "jobCheckupInfo/" + String(po)
        
        setupRequest(route: route, method: "POST") { request in
            var reqWithData = request
            reqWithData.httpBody = body
            
            self.startSession(request: reqWithData, route: route) { json in
                callback()
            }
        }
    }
    
    func fetchEmployee(employeeId: Int, vc:UIViewController, callback: @escaping (UserData.UserInfo, UserData.AddressInfo) -> ()){
        let route = "employee/" + String(employeeId)
        
        setupRequest(route: route, method: "GET") { request in
            self.startSession(request: request, route: route) { json in
                
                guard let user = UserData.UserInfo.fromJSON(dictionary: json),
                    let dictionary = json["addressInfo"] as? NSDictionary,
                    let addressInfo = UserData.AddressInfo.fromJSON(dictionary: dictionary) else {
                        print("failed to parse UserData"); return
                }
                UserDefaults.standard.set(user.userName, forKey: "employeeName")
                callback(user, addressInfo)
            }
        }
    }
    
    func getSafetyQs(cb: @escaping ([SafetyQuestion]) -> () ) {
        let route = "safetyQuestions/mobile"
        
        setupRequest(route: route, method: "GET") { request in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil {
                    print("Error in getSafetyQs: \(error)"); return
                }
                
                guard let verfData = data,
                    let json = (((try? JSONSerialization.jsonObject(with: verfData, options: []) as? NSArray) as NSArray??)) else {
                        print("failed to serialize JSON from SafetyQ req")
                        return
                }
                var allSafetyQuestions = [SafetyQuestion]()
                
                for question in json ?? [] {
                    guard  let dictionary = question as? NSDictionary else { return }
                    let q = SafetyQuestion.jsonToSQ(dictionary: dictionary)
                    allSafetyQuestions.append(q)
                }
                cb(allSafetyQuestions)
            }
            task.resume()
        }
    }
    
    func addPoints(employee: String, pts: Int) {
        let route = "addPoints/\(employee)/\(pts)"
        
        setupRequest(route: route, method: "GET") { request in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil {
                    print("Error in addPoints: \(error)"); return
                }
                
                guard let verfData = data else {
                    print("Couldnt verf data")
                    return
                }
            }
            task.resume()
        }
    }
    
    func acceptMoreHrs(employee: String, moreDays: AcceptMoreDays, vc:UIViewController, callback: @escaping (Bool)->()) {
        let route = "acceptMoreHours/\(employee)"
        var data = Data()
        
        do {
            data = try self.jsonEncoder.encode(moreDays)
        } catch {
            print("error coding moreDays to JSON: \(error)"); return
        }
        
        setupRequest(route: route, method: "POST") { request in
            var req = request
            req.httpBody = data

            self.startSession(request: req, route: route) { json in
                print("\(route): success \(json["success"])")
                guard let success = json["success"] as? Bool else { return }
                callback(success)
            }
        }
    }
    
    func getToolRentals(employeeID: Int, callback: @escaping (FieldActions.ToolsNImages) -> ()) {
        let route = APICalls.host + "toolRentals/\(employeeID)"
        
        APICalls.getFIRidToken() { idToken in
            var headers: HTTPHeaders = [ "Authorization" : idToken ]
            
            UsernameAndPassword.getUsernmAndPasswd() { userNpass in
                headers.updateValue(userNpass.username, forKey: "username")
                headers.updateValue(userNpass.password, forKey: "password")
            }
            Alamofire.request(route, headers: headers).responseJSON() { response in
                
                if let json = response.result.value {
                    print("JSON")
                    let toolsNphotos = FieldActions.fromJSONtoTool(json: json)
                    let sendBackObj = FieldActions.ToolsNImages(tools: toolsNphotos.0, images: toolsNphotos.1)
                    
                    callback(sendBackObj)
                } else {
                    print("Error parsing Tools json: \(String(describing: response.error))")
                }
            }
        }
    }
    
    static func getFIRidToken(cb: @escaping (String) -> () ) {
        let currentUser = Auth.auth().currentUser
        currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
            if let err = error {
                print("Error in getFIRidToken: \(err)")
            }
            guard let verifiedTk: String = idToken else { return }
             cb(verifiedTk)
        }
    }
    
    func extendRental(toolData: FieldActions.ToolRentalExtension, cb: @escaping (NSDictionary)-> ()) {
        let route = "toolRental/extend"
        var data = Data()
        
        do { data = try self.jsonEncoder.encode(toolData) }
        catch let err {
            print("Erro in extendRental, w/ err: \(err)"); cb(["error":"Unable to encode data for server."])
        }
        
        setupRequest(route: route, method: "POST") { request in
            var req = request
            req.httpBody = data
            
            self.startSession(request: req, route: route) { json in
                cb(json)
            }
        }
    }
    
    func getJobNames(errorAndJobs cb: @escaping (String?, [String]?)-> ()) {
        let route = "getJobs"

        setupRequest(route: route, method: "GET") { request in
            
            self.startSession(request: request, route: route) { json in
                var jobs: [String]?
                var err: String?
                
                if let theseJobs = json["jobs"] as? [String] {
                    jobs = theseJobs
                } else if let error = json["error"] {
                    err = error as? String
                }
                cb(err, jobs)
            }
        }
    }
    
    
}


extension APICalls {
    
    func setupRequest(route: String, method: String, cb: @escaping(URLRequest)-> ())  {
        let url = URL(string: APICalls.host + route)!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("close", forHTTPHeaderField: "Connection")
        
        APICalls.getFIRidToken() { firebaseIDtoken in
            
            UsernameAndPassword.getUsernmAndPasswd() { userNpass in
                request.addValue(firebaseIDtoken, forHTTPHeaderField: "Authorization")
                request.addValue(userNpass.username, forHTTPHeaderField: "username")
                request.addValue(userNpass.password, forHTTPHeaderField: "password")

                cb(request)
            }
        }
    }
    
    func startSession(request: URLRequest, route: String, callback: @escaping (NSDictionary)->()) {
        print("start session w/ req")
        let config = URLSessionConfiguration.default
        let session = URLSession.init(configuration: config)
        
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil {
                print("Error in route: \(route) \n \(String(describing: error))")
                callback(["error": error])
                return
            }
            guard let verifiedData = data as? Data,
                let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary else {
                        print("APICalls > startSession > data/json error in route: \(route) \n \(String(describing: response)) \n \(data)")
                        callback(["error":"unable to parse JSON"]); return
            }
            callback(json)
        }
        task.resume()
    }
    
    func parseJobs(from array: NSArray) -> [Job.UserJob] {
        var jobsArray: [Job.UserJob] = []
        
        for jobJson in array {
            if let jobDictionary = jobJson as? [String : Any]  {
                if let job = Job.UserJob.jsonToDictionary(dictionary: jobDictionary as NSDictionary) {
                    jobsArray.append(job)
                }
            } else {
                print("couldn't cast index json to type Dictionary"); return jobsArray
            }
        }
        return jobsArray
    }
    
    func parseTORS(from array: NSArray) -> [TimeOffReq] {
        var timeOffReqs: [TimeOffReq] = []
        
        for tmOffReq in array {
            
            if let jobDictionary = tmOffReq as? NSDictionary {
                let req = TimeOffReq.parseJson(dictionary: jobDictionary)
                timeOffReqs.append(req)
            } else {
                print("couldn't cast index json to type Dictionary"); return timeOffReqs
            }
        }
        return timeOffReqs
    }
    
    func parseHolidays(from array: NSArray) -> [Holiday] {
        var holidays: [Holiday] = []
        
        for oneHoliday in array {
            
            if let holidayDictionary = oneHoliday as? NSDictionary {
                let hldy = Holiday.parseJson(dictionary: holidayDictionary)
                holidays.append(hldy)
            } else {
                print("couldn't cast index json to type Dictionary"); return holidays
            }
        }
        return holidays
    }
    
    func convertToJSON(employee: UserData.UserInfo, location: [String], role: String, po: String) -> Data {
        let person = UserData.UserInfoCodeable(
            userName: employee.userName,
            employeeID: String(employee.employeeID),
            coordinateLat: location[0],
            coordinateLong: location[1],
            currentRole: role,
            po: po
        )
        var data = Data()
        var combinedString = person.userName + " -- " + person.employeeID  + " |"
        combinedString += person.coordinateLat + ", " + person.coordinateLong + "|" + person.currentRole
        
        do {
            data = try self.jsonEncoder.encode(person)
        } catch {
            print(error)
            data = combinedString.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        }
        return data
    }
    
}

extension APICalls {
    
    //Doesn't set an alarm but does add an event to calendar, which may be useful for adding jobs to internal calendar
    func setAnAlarm(jobName: String, jobStart: Date, jobEnd: Date) {
        var _: EKCalendar?
        let eventstore = EKEventStore()
        
        eventstore.requestAccess(to: EKEntityType.event){ (granted, error ) -> Void in
            if granted == true { //Substitute job info in here: startDate, endDate, title
                let event = EKEvent(eventStore: eventstore)
                event.startDate = Date(); event.endDate = Date()
                event.title = "Job Name"
                event.calendar = eventstore.defaultCalendarForNewEvents
                event.structuredLocation = EKStructuredLocation() // Geofence location for event
                event.addAlarm(EKAlarm(relativeOffset: TimeInterval(10)))
                
                do {
                    try eventstore.save(event, span: .thisEvent, commit: true)
                } catch {
                    print("Error: \(error) \n Couldn't setup that alarm or event: \(event.description)")
                }
            }
        }
    }
    
    func changePunctuation(uploadType: String) -> String {
        switch uploadType {
        case "toolReturn":
            return "Tool Return"
        case "profilePhoto":
            return "Profile Photo"
        case "timeOffRequest":
            return "Time Off Request"
        case "vehicleCheckList":
            return "Vehicle Checklist"
        case "changeOrder":
            return "Form"
            
        default:
            return uploadType
        }
    }
    
    static func succeedOrFailUpload(msg: String, uploadType: String, success: Bool)  {
        var title = "FAILED"
        var adjMsg = ""
        
        if success == true {
            title = "SUCCESS"
            adjMsg += APICalls().changePunctuation(uploadType: uploadType)
            adjMsg += msg
        } else {
            adjMsg += msg
            adjMsg += APICalls().changePunctuation(uploadType: uploadType)
        }
        
        let completeNotif = UIViewController().createNotification(intervalInSeconds: 1, title: title, message: adjMsg, identifier: "uploadSuccess")
        UNUserNotificationCenter.current().add(completeNotif, withCompletionHandler: { (error) in
            if error != nil { return }
        })
    }
    
    func handleResponseMsgOrErr(json: NSDictionary, uploadType: String, callback: ([String: String]) -> () ) {
        _ = UIApplication.shared.applicationState
        
        if let err = json["error"] as? String {
            print(err)
            
            APICalls.succeedOrFailUpload(msg: "An Error occured: \(err) with upload: ", uploadType: uploadType, success: false);
            callback(["error": err])
        } else if let msg = json["msg"] as? String {
            APICalls.succeedOrFailUpload(msg: " uploaded successfully. \(msg)", uploadType: uploadType, success: true);
            callback(["msg": msg])
        } else {
            APICalls.succeedOrFailUpload(msg:  " uploaded successfully.", uploadType: uploadType, success: true);
            callback(["success": "true"])
        }
    }
    
}




