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
import UserNotifications


class UserLocation: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate  {
    
    static let instance = UserLocation()
    override init() {}
    
    var alreadyInitialized = false
    var onLocation: ((CLLocationCoordinate2D) -> Void)?
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var currentRegion: MKCoordinateRegion?
    var currentCoordinate: CLLocationCoordinate2D? { return currentLocation?.coordinate }
    var notificationCenter: UNUserNotificationCenter?
    var regionToCheck: CLCircularRegion?
    
    func initialize() {
//        if alreadyInitialized { print("locationManager is already initialized"); return }
//        locationManager = CLLocationManager()
        
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        notificationCenter = UNUserNotificationCenter.current()
        notificationCenter?.delegate = self
        
        alreadyInitialized = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocation = locations.first else { print("Failed to Update First Location"); return }

        self.currentLocation = location
        let region = calculateRegion(for: location.coordinate)
        self.currentRegion = region

        onLocation?(location.coordinate)
        print(manager.monitoredRegions); print(location.coordinate)
    }
    //        onLocation = nil
    //        defer { locationManager?.stopUpdatingLocation() }
    
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
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) { print("monitoring failed for region w/ identifier: "); print(region?.identifier) }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { print("Location manger failed with followign error: "); print(error) }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) { handleGeoFenceEvent(forRegion: region) }
    
}

extension UserLocation {
    func requestLocation(callback: @escaping ((CLLocationCoordinate2D) -> Void)) {
        self.onLocation = callback
        locationManager.startUpdatingLocation()
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

    func startMonitoring(location: CLLocationCoordinate2D) {
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            fatalError("GPS loc not set to ALWAYS in use")
        } else {
            //radius: 402
            let region = CLCircularRegion(center: location, radius: 2, identifier: "range") // radius 1/4 mile ~= 402 meters
            regionToCheck = region
            locationManager.startMonitoring(for: region)
            print("location to begin monitoring: \(locationManager.monitoredRegions)")
        }
    }
    
    func stopMonitoring() {
        print("stop monitoring location")
        for region in (locationManager.monitoredRegions) {
            guard let circularRegion = region as? CLCircularRegion else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    func handleGeoFenceEvent(forRegion region: CLRegion) {
        print("region EXIT event triggered \(region)")
        guard let employeeID = UserDefaults.standard.integer(forKey: "employeeID") as? Int else { print("failed on employeeID"); return }
        guard let employeeName = UserDefaults.standard.string(forKey: "employeeName") as? String else { print("failed on employeeName"); return }
        let userInfo = UserData.UserInfo(employeeID: employeeID, userName: employeeName, employeeJobs: [], punchedIn: true)
        let autoClockOut = true
        guard let coordinate = UserLocation.instance.currentCoordinate as? CLLocationCoordinate2D else { return }
        let locationArray = [String(coordinate.latitude), String(coordinate.longitude)]
        
        APICalls().sendCoordinates(employee: userInfo, location: locationArray, autoClockOut: autoClockOut) { success, currentJob, poNumber, jobLatLong, clockedIn in
            let content = UNMutableNotificationContent()
            content.title = "Left Job Site"
            content.body = "You were clocked out because you left the job site."
            content.sound = UNNotificationSound.default()
            let intrvl = TimeInterval(1.01)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intrvl, repeats: false)
            let request = UNNotificationRequest(identifier: region.identifier, content: content, trigger: trigger)
            
            self.notificationCenter?.add(request) { (err) in
                if err != nil { print("error setting up notification request") } else {
                    print("added notification")
                }
            }
            if clockedIn == false && success == true { UserLocation.instance.stopMonitoring() }
        }
    }
}


