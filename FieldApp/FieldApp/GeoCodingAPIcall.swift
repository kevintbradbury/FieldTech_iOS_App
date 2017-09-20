//
//  GeoCodingAPIcall.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import Foundation

class GeoCodingCall {
    
    let url = "https://maps.googleapis.com/maps/api/geocode/json?address="
    let apiKey = "&key=" + "AIzaSyDbWfZ30A-Ry2q-lZ3pb6klHy_WkUJVgic"
    var address = ""
    var city = ", "
    var state = ", "
 
    func fetchCoordinates(address: String, city: String, state: String) {
        
    }
    
}
