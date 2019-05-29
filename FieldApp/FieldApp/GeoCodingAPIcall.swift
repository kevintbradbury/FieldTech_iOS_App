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
    
    static func getDistance(userLocation: CLLocationCoordinate2D, jobLocation: CLLocationCoordinate2D) -> Double {
        let userCoordinates = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let jobCoordinates = CLLocation(latitude: jobLocation.latitude, longitude: jobLocation.longitude)
        let distanceInMeters = userCoordinates.distance(from: jobCoordinates)
        let distanceInMiles = metersToMiles(meters: distanceInMeters)
        return distanceInMiles
    }
    
    static func metersToMiles(meters: Double) -> Double{
        let miles = meters * 0.000621371
        return miles
    }
    
    static func milesToMeters(miles: Double) -> Double {
        let meters = miles * 1609.34
        return meters
    }
}


