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
                self.saveIdUserAndPasswd(userNpass: unwrappedUsrAndPass, employeeId: id)
                
            } else {
                self.showAlert(withTitle: "Error", message: "Error in Response")
            }
        }
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
    
    func saveIdUserAndPasswd(userNpass: UsernameAndPassword, employeeId: String) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("UsernameAndPassword.plist")
        
        do {
            let data = try encoder.encode(userNpass)
            try data.write(to: path)
            
            UserDefaults.standard.set(employeeId, forKey: "employeeID")
            getUsernmAndPasswd()
        } catch {
            print("Error ecoding usr n pass w/ err: \(error)")
        }
    }
    
    func getUsernmAndPasswd() {
        if let path = Bundle.main.path(forResource: "UsernameAndPassword", ofType: "plist"),
            let xml = FileManager.default.contents(atPath: path),
            let usrAndPassList = try? PropertyListDecoder().decode(UsernameAndPassword.self, from: xml) {
            
            showAlert(withTitle: "Confirmed", message: "Username: \(usrAndPassList.username) and Password Confirmed.")
        }
        
//        var resourceDictionary: NSDictionary?
//
//        if let path = Bundle.main.path(forResource: "Preferences", ofType: "plist") {
//            resourceDictionary = NSDictionary(contentsOfFile: path)
//        }
//
//        if let resourceFileDIctionaryContent = resourceDictionary {
//            let nm = resourceFileDIctionaryContent["username"] as? String ?? ""
//            showAlert(withTitle: "Confirmed", message: "Username: \(nm) and Password Confirmed")
//        }
        
    }
}


