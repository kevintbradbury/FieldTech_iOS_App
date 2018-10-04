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


class UserLocation: NSObject, CLLocationManagerDelegate {
    
    static let instance = UserLocation()
    override init() {}
    
    private var alreadyInitialized = false
    private var onLocation: ((CLLocationCoordinate2D) -> Void)?
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var currentRegion: MKCoordinateRegion?
    var currentCoordinate: CLLocationCoordinate2D? { return currentLocation?.coordinate }
    var notificationCenter: UNUserNotificationCenter?
    var regionToCheck: CLCircularRegion?
    
    func initialize() {
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
        print(location.coordinate)
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
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) { print("monitoring failed for region w/ identifier: "); print(region?.identifier) }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { print("Location manger failed with followign error: "); print(error) }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) { handleGeoFenceEvent(forRegion: region) }
    
}

extension UserLocation {
    
    func calculateRegion(for location: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let latitude = location.latitude
        let longitude = location.longitude
        let dist = CLLocationDistance(0.5)
//        let latDelta = dist
//        let longDelta = dist
        let span = MKCoordinateSpan(latitudeDelta: dist, longitudeDelta: dist)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        
        return region
    }
    
    func startMonitoring(location: CLLocationCoordinate2D) {
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            fatalError("GPS loc not set to ALWAYS in use")
        } else {
            let radius = CLLocationDistance(402) // radius: 402
            guard let region = CLCircularRegion(center: location, radius: radius, identifier: "range") as? CLCircularRegion else { return } // radius 1/4 mile ~= 402 meters
            print("region to start monitoring: \(region)")
            locationManager.startMonitoring(for: region)
            
            while locationManager.monitoredRegions.count == 0 {
                locationManager.startMonitoring(for: region); print("Locale BEING monitored: \(locationManager.monitoredRegions)")
            }
        }
    }
    
    func stopMonitoring() {
        print("stop monitoring location")
        for region in (locationManager.monitoredRegions) {
            guard let circularRegion = region as? CLCircularRegion else { continue }
            locationManager.stopMonitoring(for: circularRegion)
            locationManager.stopUpdatingLocation()
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
        
        // get role here
        let role: String
        
        APICalls().sendCoordinates(employee: userInfo, location: locationArray, autoClockOut: autoClockOut, role: "-") { success, currentJob, poNumber, jobLatLong, clockedIn, err in
            let content = UNMutableNotificationContent()
            content.title = "Clocked Out"
            content.body = "You were clocked out because you left the job site."
            content.sound = UNNotificationSound.default()
            let intrvl = TimeInterval(1.01)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intrvl, repeats: false)
            let request = UNNotificationRequest(identifier: region.identifier, content: content, trigger: trigger)
            
            self.notificationCenter?.add(request) { (error) in
                if error != nil { print("error setting up notification request") } else {
                    print("added notification")
                }
            }
            
            if clockedIn == false && success == true {
                UserLocation.instance.stopMonitoring()
                HomeView.employeeInfo = nil
                NotificationCenter.default.post(name: .info, object: self, userInfo: ["employeeInfo" : UserData.UserInfo])
            }
        }
    }
}

extension UserLocation: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) { completionHandler([.alert, .badge, .sound]) }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) { completionHandler() }
}


