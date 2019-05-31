//
//  OneTimeLoginController.swift
//  FieldApp
//
//  Created by MB Mac 3 on 5/10/19.
//  Copyright © 2019 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit

class OneTimeLoginController: UIViewController {
    @IBOutlet var employeeIDfield: UITextField!
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var loginBtn: UIButton!
    @IBOutlet var activityBkgd: UIView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func loginPressed(_ sender: Any) {
        getVals()
    }
    
    var employeeID: String?,
    userNpass: UsernameAndPassword?,
    userInfo: UserData.UserInfo?,
    userAddressInfo: UserData.AddressInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
    }
    
    func setView() {
        self.setDismissableKeyboard(vc: self)
        passwordField.isSecureTextEntry = true
        activityBkgd.isHidden = true
        activityIndicator.isHidden = true
        activityIndicator.hidesWhenStopped = true
    }
    
    func getVals() {
        guard let id = employeeIDfield.text,
            let usrnm = usernameField.text,
            let psswrd = passwordField.text,
            let employeeId = Int(id) else {
                self.showAlert(withTitle: "Incomplete values", message: "Please enter all information on the form.")
                return
        }
        
        userNpass = UsernameAndPassword(username: usrnm, password: psswrd)
        
        inProgress(activityBckgd: activityBkgd, activityIndicator: activityIndicator, showProgress: false)
        
        fetchEmployee(employeeId: employeeId) { success in
            self.completeProgress(activityBckgd: self.activityBkgd, activityIndicator: self.activityIndicator)
            
            if success == true && self.userInfo != nil && self.userAddressInfo != nil {
                guard let unwrappedUsrAndPass = self.userNpass else { return }
                
                UsernameAndPassword.saveIdUserAndPasswd(userNpass: unwrappedUsrAndPass, employeeId: id) { userNpass in
                    self.showSavedAlert(withTitle: "Complete", message: "Saved username: \(userNpass.username) and password.")
                }
            } else {
                self.showAlert(withTitle: "Error", message: "Error in Response")
            }
        }
    }
    
    func showSavedAlert(withTitle title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel) { action in
            self.performSegue(withIdentifier: "doneWithLogin", sender: nil)
        }
        let main = OperationQueue.main
        
        alert.addAction(action)
        main.addOperation { self.present(alert, animated: true, completion: nil) }
    }
    
    func fetchEmployee(employeeId: Int, callback: @escaping (Bool) -> ()) {
        guard let usernm = self.userNpass?.username,
            let passwd = self.userNpass?.password else {
                callback(false); return
        }
        let route = "employee/" + String(employeeId)
        let url = URL(string: APICalls.host + route)!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        APICalls.getFIRidToken() { firebaseIDtoken in
            request.addValue(firebaseIDtoken, forHTTPHeaderField: "Authorization")
            request.addValue(usernm, forHTTPHeaderField: "username")
            request.addValue(passwd, forHTTPHeaderField: "password")
            
            APICalls().startSession(request: request, route: route) { json in
                if json["error"] != nil {
                    callback(false); return
                }
                guard let user = UserData.UserInfo.fromJSON(dictionary: json),
                    let dictionary = json["addressInfo"] as? NSDictionary,
                    let addressInfo = UserData.AddressInfo.fromJSON(dictionary: dictionary) else {
                        
                        print("failed to parse UserData from json: \(json)");
                        self.completeProgress(activityBckgd: self.activityBkgd, activityIndicator: self.activityIndicator)
                        
                        guard let resMsg = json as? [String:String] else { return }
                        self.handleResponseType(responseType: resMsg)
                        return
                }
                self.userInfo = user
                self.userAddressInfo = addressInfo
                callback(true)
            }
        }
    }

}


