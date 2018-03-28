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
import Firebase
import FirebaseStorage

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
    
    func sendCoordinates(employee: UserData.UserInfo, location: [String], callback: @escaping (Bool, String, Int) -> ()){
        
        let route = "employee/" + String(describing: employee.employeeID)
        let data = convertToJSON(employee: employee, location: location)
        let session = URLSession.shared;
        
        var request = setupRequest(route: route, method: "POST")
        request.httpBody = data
        
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                print("failed to fetch JSON from database \n \(String(describing: response))")
                return
            } else {
                guard let verifiedData = data else {
                    print("could not verify data from dataTask")
                    return
                }
                guard let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary else {
                    print("json serialization failed")
                    return
                }
                guard let successfulPunch = json["success"] as? Bool else {
                    print("couldnt parse successful punch bool")
                    return
                }
                
                if let currentJob = json["job"] as? String,
                    let poNumber = json["poNumber"] as? Int {
                    print("punch was success or no ?")
                    print(successfulPunch)
                    print(currentJob)
                    print(poNumber)
                    
                    callback(successfulPunch, currentJob, poNumber)
                } else {
                    callback(successfulPunch, "", 000)
                }
                
                
            }
        }
        task.resume()
    }
    
    func sendPhoto(imageData: Data, poNumber: Int, callback: @escaping (HTTPURLResponse) -> () ) {
        
        let route = "job/" + String(poNumber) + "/upload"
        let session = URLSession.shared;
        
        var request = setupRequest(route: route, method: "POST")
        request.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
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
    
    func uploadToFirebase(photo: UIImage, jobs: [Job.UserJob]) {
        
        guard let imageData = UIImageJPEGRepresentation(photo, 0.5) else {
            print("Could not get JPEG representation of UIImage")
            return
        }
        
        let storage = Storage.storage()
        let data = imageData
        let storageRef = storage.reference()
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        let result = formatter.string(from: date)
        print("\n imageName will be: image\(result)\(jobs[1].jobName)_PO_\(jobs[1].poNumber).jpg")
        
        let imageStorageRef = storageRef.child("image\(result)\(jobs[0].jobName)_PO_\(jobs[0].poNumber).jpg")
        
        let uploadTask = imageStorageRef.putData(data, metadata: nil) { (metadata, error) in
            
            guard let metadata = metadata else {
                print("uploadtask error \(String(describing: error))")
                return
            }
            if error == nil {
                _ = metadata.downloadURL()
            }
        }
        uploadTask.enqueue()
    }
}
