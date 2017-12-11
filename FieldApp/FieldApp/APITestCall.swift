//
//  APITestCall.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import Foundation
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
    
    //  --- Still need to resolve employee data
    //callback: @escaping (UserData) -> ()
    func fetchEmployee(employeeId: Int, callback: @escaping (UserData.UserInfo) -> ()){
        
        let route = "employee/" + String(employeeId)
        let url = URL(string: jsonString + route)!
        let request = URLRequest(url: url)
        let session = URLSession.shared;
        let task = session.dataTask(with: request) {data, response, error in
            if error != nil {
                print("failed to fetch JSON from database")
                return
            } else {
                guard let verifiedData = data else {
                    print("could not verify data from dataTask")
                    return
                }
                print(response)
                guard let json = (try? JSONSerialization.jsonObject(with: verifiedData, options: [])) as? NSDictionary else {
                    print("json serialization failed")
                    return
                }
                
                guard let user = UserData.UserInfo.fromJSON(dictionary: json) else { return }
                print("user is : \(user) \n")
                callback(user)
            }
        }
        task.resume()
    }
    func isEmployeePhone(view: UIViewController) {
        let alert = UIAlertController(title: "Verification", message: "Enter your employee number", preferredStyle: .alert)
        var foundUser: UserData.UserInfo?
        let confirmEmployeeAlert = UIAlertAction(title: "Send", style: .default) { action in
            
            let employeeNumber = alert.textFields![0]
            var employeeNumberToInt: Int?;
            
            if employeeNumber.text != nil {
                
                employeeNumberToInt = Int(employeeNumber.text!)
                
                self.fetchEmployee(employeeId: employeeNumberToInt!) { user in
                    if (user.employeeID == nil) {
                        alert.dismiss(animated: true, completion: nil)
                        return
                    } else {
                        foundUser = user
                        print(foundUser)
                        self.showVerfWin(view: view)
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
    
    func showVerfWin(view: UIViewController) {
        let alert = UIAlertController(title: "Verification", message: "Enter verification code received via SMS", preferredStyle: .alert)
        
        let confirmCodeAlert = UIAlertAction(title: "Send", style: .default) { action in
            
            let verificationCode = alert.textFields![0]
            var verificationCodeToString = "";
            if verificationCode.text != nil {
                verificationCodeToString = verificationCode.text!
                
                if let authVerificationID = UserDefaults.standard.string(forKey: "authVerificationID") {
                    
                    let credential = PhoneAuthProvider.provider().credential(withVerificationID: authVerificationID, verificationCode: verificationCodeToString)
                    
                    //Add Firebase sign in here
                    Auth.auth().signIn(with: credential) { (user, error) in
                        if let error = error {
                            print("received the following error from credentials --> \(error) \n")
                        }
                        LoginViewController().phoneNumberField.text?.removeAll()
                    }
                }
            }
        }
        
        alert.addTextField { textFieldPhoneNumber in
            textFieldPhoneNumber.placeholder = "Verification code"
            textFieldPhoneNumber.keyboardType = UIKeyboardType.phonePad
            textFieldPhoneNumber.isSecureTextEntry = true
        }
        alert.addAction(confirmCodeAlert)
        
        view.present(alert, animated: true, completion: nil)
    }
    
}
