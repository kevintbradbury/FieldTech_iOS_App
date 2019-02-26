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
    static let host = "https://mb-server-app-kbradbury.c9users.io/"
    
    func fetchJobInfo(employeeID: String, callback: @escaping ([Job.UserJob], [TimeOffReq], [Holiday]) -> ()) {
        let route = "employee/" + employeeID + "/jobs"
        
        setupRequest(route: route, method: "GET") { request in
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil {
                    print("failed to fetch JSON")
                    return
                }
                guard let verifiedData = data else {
                    print("could not verify data from dataTask")
                    return
                }
                guard let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary,
                    let jobs = json["employeeJobs"] as? NSArray,
                    let tORS = json["timeOffReqs"] as? NSArray,
                    let hldys = json["holidays"] as? NSArray else {
                        print("couldn't parse json objects as an Array"); return
                }
                
                let employeeJobs: [Job.UserJob] = self.parseJobs(from: jobs)
                let timeOffReqs: [TimeOffReq] = self.parseTORS(from: tORS)
                let holidays: [Holiday] = self.parseHolidays(from: hldys)
                
                callback(employeeJobs, timeOffReqs, holidays)
            }
            task.resume()
        }
    }
    
    func sendCoordinates(employee: UserData.UserInfo, location: [String], autoClockOut: Bool, role: String, callback: @escaping (Bool, String, String, [Double], Bool, String) -> ()) {
        let route = "employee/" + String(describing: employee.employeeID)
        let data = convertToJSON(employee: employee, location: location, role: role)
        var auto: String { if autoClockOut == true { return "true" } else { return "" } }
        
        setupRequest(route: route, method: "POST") { req in
            var request = req
            request.httpBody = data
            request.addValue(auto, forHTTPHeaderField: "autoClockOut")
            print(request.allHTTPHeaderFields as Any)
            
            let task = URLSession.shared.dataTask(with: request) {data, response, error in
                if error != nil {
                    print("failed to fetch JSON from database \n \(String(describing: response))");
                    return
                    
                } else {
                    print("no errors sending GPS coordinatess")
                    guard let verifiedData = data else { print("could not verify data from dataTask"); return }
                    guard let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary else { print("json serialization failed"); return }
                    guard let successfulPunch = json["success"] as? Bool else { print("failed on success bool"); return }
                    
                    if let currentJob = json["job"] as? String,
                        let poNumber = json["poNumber"] as? String,
                        let jobLatLong = json["jobLatLong"] as? [Double],
                        let clockedIn = json["punchedIn"] as? Bool {
                        
                        print("successBool, crntJob, jobGPS, clockdINOUT: \n \(successfulPunch), \(currentJob), \(poNumber), \(jobLatLong), \(clockedIn)")
                        callback(successfulPunch, currentJob, poNumber, jobLatLong, clockedIn, "")
                        
                    } else {
                        guard let err = json["error"] as? String else { return }
                        callback(successfulPunch, "", "", [0.0], false, err)
                    }
                }
            }
            task.resume()
        }
    }
    
    func manualSendPO(employee: UserData.UserInfo, location: [String], role: String, po: String, callback: @escaping (Bool, String, String, [Double], Bool, String) -> ()) {
        let route = "employee/" + String(describing: employee.employeeID) + "/override/" + po
        let data = convertToJSON(employee: employee, location: location, role: role)
//        let session = URLSession.shared;
        
        setupRequest(route: route, method: "POST") { request in
            var req = request
            req.httpBody = data
            
            let task = URLSession.shared.dataTask(with: req) {data, response, error in
                if error != nil {
                    print("failed to fetch JSON from database \n \(String(describing: response))");
                    return
                    
                } else {
                    print("no errors sending GPS coordinatess")
                    guard let verifiedData = data else { print("could not verify data from dataTask"); return }
                    guard let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary else { print("json serialization failed"); return }
                    guard let successfulPunch = json["success"] as? Bool else { print("failed on success bool"); return }
                    
                    if let currentJob = json["job"] as? String,
                        let poNumber = json["poNumber"] as? String,
                        let jobLatLong = json["jobLatLong"] as? [Double],
                        let clockedIn = json["punchedIn"] as? Bool {
                        print("successBool, crntJob, jobGPS, clockdINOUT: \n \(successfulPunch), \(currentJob), \(poNumber), \(jobLatLong), \(clockedIn)")
                        callback(successfulPunch, currentJob, poNumber, jobLatLong, clockedIn, "")
                        
                    } else {
                        guard let err = json["error"] as? String else { return }
                        callback(successfulPunch, "", "", [0.0], false, err)
                    }
                }
            }
            task.resume()
        }
    }
    
    func justCheckCoordinates(location: [String], callback: @escaping (Bool) -> ()) {
        guard let employee = UserDefaults.standard.string(forKey: "employeeName") else { return }
        guard let emplyID = UserDefaults.standard.string(forKey: "employeeID") else { return }
        
        let route = "checkCoordinates/" + employee
        let person = UserData.UserInfoCodeable(
            userName: employee,
            employeeID: emplyID,
            coordinateLat: location[0],
            coordinateLong: location[1],
            currentRole: "-"    //  Receives currentRole from DB, so no need to send here
        )
        setupRequest(route: route, method: "POST") { request in
            var req = request
            var data = Data()
            
            do {
                let jsonEncoder = JSONEncoder()
                data = try jsonEncoder.encode(person)
            } catch {
                print(error);   return
            }
            req.httpBody = data
            
            let task = URLSession.shared.dataTask(with: req) {data, response, error in
                if error != nil {
                    print("failed to fetch JSON from database \n \(String(describing: response))"); return
                } else {
                    print("no errors sending GPS coordinates")
                    guard let verifiedData = data else { print("could not verify data from dataTask"); return }
                    guard let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary else {
                        print("json serialization failed"); return
                    }
                    guard let successfulPunch = json["success"] as? Bool else { print("failed on success bool"); return }
                    callback(successfulPunch)
                }
            };  task.resume()
        }
    }
    
    func fetchEmployee(employeeId: Int, callback: @escaping (UserData.UserInfo, UserData.AddressInfo) -> ()){
        let route = "employee/" + String(employeeId)
        
        setupRequest(route: route, method: "GET") { request in
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                
                if error != nil { print(error as Any); return }
                else {
                    guard let verifiedData = data else { print("couldn't verify data from server"); return }
                    guard let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary else {
                        print("json serialization failed"); return
                    }
                    guard let user = UserData.UserInfo.fromJSON(dictionary: json),
                        let dictionary = json["addressInfo"] as? NSDictionary,
                        let addressInfo = UserData.AddressInfo.fromJSON(dictionary: dictionary) else {
                            
                            print("failed to parse UserData"); return
                    }
                    callback(user, addressInfo)
                }
            }; task.resume()
        }
    }
    
    func getSafetyQs(cb: @escaping ([SafetyQuestion]) -> () ) {
        let route = "safetyQuestions/mobile"
        
        setupRequest(route: route, method: "GET") { request in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil { print(error); return }
                
                guard let verfData = data as? Data,
                    let json = (try? JSONSerialization.jsonObject(with: verfData, options: []) as? NSArray) else {
                        print("failed to serialize JSON from SafetyQ req")
                        return }
                var allSafetyQuestions = [SafetyQuestion]()
                
                for question in json ?? [] {
                    guard  let dictionary = question as? NSDictionary,
                    let q = SafetyQuestion.jsonToSQ(dictionary: dictionary) as? SafetyQuestion else { return }
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
                    print(error); return
                }
                
                guard let verfData = data as? Data else {
                    print("Couldnt verf data")
                    return
                }
            }
            task.resume()
        }
    }
    
    func acceptMoreHrs(employee: String) {
        let route = "acceptMoreHours/\(employee)"
        
        setupRequest(route: route, method: "POST") { request in
            let task = URLSession.shared.dataTask(with: request) { data, response, err in
                if err != nil {
                    print(err); return
                }
                
                
            }
            task.resume()
        }
    }
    
    func uploadJobImages(images: [UIImage], jobNumber: String, employee: String, callback: @escaping ([String : String]) -> () ) {
        let route = "job/\(jobNumber)/upload"
        let headers = ["employee", employee]
        
        alamoUpload(route: route, headers: headers, formBody: Data(), images: images, uploadType: "job_\(jobNumber)") { responseType in
            callback(responseType)
        }
    }
    
    func alamoUpload(route: String, headers: [String], formBody: Data, images: [UIImage], uploadType: String, callback: @escaping ([String: String]) -> ()) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let url = "\(APICalls.host)\(route)"
        var headers: HTTPHeaders = [
            "Content-type" : "multipart/form-data",
            headers[0] : headers[1]
        ]
        
        getFIRidToken() { idToken in
            headers["Authorization"] = idToken
            
            Alamofire.upload(
                multipartFormData: { multipartFormData in
                    multipartFormData.append(formBody, withName: uploadType)
                    var i = 0
                    for img in images {
                        guard let imageData = UIImageJPEGRepresentation(img, 1) else { return }
                        let nm = "\(uploadType)_\(i)"
                        
                        multipartFormData.append( imageData, withName: nm, fileName: "\(nm).jpg", mimeType: "image/jpeg")
                        i += 1
                    }
            },
                usingThreshold: UInt64.init(),
                to: url,
                method: .post,
                headers: headers,
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.uploadProgress { progress in
                            print("progress: ", Float(progress.fractionCompleted * 100))
                        }
                        upload.validate()
                        upload.responseString { response in
                            
                            guard response.result.isSuccess else {
                                guard let err = response.result.error as? String else { return }
                                print("error while uploading file: \(err)");
                                APICalls.succeedOrFailUpload(msg: "Error occured: \(err) with upload: ", uploadType: uploadType, success: false)
                                callback(["error" : err]); return
                            }
                            guard let msg = response.result.value,
                                let data: Data = msg.data(using: String.Encoding.utf16, allowLossyConversion: true),
                                let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? NSDictionary else {
                                    APICalls.succeedOrFailUpload(msg: " uploaded successfully.", uploadType: uploadType, success: true);
                                    callback(["success": "true"]); return
                            }
                            
                            self.handleResponseMsgOrErr(json: json, uploadType: uploadType) { responseType in
                                callback(responseType)
                            }
                        }
                        
                    case .failure(let encodingError):
                        print(encodingError);
                        APICalls.succeedOrFailUpload(msg: "Failed to upload: ", uploadType: uploadType, success: false)
                        callback(["error": encodingError.localizedDescription])
                    }
            }
            );  UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    struct ToolsNImages {
        let tools: [FieldActions.ToolRental]
        let images: [UIImage]
    }
    
    func getToolRentals(employeeID: Int, callback: @escaping (ToolsNImages) -> ()) {
        let route = APICalls.host + "toolRentals/\(employeeID)"
        
        getFIRidToken() { idToken in
            let headers: HTTPHeaders = [ "Authorization" : idToken ]
            Alamofire.request(route, headers: headers).responseJSON() { response in
                
                if let json = response.result.value {
                    print("JSON")
                    let toolsNphotos = FieldActions.fromJSONtoTool(json: json)
                    let sendBackObj = ToolsNImages(tools: toolsNphotos.0, images: toolsNphotos.1)
                    print("tools & images count: ", toolsNphotos.0.count, toolsNphotos.1.count)
                    
                    callback(sendBackObj)
                } else {
                    print("Error parsing Tools json: \(String(describing: response.error))")
                }
            }
        }
    }
    
    func getFIRidToken(cb: @escaping (String) -> () ) {
        let currentUser = Auth.auth().currentUser
        currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
            if let err = error {
                print(err)
            }
            guard let verifiedTk: String = idToken else { return }
             cb(verifiedTk)
        }
    }
}


extension APICalls {
    
    func setupRequest(route: String, method: String, cb: @escaping(URLRequest)-> ())  {
        let url = URL(string: APICalls.host + route)!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let session = URLSession.shared;
        
        getFIRidToken() { firebaseIDtoken in
            request.addValue(firebaseIDtoken, forHTTPHeaderField: "Authorization")
            cb(request)
        }
    }
    
    func startSession(request: URLRequest, session: URLSession, callback: @escaping (Bool, Data)->()) {
        print("start session w/ req: ", request)
        
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                print("failed to fetch JSON from database \n \(String(describing: response)) \n \(String(describing: error))")
                callback(false, Data())
                return
            } else {
                guard let verifiedData = data else {
                    print("could not verify data from dataTask")
                    callback(false, Data())
                    return
                }
                callback(true, verifiedData)
            }
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
                if let req = TimeOffReq.parseJson(dictionary: jobDictionary) as? TimeOffReq {
                    timeOffReqs.append(req)
                }
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
    
    func convertToJSON(employee: UserData.UserInfo, location: [String], role: String) -> Data {
        let person = UserData.UserInfoCodeable(
            userName: employee.userName,
            employeeID: String(employee.employeeID),
            coordinateLat: location[0],
            coordinateLong: location[1],
            currentRole: role
        )
        var data = Data()
        var combinedString = person.userName + " -- " + person.employeeID  + " |"
        combinedString += person.coordinateLat + ", " + person.coordinateLong + "|" + person.currentRole
        
        do {
            let jsonEncoder = JSONEncoder()
            data = try jsonEncoder.encode(person)
        } catch {
            print(error)
            data = combinedString.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        }
        return data
    }
    
    func generateCOstring(co: FieldActions.ChangeOrders) -> Data {
        var data = Data()
        let jsonEncoder = JSONEncoder()
        
        do { data = try jsonEncoder.encode(co) }
        catch { print("error converting CO to DATA", error) };
        
        return data
    }
    
    func generateTOOLstring(toolForm: FieldActions.ToolRental) -> Data {
        var data = Data()
        let jsonEncoder = JSONEncoder()
        
        do { data = try jsonEncoder.encode(toolForm) }
        catch { print("error converting TOOLRT to DATA", error) };
        
        return data
    }

    func generateSRFstring(srForm: FieldActions.SuppliesRequest) -> Data {
        var data = Data()
        let jsonEncoder = JSONEncoder()
        
        do { data = try jsonEncoder.encode(srForm) }
        catch { print("error converting TOOLRT to DATA", error) };
        
        return data
    }
    
    func generateToolReturnData(toolForm: FieldActions.ToolRental, signedDate: String, printedNames: [String]) -> Data {
        var data = Data()
        let jsonEncoder = JSONEncoder()
        
        struct ToolReturn: Encodable {
            let rental: FieldActions.ToolRental
            let signedDate: String
            let printedNames: [String]
        }
        
        let returnObj = ToolReturn(rental: toolForm, signedDate: signedDate, printedNames: printedNames)
        
        do { data = try jsonEncoder.encode(returnObj) }
        catch { print("error converting TOOLRT to DATA", error) };
        
        return data
    }
    
    func generateAddressData(addressInfo: UserData.AddressInfo) -> Data {
        var data = Data()
        let jsonEncoder = JSONEncoder()
        
        do { data = try jsonEncoder.encode(addressInfo) }
        catch { print("error converting addressInfo to DATA", error) };
        
        return data
    }
}

extension APICalls {
    
    //Doesn't set an alarm but does add an event to calendar, which may be useful for adding jobs to internal calendar
    func setAnAlarm(jobName: String, jobStart: Date, jobEnd: Date) {
        var calendar: EKCalendar?
        let eventstore = EKEventStore()
        
        eventstore.requestAccess(to: EKEntityType.event){ (granted, error ) -> Void in
            if granted == true { //Substitute job info in here: startDate, endDate, title
                let event = EKEvent(eventStore: eventstore)
                event.startDate = Date()
                event.endDate = Date()
                event.calendar = eventstore.defaultCalendarForNewEvents
                event.title = "Job Name"
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
        let state = UIApplication.shared.applicationState
        
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




