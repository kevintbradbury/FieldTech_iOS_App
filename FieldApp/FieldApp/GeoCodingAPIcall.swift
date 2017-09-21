//
//  GeoCodingAPIcall.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import Foundation

class GeoCodingCall {
    
    let apiURL = "https://maps.googleapis.com/maps/api/geocode/json?address="
    let apiKey = "&key=" + "AIzaSyDbWfZ30A-Ry2q-lZ3pb6klHy_WkUJVgic"
    
     let testaddress = "1951+W+Malvern+Ave"
     let testcity = "Fullerton"
     let teststate = "CA"
    
    func fetchCoordinates(/*address: String, city: String, state: String*/) -> Any {
        
        var combinedString = "\(apiURL)\(testaddress), +\(testcity), +\(teststate)\(apiKey)"
        
        var jsonData: [Any?] = []
        
        let url = URL(string: combinedString)!
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
            
            if error != nil {
                
                print("failed to fetch JSON from AWS")
                return
            }
            guard let verifiedData = data else {
                
                print("could not verify data from dataTask")
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: verifiedData, options: []) else {
                return
            }
        }
        print("Our Geocoding JSON is \(jsonData)")
        return jsonData
        
        task.resume()
    }
    
}
