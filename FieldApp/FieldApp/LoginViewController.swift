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
import FirebaseAuth


class LoginViewController: UIViewController {   //, AuthUIDelegate {
    
    @IBOutlet var enterPhoneLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var phoneNumberField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    var authId = UserDefaults.standard.string(forKey: "authVerificationID")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.hidesWhenStopped = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        Auth.auth().languageCode = "en"

        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                self.activityIndicator.stopAnimating()
//                self.performSegue(withIdentifier: "home", sender: nil)
                self.checkForUsernameNPassword()
            }
        }

        if Auth.auth().currentUser == nil { activityIndicator.stopAnimating() }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginPressed(_ sender: Any) {
        activityIndicator.startAnimating()

        guard let phoneNum = phoneNumberField.text else {
            showAlert(withTitle: "Error", message: "No number given or formatting issue."); return
        }
        authPhoneNumber(phoneNumber: phoneNum)
    }
    
    func checkForUsernameNPassword() {
        var savedUserNpass: UsernameAndPassword?
        
        UsernameAndPassword.getUsernmAndPasswd() { userNpass in
            savedUserNpass = userNpass
        }
        
        if let usernm = savedUserNpass?.username,
            let passwd = savedUserNpass?.password {
            self.performSegue(withIdentifier: "home", sender: nil)
        } else {
            self.performSegue(withIdentifier: "addLoginInfo", sender: nil)
        }
    }
    
    func authPhoneNumber(phoneNumber: String) {
        let adjustedNum = String("+1\(phoneNumber)")
        print("phoneNumber", adjustedNum)

        PhoneAuthProvider.provider()
            .verifyPhoneNumber(adjustedNum, uiDelegate: nil) { (verificationID, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self.activityIndicator.stopAnimating()
                    self.showAlert(
                        withTitle: "Error", message: "Couldn't verify number, error: \n \(error.localizedDescription).\n Check formatting and remove 1 from the beginning of the number if necessary."
                    )
                    print(error)
                    return
                } else {
                    guard let idToString: String = verificationID else { return }
                    UserDefaults.standard.set(idToString, forKey: "authVerificationID")
                    self.showVerfWin()
                }
            }
        }
    }

    func showVerfWin() {
        let alert = UIAlertController(title: "Verification", message: "Enter verification code received via SMS", preferredStyle: .alert)

        let confirmCodeAlert = UIAlertAction(title: "Send", style: .default) { action in
            self.activityIndicator.startAnimating()

            let verificationCode = alert.textFields![0]
            var verificationCodeToString = "";
            if verificationCode.text != nil {
                verificationCodeToString = verificationCode.text!

                if let authVerificationID = UserDefaults.standard.string(forKey: "authVerificationID") {

                    let credential = PhoneAuthProvider.provider().credential(withVerificationID: authVerificationID, verificationCode: verificationCodeToString)

                    //Add Firebase sign in here
                    Auth.auth().signInAndRetrieveData(with: credential) { (user, error) in
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
    
}



