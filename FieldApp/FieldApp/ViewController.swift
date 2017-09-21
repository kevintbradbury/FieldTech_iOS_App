//
//  ViewController.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

class ViewController: UIViewController {

    var jobs: [Job.UserJob] = []
    let main = OperationQueue.main
    var location = UserData.init().userLocation
    var jobAddress = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        UserLocation.instance.initialize()
        getJobs() {jobs in
            self.getLocation()
            self.jobAddress = "\(jobs[0].jobAddress), \(jobs[0].jobCity), \(jobs[0].jobState)"
            GeoCoding.locationForAddressCode(address: self.jobAddress) { location in
                
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getJobs(callback: @escaping ([Job.UserJob]) -> ()) {
        
        APITestCall().fetchJobInfo() { jobs in
            self.jobs = jobs
            callback(jobs)
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            self.main.addOperation {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            print("Index 0 of JSON Jobs data \(self.jobs[0])")
        }
    }
    
    func getLocation() {
        
        UserLocation.instance.requestLocation(){ coordinate in
            
            self.location = coordinate
            
            if (self.location?.latitude)! > CLLocationDegrees(0.0) {
                print("User location is --> \(self.location?.latitude) by \(self.location?.longitude)")
            } else {
                print("location failed")
            }
        }
    }

}

