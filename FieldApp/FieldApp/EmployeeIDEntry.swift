//
//  EmployeeIDEntry.swift
//  FieldApp
//
//  Created by MB Mac 3 on 12/20/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import Firebase

class EmployeeIDEntry: UIViewController {
    
    @IBOutlet weak var employeeID: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var jobAddress = ""
    var jobs: [Job.UserJob] = []
    let firebaseAuth = Auth.auth()
    var foundUser: UserData.UserInfo?
    var location = UserData.init().userLocation
    let main = OperationQueue.main
    var firAuthId = UserDefaults.standard.string(forKey: "authVerificationID")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserLocation.instance.initialize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        activityIndicator.isHidden = true
        super.viewDidAppear(true)
    }
    
    func isEmployeePhone(callback: @escaping (UserData.UserInfo) -> ()) {
        
        var employeeNumberToInt: Int?;
        guard let employeeNumber = employeeID.text else { return }
        
        employeeNumberToInt = Int(employeeNumber)
        
        fetchEmployee(employeeId: employeeNumberToInt!) { user in
            self.foundUser = user
            callback(self.foundUser!)
            self.main.addOperation {
                self.activityIndicator.isHidden = true
                self.performSegue(withIdentifier: "home", sender: self)
            }
        }
    }
    
    @IBAction func sendIDNumber(_ sender: Any) {
        activityIndicator.isHidden = false
        if employeeID.text != "" {
            isEmployeePhone() { foundUser in
                self.getLocation() { coordinate in
                    let locationArray = [String(coordinate.latitude), String(coordinate.longitude)]
                    APICalls().sendCoordinates(employee: foundUser, location: locationArray)
                }
            }
        } else {
            incorrectID()
        }
    }
    
    func getLocation(completition: @escaping (CLLocationCoordinate2D) -> Void) {
        
        UserLocation.instance.requestLocation(){ coordinate in
            self.location = coordinate
            completition(coordinate)
        }
    }
    
    func fetchEmployee(employeeId: Int, callback: @escaping (UserData.UserInfo) -> ()){
        
        let jsonString = "https://mb-server-app-kbradbury.c9users.io/"
        let route = "employee/" + String(employeeId)
        let url = URL(string: jsonString + route)!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0 * 1000)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
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
                    self.main.addOperation {
                        self.activityIndicator.isHidden = true
                        self.incorrectID()
                    }
                    return
                }
                callback(user)
            }
        }
        task.resume()
        
        
    }
    
    func incorrectID() {
        let actionsheet = UIAlertController(title: "Error", message: "Unable to find that user", preferredStyle: UIAlertControllerStyle.alert)
        
        let ok = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) {(action) in
            self.employeeID.text = ""
            actionsheet.dismiss(animated: true, completion: nil)
        }
        actionsheet.addAction(ok)
        self.present(actionsheet, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! HomeView
        
        if segue.identifier == "home" {
            vc.employeeInfo = foundUser
            vc.firAuthId = firAuthId
        }
    }
}
