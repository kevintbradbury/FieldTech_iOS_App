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
    
    public static var homeViewActive: HomeView?
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
//        notificationCenter?.delegate = self
        
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
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) { handleGeoFenceEvent(forRegion: region) }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let errMsg = "LocationManager Failed with error: \(error.localizedDescription)"
        
        APICalls().sendErrorLog(errMsg: errMsg)
        
        print("Location manger failed with following error: \(error)")
    }
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        let errMsg = "LocationManager Failed with error: \(error.localizedDescription)"
        
        APICalls().sendErrorLog(errMsg: errMsg)
        
        print("monitoring failed for region w/ identifier: \(String(describing: region?.identifier))")
    }
    
}

extension UserLocation {
    
    func calculateRegion(for location: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let latitude = location.latitude
        let longitude = location.longitude
        let dist = CLLocationDistance(400)
        let span = MKCoordinateSpan(latitudeDelta: dist, longitudeDelta: dist)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        
        return region
    }
    
    func startMonitoring(location: CLLocationCoordinate2D) {
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            fatalError("GPS loc not set to ALWAYS in use")
        } else {
            let radius = CLLocationDistance(402)    // radius 1/4 mile ~= 402 meters
            let region = CLCircularRegion(center: location, radius: radius, identifier: "leftJobSite")
            print("region to start monitoring: \(region)")
            locationManager.startMonitoring(for: region)
            
            while locationManager.monitoredRegions.count == 0 {
                locationManager.startMonitoring(for: region)
                print("Locale BEING monitored: \(locationManager.monitoredRegions)")
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
        print("handleGeoFenceEvent EXIT region: \(region)")
        guard let employeeName = UserDefaults.standard.string(forKey: "employeeName"),
            let coordinates = UserLocation.instance.currentCoordinate else {
                print("failed on employeeName or coordinate or employeeID"); return
        }
        let employeeID = UserDefaults.standard.integer(forKey: "employeeID")
        let userInfo = UserData.UserInfo(employeeID: employeeID, username: employeeName, employeeJobs: [], punchedIn: true)
        let role: String
        
        APICalls().sendCoordinates(
            employee: userInfo, location: coordinates, autoClockOut: true, role: "-", po: "", override: false
        ) { success, currentJob, poNumber, jobLatLong, clockedIn, err in
            
            if clockedIn == false && success == true {
                self.notifyClockOut(identifier: region.identifier)
                
                UserLocation.instance.stopMonitoring()
                HomeView.employeeInfo = nil
                NotificationCenter.default.post(name: .info, object: self, userInfo: ["employeeInfo" : userInfo])
            }
        }
    }
    
    func notifyClockOut(identifier: String) {
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Clocked Out"
        notificationContent.body = "You were clocked out because you left the job site. \nPlease send photos, supplies requests, or change orders."
        notificationContent.sound = UNNotificationSound.default
        notificationContent.categoryIdentifier = "leftJobSite"
        notificationContent.threadIdentifier = "leftJobSite"
        
        var clockedOutNotifs = [UNNotificationRequest]()
        
        for i in 1...6 {
            let fiveMin = TimeInterval(60 * 5 * i) // 60*5*i for production
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fiveMin, repeats: false)
            let clockedOutNotif = UNNotificationRequest(identifier: "leftJobSite\(i)", content: notificationContent, trigger: trigger)
            
            clockedOutNotifs.append(clockedOutNotif)
        }
        
        for notf in clockedOutNotifs {
            UNUserNotificationCenter.current().add(notf) { (error) in
                if error != nil {
                    print("Error setting notification: \(error)")
                }
            }
        }
    }
    
}

