//
//  ViewController.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import Firebase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var phoneNumberFIeld: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    var jobs: [Job.UserJob] = []
    let main = OperationQueue.main
    var location = UserData.init().userLocation
    var jobAddress = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        UserLocation.instance.initialize()
        getJobs() {jobs in
            self.checkJobProximity()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Auth.auth().addStateDidChangeListener() { (auth, user) in
            if user != nil {
                self.performSegue(withIdentifier: "login", sender: self)
            }
        }
        Auth.auth().languageCode = "en"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getJobs(callback: @escaping ([Job.UserJob]) -> ()) {
        
        APITestCall().fetchJobInfo() { jobs in
            self.jobs = jobs
            callback(jobs)
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            self.main.addOperation {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            print("Index 0 Job is --> \(self.jobs[0].jobName) \n")
        }
    }
    
    func getLocation(completition: @escaping (CLLocationCoordinate2D) -> Void) {
        
        UserLocation.instance.requestLocation(){ coordinate in
            
            self.location = coordinate
            
//            if (self.location?.latitude)! > CLLocationDegrees(0.0) {
                print("User location is --> \(coordinate) \n")
//            } else {
//                print("location failed")
//            }
            completition(coordinate)
        }
    }
    
    func checkJobProximity() {
        
        self.getLocation() { completition in
            
            self.jobAddress = "\(self.jobs[0].jobAddress), \(self.jobs[0].jobCity), \(self.jobs[0].jobState)"
            GeoCoding.locationForAddressCode(address: self.jobAddress) { location in
                let distance = GeoCoding.getDistance(userLocation: self.location!, jobLocation: location!)
                print("Miles from job location is --> \(distance) \n")
                
                if distance > 1.0 {
                    print("NO <-- User is not in proximity to Job location \n")
                } else {
                    print("YES <-- User is in proximity to Job location \n")
                }
            }
        }
        
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        
        if phoneNumberFIeld.text == nil { return }
        authPhoneNumber(phoneNumber: phoneNumberFIeld.text!)
        showVerfWin()
    }
    
    func authPhoneNumber(phoneNumber: String) {
        var phoneNumberToString = "+1"; phoneNumberToString += phoneNumberFIeld.text!
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumberToString) { (verificationID, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("could not verify phone number due to \(error)")
                    return
                }
            }
            guard let idToString: String = verificationID else { return }
            UserDefaults.standard.set(idToString, forKey: "authVerificationID")
        }
    }
    
    func showVerfWin() {
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
                        self.phoneNumberFIeld.text?.removeAll()
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
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

