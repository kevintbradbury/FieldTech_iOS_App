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
//import Firebase


class APICalls {
    static let host = "https://mb-server-app-kbradbury.c9users.io/"
    let notificationCenter = UNUserNotificationCenter.current()
    
    
    func fetchJobInfo(employeeID: String, callback: @escaping ([Job.UserJob]) -> ()) {
        
        let route = "employee/" + employeeID + "/jobs"
        let request = setupRequest(route: route, method: "GET")
        let session = URLSession.shared;
        
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                print("failed to fetch JSON")
                return
            }
            guard let verifiedData = data else {
                print("could not verify data from dataTask")
                return
            }
            let jobs: [Job.UserJob] = self.parseJobs(from: verifiedData)
            callback(jobs)
        }
        task.resume()
    }
    
    func sendCoordinates(employee: UserData.UserInfo, location: [String], autoClockOut: Bool, role: String, callback: @escaping (Bool, String, String, [Double], Bool, String) -> ()){
        let route = "employee/" + String(describing: employee.employeeID)
        let data = convertToJSON(employee: employee, location: location, role: role)
        let session = URLSession.shared;
        var auto: String { if autoClockOut == true { return "true" } else { return "" } }
        var request = setupRequest(route: route, method: "POST")
        
        request.httpBody = data
        request.addValue(auto, forHTTPHeaderField: "autoClockOut")
        print(request.allHTTPHeaderFields)
        
        let task = session.dataTask(with: request) {data, response, error in
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

    func manualSendPO(employee: UserData.UserInfo, location: [String], role: String, po: String, callback: @escaping (Bool, String, String, [Double], Bool, String) -> ()){
        let route = "employee/" + String(describing: employee.employeeID) + "/override/" + po
        let data = convertToJSON(employee: employee, location: location, role: role)
        let session = URLSession.shared;
        var request = setupRequest(route: route, method: "POST")
        
        request.httpBody = data
        
        let task = session.dataTask(with: request) {data, response, error in
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
    
    func justCheckCoordinates(location: [String], callback: @escaping (Bool) -> ()){
        guard let employee = UserDefaults.standard.string(forKey: "employeeName") else { return }
        guard let emplyID = UserDefaults.standard.string(forKey: "employeeID") else { return }

        // Get role from UserDefaults or CoreData
        let role: String

        let route = "checkCoordinates/" + employee
        let session = URLSession.shared;
        let person = UserInfoCodeable(userName: employee, employeeID: emplyID, coordinateLat: location[0], coordinateLong: location[1], currentRole: "-")
        // Receives currentRole from DB, so no need to send here
        var request = setupRequest(route: route, method: "POST")
        var data = Data()
        
        do {
            let jsonEncoder = JSONEncoder()
            data = try jsonEncoder.encode(person)
        } catch {
            print(error);   return
        };  request.httpBody = data
        
        let task = session.dataTask(with: request) {data, response, error in
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
    
    
    func sendChangeOrderReq(imageData: Data, formType: String, formBody: Data, po: String, callback: @escaping (Bool) -> () ) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let url = APICalls.host + "changeOrder/" + po
        let contentType = "multipart/form-data"
        let headers: HTTPHeaders = [
            "Content-type" : contentType,
            "formType" : formType
        ]
        
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(
                    formBody,
                    withName: "changeOrder"
                )
                multipartFormData.append(
                    imageData,
                    withName: "changeOrderImg",
                    fileName: "changeOrder_PO: \(po).jpg",
                    mimeType: "image/jpeg"
                )
        },
            usingThreshold: UInt64.init(),
            to: url,
            method: .post,
            headers: headers,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.uploadProgress { progress in
                        //progressCompletion(Float(progress.fractionCompleted))
                    }; upload.validate()
                    upload.responseString { response in
                        guard response.result.isSuccess else {
                            print("error while uploading file: \(response.result.error)"); self.failedUpload(msg: "Change order failed to upload.")
                            callback(false); return
                        }
                        self.successUpload(msg: "Change order uploaded successfully."); callback(true)
                    }
                    
                case .failure(let encodingError):
                    print(encodingError); self.failedUpload(msg: "Change order failed to upload.")
                    callback(false)
                }
        }
        ); UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func fetchEmployee(employeeId: Int, callback: @escaping (UserData.UserInfo) -> ()){
        let route = "employee/" + String(employeeId)
        let request = setupRequest(route: route, method: "GET")
        let session = URLSession.shared;
        
        let task = session.dataTask(with: request) { data, response, error in
            
            if error != nil { print(error); return }
            else {
                guard let verifiedData = data as? Data else {
                    print("couldn't verify data from server"); return
                }
                guard let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary else { return }
                guard let user = UserData.UserInfo.fromJSON(dictionary: json) else {
                    print("json serialization failed")
                    return
                }; callback(user)
            }
        }; task.resume()
    }
    
    func upload(images: [UIImage], jobNumber: String, employee: String, callback: @escaping (Bool) -> () ) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let url = APICalls.host + "job/" + jobNumber + "/upload"
        let headers: HTTPHeaders = [
            "Content-type" : "multipart/form-data",
            "employee": employee
        ]
        
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                var i = 0
                for img in images {
                    guard let imageData = UIImageJPEGRepresentation(img, 0.25) else { return }
                    multipartFormData.append(imageData,
                                             withName: "\(jobNumber)_\(i)",
                        fileName: "\(jobNumber)_\(i).jpg",
                        mimeType: "image/jpeg")
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
                        //progressCompletion(Float(progress.fractionCompleted))
                    }
                    upload.validate()
                    upload.responseString { response in
                        guard response.result.isSuccess else {
                            print("error while uploading file: \(response.result.error)")
                            self.failedUpload(msg: "Photos failed to upload.")
                            callback(false)
                            return
                        }
                        self.successUpload(msg: "Photos uploaded successfully.")
                        callback(true)
                    }
                    
                case .failure(let encodingError):
                    print(encodingError)
                    self.failedUpload(msg: "Photos failed to upload.")
                    callback(false)
                }
        }
        ); UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func getToolRentals(employeeID: Int)  { // -> [FieldActions.ToolRental]
        let route = APICalls.host + "toolRentals/\(employeeID)"
        
        Alamofire.request(route).responseData { response in
            print(response.result)
            
//            if let json = response.result.value {
//                print("JSON: ", json)
//            }
            if let data = response.data,
                let utf8Text = String(data:  data, encoding: .utf8) {
                print("Data: ", utf8Text)
            }
        }
        
        
//        let request = setupRequest(route: route, method: "GET")
//        let session = URLSession.shared
//
//        let task = session.dataTask(with: request) { data, response, error in
//            if error != nil {
//                print("error: ", error)
//            } else if response != nil {
//
//                print(response)
//            }
//        }
//
//        task.resume()
    }
    
}

extension APICalls {
    
    func setupRequest(route: String, method: String) -> URLRequest {
        let url = URL(string: APICalls.host + route)!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        return request
    }
    
    func startSession(request: URLRequest, session: URLSession, callback: @escaping (Bool, Data)->()) {
        print("start session w/ req: ", request)
        
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                print("failed to fetch JSON from database \n \(String(describing: response)) \n \(String(describing: error))")
                callback(false, Data())
                return
            } else {
                guard let verifiedData = data as? Data else {
                    print("could not verify data from dataTask")
                    callback(false, Data())
                    return
                }
                callback(true, verifiedData)
            }
        }
        task.resume()
    }
    
    func parseJobs(from data: Data) -> [Job.UserJob] {
        var jobsArray: [Job.UserJob] = []
        
        guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? NSArray else {
            print("couldn't parse json objects as an Array"); return jobsArray
        }
        
        for jobJson in json {
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
    
    struct UserInfoCodeable: Encodable {
        let userName: String
        let employeeID: String
        let coordinateLat: String
        let coordinateLong: String
        let currentRole: String
    }
    
    func convertToJSON(employee: UserData.UserInfo, location: [String], role: String) -> Data {
        let person = UserInfoCodeable(userName: employee.userName, employeeID: String(employee.employeeID), coordinateLat: location[0], coordinateLong: location[1], currentRole: role)
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
                } catch { (error)
                    if error != nil { print("looks like we couldn't setup that alarm"); print(error) }
                }
            }
        }
    }
    
    func failedUpload(msg: String) {
            let failedNotifc = UIViewController().createNotification(intervalInSeconds: 1, title: "FAILED", message: msg, identifier: "failedUpload")
            
            self.notificationCenter.add(failedNotifc, withCompletionHandler: { (error) in
                if error != nil { return }
            })
    }
    
    func successUpload(msg: String)  {
        let completeNotif = UIViewController().createNotification(intervalInSeconds: 1, title: "SUCCESS", message: msg, identifier: "uploadSuccess")
        
        self.notificationCenter.add(completeNotif, withCompletionHandler: { (error) in
            if error != nil { return }
        })
    }
    
}




