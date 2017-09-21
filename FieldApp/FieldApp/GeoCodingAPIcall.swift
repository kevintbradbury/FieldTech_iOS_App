//
//  GeoCodingAPIcall.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import Foundation
import CoreLocation
import AddressBook
import AddressBookUI

class GeoCoding {
    
    static func locationForAddressCode(address: String, callback: @escaping (CLLocationCoordinate2D?) -> Void) {
        
        let testaddress = "1951 W Malvern Ave"
        let testcity = "Fullerton"
        let teststate = "CA"
        
        let combinedString = "\(testaddress), \(testcity), \(teststate)"
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            
            if let error = error {
                print("geocoding failed due to --> \(error)")
            }
            
            //Pick the first placemark and center the map there.
            if let placemark = placemarks?.first, let location = placemark.location?.coordinate {
                callback(location)
                print("geocoding location is : \(location)")
                return
            }
            
            callback(nil)
        }
    }
    
    static func getDistance(userLocation: CLLocationCoordinate2D, storeLocation: CLLocationCoordinate2D) -> Double {
        
        let userCoordinate = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        
        let storeCoordinate = CLLocation(latitude: storeLocation.latitude, longitude: storeLocation.longitude)
        
        let distanceInMeters = userCoordinate.distance(from: storeCoordinate)
        
        return distanceInMeters
        
    }
    
    static func milesToMeters(miles: Double) -> Double {
        
        let meters = miles * 1609.34
        
        return meters
        
    }
    
    static func metersToMiles(meters: Double) -> Double{
        
        let miles = meters * 0.000621371
        
        return miles
        
    }
    
}
