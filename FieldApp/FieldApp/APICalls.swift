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
//import Firebase


class APICalls {
    let jsonString = "https://mb-server-app-kbradbury.c9users.io/"
    
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
    
    func sendCoordinates(employee: UserData.UserInfo, location: [String], autoClockOut: Bool, callback: @escaping (Bool, String, String, [Double], Bool) -> ()){
        let route = "employee/" + String(describing: employee.employeeID)
        let data = convertToJSON(employee: employee, location: location)
        let session = URLSession.shared;
        let bool = true
        var auto: String { if autoClockOut == true { return "true" } else { return "" } }
//        var testBool: String { var bool = true; if bool == true { return "true" } else { return "" } }
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
                    callback(successfulPunch, currentJob, poNumber, jobLatLong, clockedIn)
                    
                } else { callback(successfulPunch, "", "", [0.0], false) }
            }
        }
        task.resume()
    }
    
    func sendPhoto(imageData: Data, poNumber: String, callback: @escaping (HTTPURLResponse) -> () ) {
        
        let route = "job/" + poNumber + "/upload"
        let session = URLSession.shared;
        
        var request = setupRequest(route: route, method: "POST")
        request.addValue("application/x-www-formurlencoded", forHTTPHeaderField: "Content-Type")
        // "image/jpeg"
        request.httpBody = imageData
        
        print(request.httpBody)
        
        let task = session.dataTask(with: request) {data, response, error in
            
            if error != nil {
                print("failed to fetch JSON from database \n \(String(describing: response)) \n \(String(describing: error))")
                return
            } else {
                if let responseObj = response as? HTTPURLResponse {
                    if responseObj.statusCode == 201 {
                        
                        callback(responseObj)
                    } else {
                        print("error sending photo to server")
                        return
                    }
                }
            }
        }
        task.resume()
    }
    
    func fetchEmployee(employeeId: Int, callback: @escaping (UserData.UserInfo) -> ()){
        
        let route = "employee/" + String(employeeId)
        let request = setupRequest(route: route, method: "GET")
        let session = URLSession.shared;
        
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                print("failed to fetch JSON from database \n \(String(describing: response)) \n \(String(describing: error))")
                return
            } else {
                guard let verifiedData = data else {
                    print("could not verify data from dataTask")
                    return
                }
                
                guard let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary else { return }
                guard let user = UserData.UserInfo.fromJSON(dictionary: json) else {
                    print("json serialization failed")
                    return
                }
                callback(user)
            }
        }
        task.resume()
        
        
    }
    
    func setupRequest(route: String, method: String) -> URLRequest {
        let url = URL(string: jsonString + route)!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        return request
    }
    
}

extension APICalls {
    
    func parseJobs(from data: Data) -> [Job.UserJob] {
        var jobsArray: [Job.UserJob] = []
        
        guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? NSArray else {
            print("couldn't parse json objects as an Array")
            return jobsArray
        }
        
        for jobJson in json {
            if let jobDictionary = jobJson as? [String : Any]  {
                if let job = Job.UserJob.jsonToDictionary(dictionary: jobDictionary as NSDictionary) {
                    jobsArray.append(job)
                }
            } else {
                print("couldn't cast index json to type Dictionary")
                return jobsArray
            }
        }
        return jobsArray
    }
    
    struct UserInfoCodeable: Encodable {
        
        let userName: String
        let employeeID: String
        let coordinateLat: String
        let coordinateLong: String
    }
    
    func convertToJSON(employee: UserData.UserInfo, location: [String]) -> Data {
        
        let person = UserInfoCodeable(userName: employee.userName, employeeID: String(employee.employeeID), coordinateLat: location[0], coordinateLong: location[1])
        
        var combinedString = person.userName + " -- " + person.employeeID  + " |"
        combinedString += person.coordinateLat + ", " + person.coordinateLong + "|"
        
        var data = Data()
        
        do {
            let jsonEncoder = JSONEncoder()
            data = try jsonEncoder.encode(person)
        }
        catch {
            print(error)
            data = combinedString.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        }
        return data
    }
    
}

extension APICalls {
    
//    func uploadToFirebase(photo: UIImage, jobs: [Job.UserJob]) {
//
//        guard let imageData = UIImageJPEGRepresentation(photo, 0.5) else {
//            print("Could not get JPEG representation of UIImage")
//            return
//        }
//
//        let storage = Storage.storage()
//        let data = imageData
//        let storageRef = storage.reference()
//
//        let date = Date()
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MM.dd.yyyy"
//        let result = formatter.string(from: date)
//        print("\n imageName will be: image\(result)\(jobs[1].jobName)_PO_\(jobs[1].poNumber).jpg")
//
//        let imageStorageRef = storageRef.child("image\(result)\(jobs[0].jobName)_PO_\(jobs[0].poNumber).jpg")
//
//        let uploadTask = imageStorageRef.putData(data, metadata: nil) { (metadata, error) in
//
//            guard let metadata = metadata else {
//                print("uploadtask error \(String(describing: error))")
//                return
//            }
//            if error == nil {
//                _ = metadata.downloadURL()
//            }
//        }
//        uploadTask.enqueue()
//    }
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
                
                do { try eventstore.save(event, span: .thisEvent, commit: true) }
                catch { (error)
                    if error != nil { print("looks like we couldn't setup that alarm"); print(error) }
                }
            }
        }
    }
    
}
