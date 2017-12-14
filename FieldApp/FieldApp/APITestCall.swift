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
    var job: Job.UserJob?
    var employee: UserData.UserInfo?
    var coordinates: CLLocationCoordinate2D?
    
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
    func isEmployeePhone(view: UIViewController, callback: @escaping (UserData.UserInfo) -> ()) {
        let alert = UIAlertController(title: "Employee ID Number", message: "Enter your employee number", preferredStyle: .alert)
        var foundUser: UserData.UserInfo?
        let confirmEmployeeAlert = UIAlertAction(title: "Send", style: .destructive) { action in
            
            let employeeNumber = alert.textFields![0]
            var employeeNumberToInt: Int?;
            
            if employeeNumber.text != nil {
                
                employeeNumberToInt = Int(employeeNumber.text!)
                
                self.fetchEmployee(employeeId: employeeNumberToInt!) { user in
                    foundUser = user
                    if foundUser != nil {
                        print(foundUser!)
                        callback(foundUser!)
                    }
                }
            }
        }
        
        alert.addTextField { textFieldEmployeeNumber in
            textFieldEmployeeNumber.placeholder = "Employee Number"
            textFieldEmployeeNumber.keyboardType = UIKeyboardType.phonePad
            textFieldEmployeeNumber.isSecureTextEntry = true
        }
        alert.addAction(confirmEmployeeAlert)
        
        view.present(alert, animated: true, completion: nil)
    }
    
    func fetchEmployee(employeeId: Int, callback: @escaping (UserData.UserInfo) -> ()){
        
        let route = "employee/" + String(employeeId)
        let url = URL(string: jsonString + route)!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0 * 1000)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Accept")
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
                callback(user)
            }
        }
        task.resume()
    }
    
    func sendCoordinates(){
        
        let route = "job/" + String(describing: employee?.employeeID)
        let url = URL(string: jsonString + route)!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0 * 1000)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let data = convertToJSON()
        
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
//                guard let user = UserData.UserInfo.fromJSON(dictionary: json) else { return }

            }
        }
        task.resume()
    }
    struct UserInfoCodeable: Encodable {
        
        var employeeID: Int
        var employeeJobs: [String]
        var userName: String
    }
    
    func convertToJSON() -> Data {
        var data = Data()
        //var employeeLocation = UserData().userLocation
        let employee = UserInfoCodeable(employeeID: 0, employeeJobs: ["ABC"], userName: "")
        
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(employee)
            let jsonString = String(data: jsonData, encoding: .utf8)
            print("JSON String is: " + jsonString!)
            data = jsonData
        }
        catch {
            print(error)
        }
        return data
    }
    
    func showVerfWin(view: UIViewController) {
        let alert = UIAlertController(title: "Password", message: "Enter your password", preferredStyle: .alert)
        
        let confirmCodeAlert = UIAlertAction(title: "Okay", style: .default) { action in
            
            let password = alert.textFields![0]
            if password.text != nil {
                //alert.dismiss(animated: true, completion: nil)
            }
        }
        
        alert.addTextField { textFieldPhoneNumber in
            textFieldPhoneNumber.placeholder = "Password"
            textFieldPhoneNumber.keyboardType = UIKeyboardType.phonePad
            textFieldPhoneNumber.isSecureTextEntry = true
        }
        alert.addAction(confirmCodeAlert)
        
        view.present(alert, animated: true, completion: nil)
    }
    
}
