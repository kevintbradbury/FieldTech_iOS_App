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


class UserLocation: NSObject, CLLocationManagerDelegate, MKMapViewDelegate  {
    
    static let instance = UserLocation()
    private override init() {}
    
    private var alreadyInitialized = false
    private var onLocation: ((CLLocationCoordinate2D) -> Void)?
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    var currentRegion: MKCoordinateRegion?
    
    var currentCoordinate: CLLocationCoordinate2D? {
        return currentLocation?.coordinate
    }
    
    func initialize() {
        
        if alreadyInitialized {
            
            print("Failed to Initialize locationManager")
            return
        }
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        alreadyInitialized = true
    }
    
    func requestLocation(callback: @escaping ((CLLocationCoordinate2D) -> Void)) {
        
        self.onLocation = callback
        locationManager.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location: CLLocation = locations.first else {
            
            print("Failed to Update First Location")
            return
        }
        
        defer {
            
            locationManager.stopUpdatingLocation()
            
        }
        
        self.currentLocation = location
        let region = calculateRegion(for: location.coordinate)
        self.currentRegion = region
        
        onLocation?(location.coordinate)
        onLocation = nil
        
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
    
    private func calculateRegion(for location: CLLocationCoordinate2D) -> MKCoordinateRegion {
        
        let latitude = location.latitude
        let longitude = location.longitude
        let latDelta: CLLocationDegrees = 0.05
        let longDelta: CLLocationDegrees = 0.05
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        
        return region
        
    }
    
}

extension UserLocation {
    func region(withGeotification geotification: Geotification) -> CLCircularRegion {
        let region = CLCircularRegion(center: geotification.coordinate, radius: geotification.radius, identifier: geotification.identifier)
        region.notifyOnEntry = (geotification.eventType == .onEntry)
        region.notifyOnExit = !region.notifyOnEntry
        return region
    }
    
    func startMonitoring(geotification: Geotification) {
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            fatalError("GPS loc not set to ALWAYS in use")
        }
        let region = self.region(withGeotification: geotification)
        locationManager.startMonitoring(for: region)
    }
    
    func stopMonitoring(geotification: Geotification) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == geotification.identifier else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("monitoring failed for region w/ identifier: \(region?.identifier)")
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manger fialed with followign erro: \(error)")
    }
    
    
}


