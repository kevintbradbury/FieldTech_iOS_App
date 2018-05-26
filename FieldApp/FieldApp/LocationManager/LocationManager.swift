//
//  LocationManager.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import UIKit


class UserLocation: NSObject, CLLocationManagerDelegate  {
    
    static let instance = UserLocation()
    private override init() {}
    
    private var alreadyInitialized = false
    private var onLocation: ((CLLocationCoordinate2D) -> Void)?
    var locationManager: CLLocationManager?
    var currentLocation: CLLocation?
    var currentRegion: MKCoordinateRegion?
    var currentCoordinate: CLLocationCoordinate2D? { return currentLocation?.coordinate }
    
    func initialize() {
        if alreadyInitialized { print("locationManager is already initialized"); return }
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.distanceFilter = kCLDistanceFilterNone
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingLocation()
        alreadyInitialized = true
    }
    
    func requestLocation(callback: @escaping ((CLLocationCoordinate2D) -> Void)) {
        self.onLocation = callback
        locationManager?.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        guard let location: CLLocation = locations.first else {
            print("Failed to Update First Location")
            return
        }

//        defer { locationManager?.stopUpdatingLocation() }

        self.currentLocation = location
        let region = calculateRegion(for: location.coordinate)
        self.currentRegion = region

        onLocation?(location.coordinate)
//        onLocation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        var allowAuthorization = false
        var locationStatus: String
        
        switch status {
        case CLAuthorizationStatus.restricted:
            locationStatus = "Restricted Access to Location"
            
        case CLAuthorizationStatus.denied:
            locationStatus = "User denied access to location"
            
        case CLAuthorizationStatus.notDetermined:
            locationStatus = "Status not determined"
            
        default:
            locationStatus = "Location Access Granted"
            allowAuthorization = true
        }
    }
    
    func calculateRegion(for location: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let latitude = location.latitude
        let longitude = location.longitude
        let latDelta: CLLocationDistance = 0.05 // set @ 20 for testing, BUT change to 500 for production
        let longDelta: CLLocationDistance = 0.05 // 500
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        
        return region
    }
}

extension UserLocation {
    
    func startMonitoring(location: CLLocationCoordinate2D) {
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            fatalError("GPS loc not set to ALWAYS in use")
        } else {
            //radius: 402
            let region = CLCircularRegion(center: location, radius: 2, identifier: "range") // radius 1/4 mile ~= 402 meters
            locationManager?.startMonitoring(for: region)
            print("location to begin monitoring: \(location)")
        }
    }
    
    func stopMonitoring() {
        print("stop monitoring location")
        for region in (locationManager?.monitoredRegions)! {
            guard let circularRegion = region as? CLCircularRegion else { continue }
            locationManager?.stopMonitoring(for: circularRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) { print("monitoring failed for region w/ identifier: "); print(region?.identifier) }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { print("Location manger failed with followign error: "); print(error) }

//    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) { AppDelegate().handleGeoFenceEvent(forRegion: region) }
}


