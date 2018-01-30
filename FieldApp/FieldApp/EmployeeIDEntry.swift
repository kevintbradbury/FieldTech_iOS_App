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
    @IBOutlet weak var enterIDText: UILabel!
    @IBOutlet weak var clockIn: UIButton!
    @IBOutlet weak var clockOut: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    
    var jobAddress = ""
    var jobs: [Job.UserJob] = []
    let firebaseAuth = Auth.auth()
    var foundUser: UserData.UserInfo?
    var location = UserData.init().userLocation
    let main = OperationQueue.main
    var firAuthId = UserDefaults.standard.string(forKey: "authVerificationID")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
        activityIndicator.hidesWhenStopped = true
        UserLocation.instance.initialize()
        hideTextfield()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    func isEmployeePhone(callback: @escaping (UserData.UserInfo) -> ()) {
        
        var employeeNumberToInt: Int?;
        if foundUser?.employeeID != nil {
            guard let employeeNumber = foundUser?.employeeID else { return }
            employeeNumberToInt = Int(employeeNumber)
        } else {
            guard let employeeNumber = employeeID.text else { return }
            employeeNumberToInt = Int(employeeNumber)
        }
        
        fetchEmployee(employeeId: employeeNumberToInt!) { user in
            self.foundUser = user
            callback(self.foundUser!)
            self.main.addOperation {
                self.activityIndicator.isHidden = true
                self.performSegue(withIdentifier: "return", sender: self)
            }
        }
    }
    
    @IBAction func sendIDNumber(_ sender: Any) {
        
        activityIndicator.startAnimating()
        if employeeID.text != "" {
            isEmployeePhone() { foundUser in
                self.getLocation() { coordinate in
                    let locationArray = [String(coordinate.latitude), String(coordinate.longitude)]
                    APICalls().sendCoordinates(employee: foundUser, location: locationArray)
                }
            }
        } else {
            self.incorrectID()
        }
    }
    
    @IBAction func backToHome(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goClockIn(_ sender: Any) {
        clockInClockOut()
    }
    
    @IBAction func goClockOut(_ sender: Any) {
        clockInClockOut()
    }
    
    func clockInClockOut() {
        activityIndicator.startAnimating()
        if foundUser?.employeeID != nil {
            isEmployeePhone() { foundUser in
                self.getLocation() { coordinate in
                    let locationArray = [String(coordinate.latitude), String(coordinate.longitude)]
                    APICalls().sendCoordinates(employee: foundUser, location: locationArray)
                }
            }
        } else {
            self.incorrectID()
        }
    }
    func incorrectID() {
        let actionsheet = UIAlertController(title: "Error", message: "Unable to find that user", preferredStyle: UIAlertControllerStyle.alert)

        let ok = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) {(action) in
            self.employeeID.text = ""
            actionsheet.dismiss(animated: true, completion: nil)
            self.main.addOperation {
                self.activityIndicator.stopAnimating()
            }
        }
        actionsheet.addAction(ok)
        self.present(actionsheet, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! HomeView
        
        UserDefaults.standard.set(foundUser?.employeeID, forKey: "employeeID")
        
        if segue.identifier == "return" {
            vc.employeeInfo = foundUser
            vc.firAuthId = firAuthId
        }
    }
    
    func getLocation(completition: @escaping (CLLocationCoordinate2D) -> Void) {
        
        UserLocation.instance.requestLocation(){ coordinate in
            self.location = coordinate
            if self.location != nil {
                completition(self.location!)
            }
        }
    }
    
    func fetchEmployee(employeeId: Int, callback: @escaping (UserData.UserInfo) -> ()){
        
        let route = "employee/" + String(employeeId)
        let request = APICalls().setupRequest(route: route, method: "GET")
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
                        self.incorrectID()
                    }
                    return
                }
                callback(user)
            }
        }
        task.resume()
    }
    
    func hideTextfield() {
        if foundUser != nil {
            employeeID.isHidden = true
            sendButton.isHidden = true
            enterIDText.isHidden = true
        } else {
            clockIn.isHidden = true
            clockOut.isHidden = true
        }
    }
}
