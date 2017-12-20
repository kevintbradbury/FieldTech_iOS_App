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
    
    @IBOutlet weak var phoneNumberField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    var authId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        UserLocation.instance.initialize()
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
    
    @IBAction func loginPressed(_ sender: Any) {
        
        if phoneNumberField.text == nil { return }
        authPhoneNumber(phoneNumber: phoneNumberField.text!)
    }
    
    func authPhoneNumber(phoneNumber: String) {
        var phoneNumberToString = "+1"; phoneNumberToString += phoneNumberField.text!
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumberToString) { (verificationID, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("could not verify phone number due to \(error)")
                    return
                }
            }
            guard let idToString: String = verificationID else { return }
            UserDefaults.standard.set(idToString, forKey: "authVerificationID")
            self.showVerfWin()
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
                        self.phoneNumberField.text?.removeAll()
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! EmployeeIDEntry
        
        if segue.identifier == "login" {
            vc.firAuthId = authId
        }
    }
    

}



