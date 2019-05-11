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
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var loginBtn: UIButton!
    
    @IBAction func loginPressed(_ sender: Any) {
    }
    
    func getVals() {
        guard let usrnm = usernameField.text,
            let passwrd = passwordField.text else { return }
        let userNpass = UsernameAndPassword(username: usrnm, password: passwrd)
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Preferences.plist")
        
        do {
            let data = try encoder.encode(userNpass)
            try data.write(to: path)
        } catch {
            print(error)
        }
    }
}
