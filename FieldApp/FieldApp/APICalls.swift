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


class APICalls {
    
    let jsonString = "https://mb-server-app-kbradbury.c9users.io/"
    
    func fetchJobInfo(callback: @escaping ([Job.UserJob]) -> ()) {
        
        let url = URL(string: jsonString)!
        let request = URLRequest(url: url)
        let session = URLSession.shared;
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                print("failed to fetch JSON from AWS")
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
    
    func parseJobs(from data: Data) -> [Job.UserJob] {
        var jobsArray: [Job.UserJob] = []
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []),
            let jsonArray = json as? NSArray else {
                return jobsArray
        }
        
        for index in jsonArray {
            guard let job = Job.UserJob.jsonToDictionary(dictionary: index as! NSDictionary) else { continue }
            jobsArray.append(job)
        }
        return jobsArray
    }
    
    
    
    
    
    func sendCoordinates(employee: UserData.UserInfo, location: [String]){
        
        let route = "employee/" + String(describing: employee.employeeID)
        let url = URL(string: jsonString + route)!
        let data = convertToJSON(employee: employee, location: location)
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0 * 1000)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = data
        print("httpBody Data as a String -- " + String(data: request.httpBody!, encoding: .utf8)!)
        
        let session = URLSession.shared;
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
                guard let user = UserData.UserInfo.fromJSON(dictionary: json) else { return }
                
//            --->  Need to handle bad/unauthorized response here
            }
        }
        task.resume()
    }
    
    struct UserInfoCodeable: Encodable {

        let userName: String
        let employeeID: String
        let coordinateLat: String
        let coordinateLong: String
//        let employeeJobs: [String]
    }
    
    func convertToJSON(employee: UserData.UserInfo, location: [String]) -> Data {
        
        var person = UserInfoCodeable(userName: employee.userName, employeeID: String(employee.employeeID), coordinateLat: location[0], coordinateLong: location[1])
        //employeeJobs: employee.employeeJobs
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
