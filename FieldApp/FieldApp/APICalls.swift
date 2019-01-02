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
    
    func fetchJobInfo(employeeID: String, callback: @escaping ([Job.UserJob]) -> ()) {
        let route = "employee/" + employeeID + "/jobs"
        
        setupRequest(route: route, method: "GET") { request in
            let session = URLSession.shared;
            
            let task = session.dataTask(with: request) { data, response, error in
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
    }
    
    func sendCoordinates(employee: UserData.UserInfo, location: [String], autoClockOut: Bool, role: String, callback: @escaping (Bool, String, String, [Double], Bool, String) -> ()){
        let route = "employee/" + String(describing: employee.employeeID)
        let data = convertToJSON(employee: employee, location: location, role: role)
        let session = URLSession.shared;
        var auto: String { if autoClockOut == true { return "true" } else { return "" } }
        
        setupRequest(route: route, method: "POST") { req in
            var request = req
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
    }
    
    func manualSendPO(employee: UserData.UserInfo, location: [String], role: String, po: String, callback: @escaping (Bool, String, String, [Double], Bool, String) -> ()){
        let route = "employee/" + String(describing: employee.employeeID) + "/override/" + po
        let data = convertToJSON(employee: employee, location: location, role: role)
        let session = URLSession.shared;
        
        setupRequest(route: route, method: "POST") { request in
            var req = request
            req.httpBody = data
            
            let task = session.dataTask(with: req) {data, response, error in
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
    
    func justCheckCoordinates(location: [String], callback: @escaping (Bool) -> ()){
        guard let employee = UserDefaults.standard.string(forKey: "employeeName") else { return }
        guard let emplyID = UserDefaults.standard.string(forKey: "employeeID") else { return }
        
        let route = "checkCoordinates/" + employee
        let session = URLSession.shared;
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
            
            let task = session.dataTask(with: req) {data, response, error in
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
            
            let session = URLSession.shared;
            
            let task = session.dataTask(with: request) { data, response, error in
                
                if error != nil { print(error); return }
                else {
                    guard let verifiedData = data as? Data else {
                        print("couldn't verify data from server"); return
                    }
                    guard let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary else { return }
                    guard let user = UserData.UserInfo.fromJSON(dictionary: json) else {
                        print("json serialization failed");     return
                    };
                    guard let dictionary = json["addressInfo"] as? NSDictionary else { return }
                    guard let addressInfo = UserData.AddressInfo.fromJSON(dictionary: dictionary) else {
                        print("addressInfo failed to parse"); return
                    }
                    callback(user, addressInfo)
                }
            }; task.resume()
        }
    }
    
    func sendChangeOrderReq(images: [UIImage], formType: String, formBody: Data, po: String, callback: @escaping (Bool) -> () ) {
        let url = APICalls.host + "changeOrder/" + po
        let headers = ["formType", formType]
        
        alamoUpload(url: url, headers: headers, formBody: formBody, images: images, uploadType: "changeOrder") { success in
            callback(success)
        }
    }
    
    func uploadProfilePhoto(images: [UIImage], employee: String, callback: @escaping (Bool) -> () ) {
        guard let idNum = UserDefaults.standard.string(forKey: "employeeID") as? String else { return }
        let url = APICalls.host + "employee/\(idNum)/profileUpload"
        let headers = ["employee", employee]
        
        // Hard coded & may never use address info
        let info = UserData.AddressInfo(address: "121 main st", city: "Cerritos", state: "CA")
        let formBody = generateAddressData(addressInfo: info)
        
        alamoUpload(url: url, headers: headers, formBody: formBody, images: images, uploadType: "profilePhoto") { success in
            callback(success)
        }
    }
    
    func uploadJobImages(images: [UIImage], jobNumber: String, employee: String, callback: @escaping (Bool) -> () ) {
        let url = APICalls.host + "job/\(jobNumber)/upload"
        let headers = ["employee", employee]
        
        alamoUpload(url: url, headers: headers, formBody: Data(), images: images, uploadType: "job_\(jobNumber)") { success in
            callback(success)
        }
    }
    
    func submitSignature(images: [UIImage], formType: String, formBody: Data, employeeID: String, returnDate: String, callback: @escaping (Bool) -> () ) {
        let url = APICalls.host + "toolReturn/\(employeeID)"
        let headers = ["formType", formType]
        
        alamoUpload(url: url, headers: headers, formBody: formBody, images: images, uploadType: "toolReturn") { success in
            callback(success)
        }
    }
    
    func alamoUpload(url: String, headers: [String], formBody: Data, images: [UIImage], uploadType: String, callback: @escaping (Bool) -> ()) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
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
                                print("error while uploading file: \(response.result.error)");
                                self.failedUpload(msg: "\(uploadType) failed to upload.")
                                callback(false); return
                            }
                            self.successUpload(msg: "\(uploadType) uploaded successfully."); callback(true)
                        }
                        
                    case .failure(let encodingError):
                        print(encodingError);
                        self.failedUpload(msg: "\(uploadType) failed to upload.")
                        callback(false)
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
    
//    struct UserInfoCodeable: Encodable {
//        let userName: String
//        let employeeID: String
//        let coordinateLat: String
//        let coordinateLong: String
//        let currentRole: String
//    }
    
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
                } catch { (error)
                    if error != nil { print("looks like we couldn't setup that alarm"); print(error) }
                }
            }
        }
    }
    
    func failedUpload(msg: String) {
        let failedNotifc = UIViewController().createNotification(intervalInSeconds: 1, title: "FAILED", message: msg, identifier: "failedUpload")
        UNUserNotificationCenter.current().add(failedNotifc, withCompletionHandler: { (error) in
            if error != nil { return }
        })
    }
    
    func successUpload(msg: String)  {
        let completeNotif = UIViewController().createNotification(intervalInSeconds: 1, title: "SUCCESS", message: msg, identifier: "uploadSuccess")
        UNUserNotificationCenter.current().add(completeNotif, withCompletionHandler: { (error) in
            if error != nil { return }
        })
    }
    
}




